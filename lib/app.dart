import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';
import 'package:yevmiye_takip/theme/app_theme.dart';
import 'package:yevmiye_takip/screens/home_screen.dart';

import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:yevmiye_takip/screens/ringing_screen.dart';

class YevmiyeTakipApp extends StatefulWidget {
  const YevmiyeTakipApp({Key? key}) : super(key: key);

  @override
  State<YevmiyeTakipApp> createState() => _YevmiyeTakipAppState();
}

class _YevmiyeTakipAppState extends State<YevmiyeTakipApp> {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AlarmSettings>? ringSubscription;

  @override
  void initState() {
    super.initState();
    ringSubscription = Alarm.ringStream.stream.listen((alarmSettings) {
      _navigateToRingingScreen(alarmSettings);
    });
  }

  void _navigateToRingingScreen(AlarmSettings alarmSettings) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => RingingScreen(alarmSettings: alarmSettings),
      ),
    );
  }

  @override
  void dispose() {
    ringSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, localeProv, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Yevmiye Takip',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
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
