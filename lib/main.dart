import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/app.dart';
import 'package:yevmiye_takip/providers/worker_provider.dart';
import 'package:yevmiye_takip/providers/record_provider.dart';
import 'package:yevmiye_takip/providers/settings_provider.dart';
import 'package:yevmiye_takip/providers/alarm_provider.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';
import 'package:alarm/alarm.dart';
// Web platformunda sqflite_common_ffi_web kullanılması gerekiyor
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web platformu için veritabanı factory'sini ayarla
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Alarm sistemini başlat (sadece mobilde çalışır)
  if (!kIsWeb) {
    await Alarm.init();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WorkerProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RecordProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => AlarmProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => LocalizationProvider(),
        ),
      ],
      child: const YevmiyeTakipApp(),
    ),
  );
}
