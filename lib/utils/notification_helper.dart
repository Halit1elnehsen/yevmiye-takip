import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:yevmiye_takip/database/database_helper.dart';

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
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  /// Bildirim izinlerini iste
  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  /// Belirtilen saatte günlük alarm planla
  /// Alarm çalmadan önce bugünün kayıtlarını kontrol eder
  static Future<void> scheduleDailyReminder(int hour, int minute) async {
    try {
      _initTimezone();
      await cancelAllNotifications();

      // Bugün için kayıt var mı kontrol et
      final hasRecords = await _checkTodaysRecords();
      if (hasRecords) {
        debugPrint('Bugün için kayıt mevcut, alarm planlanmadı.');
        return;
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'yevmiye_alarm_channel',
        'Yevmiye Alarm',
        channelDescription: 'Yevmiye girmeyi hatırlatan günlük alarm',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
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

      // Bir sonraki alarm zamanını hesapla
      final scheduledDate = _nextInstanceOfTime(hour, minute);

      await _notificationsPlugin.zonedSchedule(
        0,
        'Yevmiye Takip Vakti! ⏰',
        'Usta, bugünün yevmiyelerini yazmayı unutma!',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Alarm planlandı: $hour:$minute');
    } catch (e) {
      debugPrint('Notification schedule error: $e');
    }
  }

  /// Bugün için yevmiye kaydı var mı kontrol et
  static Future<bool> _checkTodaysRecords() async {
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

  /// Tüm bildirimleri iptal et
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
