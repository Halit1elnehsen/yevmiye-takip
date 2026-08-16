import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';
import 'package:yevmiye_takip/theme/app_theme.dart';
import 'package:yevmiye_takip/screens/home_screen.dart';

class YevmiyeTakipApp extends StatelessWidget {
  const YevmiyeTakipApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, localeProv, child) {
        return MaterialApp(
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
