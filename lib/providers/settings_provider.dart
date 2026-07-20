import 'package:flutter/material.dart';
import 'package:yevmiye_takip/database/database_helper.dart';

class SettingsProvider extends ChangeNotifier {
  int _notificationHour = 17;
  int _notificationMinute = 0;
  bool _notificationsEnabled = true;

  int get notificationHour => _notificationHour;
  int get notificationMinute => _notificationMinute;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> loadSettings() async {
    try {
      final hourStr = await DatabaseHelper.instance.getSetting('notification_hour');
      final minStr = await DatabaseHelper.instance.getSetting('notification_minute');
      final enabledStr = await DatabaseHelper.instance.getSetting('notification_enabled');

      if (hourStr != null) _notificationHour = int.parse(hourStr);
      if (minStr != null) _notificationMinute = int.parse(minStr);
      if (enabledStr != null) _notificationsEnabled = enabledStr == '1';

      notifyListeners();
    } catch (e) {
      debugPrint('Load settings error: $e');
    }
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    _notificationHour = hour;
    _notificationMinute = minute;
    notifyListeners();

    try {
      await DatabaseHelper.instance.setSetting('notification_hour', hour.toString());
      await DatabaseHelper.instance.setSetting('notification_minute', minute.toString());
    } catch (e) {
      debugPrint('Save notification time error: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();

    try {
      await DatabaseHelper.instance.setSetting('notification_enabled', enabled ? '1' : '0');
    } catch (e) {
      debugPrint('Save notification enabled status error: $e');
    }
  }
}
