import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';
import 'package:yevmiye_takip/theme/app_theme.dart';
import 'package:yevmiye_takip/screens/home_screen.dart';

import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:yevmiye_takip/screens/ringing_screen.dart';
import 'package:yevmiye_takip/providers/alarm_provider.dart';
import 'package:yevmiye_takip/providers/settings_provider.dart';

class YevmiyeTakipApp extends StatefulWidget {
  const YevmiyeTakipApp({Key? key}) : super(key: key);

  @override
  State<YevmiyeTakipApp> createState() => _YevmiyeTakipAppState();
}

class _YevmiyeTakipAppState extends State<YevmiyeTakipApp> {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  StreamSubscription<AlarmSettings>? ringSubscription;
  final Set<int> _openedRingingIds = {};

  @override
  void initState() {
    super.initState();
    ringSubscription = Alarm.ringStream.stream.listen(_handleRingingAlarm);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final ringing in Alarm.ringing.value.alarms) {
        await _handleRingingAlarm(ringing);
      }
    });
  }

  Future<void> _handleRingingAlarm(AlarmSettings alarmSettings) async {
    final currentContext = navigatorKey.currentContext;
    if (currentContext == null || !_openedRingingIds.add(alarmSettings.id)) {
      return;
    }
    final localization = Provider.of<LocalizationProvider>(
      currentContext,
      listen: false,
    );
    await localization.initialized;
    await Provider.of<AlarmProvider>(currentContext, listen: false)
        .handleAlarmRinging(
      alarmSettings,
      title: localization.translate('alarm_notification_title'),
      body: localization.translate('alarm_notification_body'),
      snooze: localization.translate('snooze_alarm'),
      stop: localization.translate('stop_alarm'),
    );
    navigatorKey.currentState
        ?.push(
          MaterialPageRoute(
            builder: (context) => RingingScreen(alarmSettings: alarmSettings),
          ),
        )
        .whenComplete(() => _openedRingingIds.remove(alarmSettings.id));
  }

  @override
  void dispose() {
    ringSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationProvider, SettingsProvider>(
      builder: (context, localeProv, settingsProv, child) {
        AppTheme.setDarkMode(settingsProv.darkModeEnabled);
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Yevmiye Takip',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              settingsProv.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
          locale: Locale(localeProv.currentLanguage),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('tr', ''),
            Locale('en', ''),
            Locale('ar', ''),
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: localeProv.currentLanguage == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child!,
            );
          },
        );
      },
    );
  }
}
