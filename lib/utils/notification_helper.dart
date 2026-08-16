import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:yevmiye_takip/database/database_helper.dart';
import 'package:yevmiye_takip/models/alarm.dart';

/// Gerçek telefon alarmı gibi çalışan bildirim yardımcısı
class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _tzInitialized = false;

  /// Timezone verisini başlat
  static void _initTimezone() {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  /// Bildirim sistemini başlat
  static Future<void> init() async {
    try {
      _initTimezone();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  /// Bildirime tıklandığında çalışacak callback
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Bildirime tıklandı: ${response.actionId}, payload: ${response.payload}');
    // 'kapat' action'ına basılırsa alarmı sustur
    if (response.actionId == 'kapat' && response.payload != null) {
      int? id = int.tryParse(response.payload!);
      if (id != null) {
        cancelAlarm(id);
      }
    }
  }

  /// Bildirim izinlerini iste
  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    try {
      // Bildirim izni
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        if (!status.isGranted) return false;
      }

      // Android 13+ özel alarm izni
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }

      return true;
    } catch (e) {
      debugPrint('Permission request error: $e');
      return false;
    }
  }

  /// Belirtilen saatte günlük alarm planla
  static Future<void> scheduleAlarm(Alarm alarm) async {
    if (alarm.id == null) return;
    try {
      _initTimezone();

      // Önce eski alarmı iptal et
      await cancelAlarm(alarm.id!);

      // Android bildirim ayarları — ALARM GİBİ ÇALSIN
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'yevmiye_alarm_channel_v2',      // Kanal ID (yenilendi ki ses ayarı güncellensin)
        'Yevmiye Alarm',                 // Kanal adı
        channelDescription: 'Yevmiye girmeyi hatırlatan günlük alarm',
        importance: Importance.max,       // En yüksek önem
        priority: Priority.high,          // En yüksek öncelik
        playSound: true,                  // Ses çal
        audioAttributesUsage: AudioAttributesUsage.alarm, // ALARM SESİ KULLAN
        enableVibration: true,            // Titreşim aç
        fullScreenIntent: true,           // Tam ekran göster (kilit ekranında bile)
        category: AndroidNotificationCategory.alarm, // Alarm kategorisi
        visibility: NotificationVisibility.public,    // Kilit ekranında göster
        ongoing: true,                    // Kaydırarak kapatılamaz
        autoCancel: false,                // Otomatik kapanmaz
        timeoutAfter: 60000,              // 60 saniye sonra otomatik dur
        enableLights: true,               // LED ışık yak
        ticker: 'Yevmiye Alarm Çalıyor!', // Erişilebilirlik metni
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'kapat',
            'Alarmı Kapat',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'ac',
            'Uygulamayı Aç',
            showsUserInterface: true,
          ),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical, // Sessiz modda bile çal
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Bir sonraki alarm zamanını hesapla
      final scheduledDate = _nextInstanceOfTime(alarm.hour, alarm.minute);

      await _notificationsPlugin.zonedSchedule(
        alarm.id!,
        '⏰ YEVMİYE ALARM! ⏰',
        alarm.label.isNotEmpty ? alarm.label : 'Yevmiyeleri yazmayı unutma!',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: alarm.id.toString(),
      );

      debugPrint('✅ Alarm planlandı [ID: ${alarm.id}]: ${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('Alarm schedule error: $e');
    }
  }

  /// Alarmı test et — hemen çalsın (test amaçlı)
  static Future<void> testAlarmNow() async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'yevmiye_alarm_channel_v2',
        'Yevmiye Alarm',
        channelDescription: 'Yevmiye girmeyi hatırlatan günlük alarm',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        ongoing: true,
        autoCancel: false,
        timeoutAfter: 15000, // Test: 15 saniye sonra otomatik dur
        enableLights: true,
        ticker: 'Test Alarm Çalıyor!',
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'kapat',
            'Alarmı Kapat',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        999, // Test notification ID
        '⏰ TEST ALARM! ⏰',
        'Bu bir test alarmıdır. Gerçek alarm da böyle çalacak!',
        platformDetails,
      );

      debugPrint('✅ Test alarmı çaldı!');
    } catch (e) {
      debugPrint('Test alarm error: $e');
    }
  }

  /// Bugün için yevmiye kaydı var mı kontrol et
  static Future<bool> checkTodaysRecords() async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      return await DatabaseHelper.instance.hasRecordsForDate(dateStr);
    } catch (e) {
      debugPrint('Check today records error: $e');
      return false;
    }
  }

  /// Bir sonraki belirtilen saati hesapla
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );
    // Eğer bugünkü saat geçtiyse yarına planla
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Alarmı iptal et
  static Future<void> cancelAlarm(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Tüm bildirimleri iptal et
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Aktif alarm var mı kontrol et
  static Future<bool> hasActiveAlarm(int id) async {
    try {
      final pendingRequests = await _notificationsPlugin.pendingNotificationRequests();
      return pendingRequests.any((r) => r.id == id);
    } catch (e) {
      debugPrint('Check active alarm error: $e');
      return false;
    }
  }
}
