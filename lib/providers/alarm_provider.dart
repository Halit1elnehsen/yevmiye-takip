import 'package:flutter/foundation.dart';
import 'package:yevmiye_takip/database/database_helper.dart';
import 'package:yevmiye_takip/models/alarm.dart';
import 'package:alarm/alarm.dart' as alarm_pkg;

class AlarmProvider with ChangeNotifier {
  List<Alarm> _alarms = [];
  bool _isLoading = false;

  List<Alarm> get alarms => _alarms;
  bool get isLoading => _isLoading;

  AlarmProvider() {
    loadAlarms();
  }

  Future<void> loadAlarms() async {
    _isLoading = true;
    notifyListeners();

    try {
      _alarms = await DatabaseHelper.instance.getAllAlarms();
      
      // Her alarm için aktifliğini sistemle senkronize et
      for (var alarm in _alarms) {
        if (alarm.isActive && alarm.id != null) {
          final isSysActive = alarm_pkg.Alarm.hasAlarm(); // Alarm package check is simpler, or Alarm.getAlarm(id) != null
          final existingAlarm = alarm_pkg.Alarm.getAlarm(alarm.id!);
          if (existingAlarm == null) {
            await _scheduleAlarmWithPackage(alarm);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading alarms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _scheduleAlarmWithPackage(Alarm alarm, {String title = '⏰ YEVMİYE ALARM! ⏰', String body = 'Yevmiyeleri yazmayı unutma!', String stop = 'Kapat'}) async {
    if (alarm.id == null) return;
    
    final now = DateTime.now();
    DateTime alarmTime = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
    
    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    final alarmSettings = alarm_pkg.AlarmSettings(
      id: alarm.id!,
      dateTime: alarmTime,
      assetAudioPath: alarm.ringtonePath ?? 'assets/marimba.mp3',
      loopAudio: true,
      vibrate: true,
      volumeSettings: alarm_pkg.VolumeSettings.fade(volume: 1.0, fadeDuration: const Duration(seconds: 3)),
      notificationSettings: alarm_pkg.NotificationSettings(
        title: title,
        body: alarm.label.isNotEmpty ? alarm.label : body,
        stopButton: stop,
        icon: 'notification_icon',
      ),
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
    );

    await alarm_pkg.Alarm.set(alarmSettings: alarmSettings);
  }

  Future<void> addAlarm(int hour, int minute, String label, {String? ringtonePath, String title = '⏰ YEVMİYE ALARM! ⏰', String body = 'Yevmiyeleri yazmayı unutma!', String stop = 'Kapat'}) async {
    final alarm = Alarm(
      hour: hour,
      minute: minute,
      label: label,
      ringtonePath: ringtonePath,
      createdAt: DateTime.now().toIso8601String(),
    );

    final id = await DatabaseHelper.instance.insertAlarm(alarm);
    
    // Oluşturulan alarmı ID'siyle beraber al
    final newAlarm = alarm.copyWith(id: id);
    _alarms.add(newAlarm);
    _alarms.sort((a, b) {
      if (a.hour == b.hour) return a.minute.compareTo(b.minute);
      return a.hour.compareTo(b.hour);
    });

    // İzin iste ve alarmı kur
    if (await alarm_pkg.Alarm.hasAlarm()) {
       // Alarm requires permission on Android 13+, it usually requests on init.
    }
    await _scheduleAlarmWithPackage(newAlarm, title: title, body: body, stop: stop);
    
    notifyListeners();
  }

  Future<void> toggleAlarm(Alarm alarm, {String title = '⏰ YEVMİYE ALARM! ⏰', String body = 'Yevmiyeleri yazmayı unutma!', String stop = 'Kapat'}) async {
    final newStatus = !alarm.isActive;
    final updatedAlarm = alarm.copyWith(isActive: newStatus);

    await DatabaseHelper.instance.updateAlarm(updatedAlarm);
    
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = updatedAlarm;
      notifyListeners();
    }

    if (newStatus) {
      await _scheduleAlarmWithPackage(updatedAlarm);
    } else {
      if (updatedAlarm.id != null) {
        await alarm_pkg.Alarm.stop(updatedAlarm.id!);
      }
    }
  }

  Future<void> updateAlarm(Alarm alarm, {String title = '⏰ YEVMİYE ALARM! ⏰', String body = 'Yevmiyeleri yazmayı unutma!', String stop = 'Kapat'}) async {
    await DatabaseHelper.instance.updateAlarm(alarm);
    
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = alarm;
      notifyListeners();
    }

    if (alarm.isActive) {
      await _scheduleAlarmWithPackage(alarm, title: title, body: body, stop: stop);
    } else if (alarm.id != null) {
      await alarm_pkg.Alarm.stop(alarm.id!);
    }
  }

  Future<void> deleteAlarm(int id) async {
    await DatabaseHelper.instance.deleteAlarm(id);
    await alarm_pkg.Alarm.stop(id);
    
    // Fix: Reassign the list so Provider correctly detects the change
    _alarms = List.from(_alarms)..removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
