import 'package:flutter/foundation.dart';
import 'package:yevmiye_takip/database/database_helper.dart';
import 'package:yevmiye_takip/models/alarm.dart';
import 'package:yevmiye_takip/utils/notification_helper.dart';

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
          // Eğer alarm veritabanında aktif ama sistemde değilse, sistemi güncelle
          final isSysActive = await NotificationHelper.hasActiveAlarm(alarm.id!);
          if (!isSysActive) {
            await NotificationHelper.scheduleAlarm(alarm);
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

  Future<void> addAlarm(int hour, int minute, String label) async {
    final alarm = Alarm(
      hour: hour,
      minute: minute,
      label: label,
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
    final granted = await NotificationHelper.requestPermissions();
    if (granted) {
      await NotificationHelper.scheduleAlarm(newAlarm);
    }
    
    notifyListeners();
  }

  Future<void> toggleAlarm(Alarm alarm) async {
    final newStatus = !alarm.isActive;
    final updatedAlarm = alarm.copyWith(isActive: newStatus);

    await DatabaseHelper.instance.updateAlarm(updatedAlarm);
    
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = updatedAlarm;
      notifyListeners();
    }

    if (newStatus) {
      final granted = await NotificationHelper.requestPermissions();
      if (granted) {
        await NotificationHelper.scheduleAlarm(updatedAlarm);
      }
    } else {
      if (updatedAlarm.id != null) {
        await NotificationHelper.cancelAlarm(updatedAlarm.id!);
      }
    }
  }

  Future<void> updateAlarm(Alarm alarm) async {
    await DatabaseHelper.instance.updateAlarm(alarm);
    
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      _alarms[index] = alarm;
      notifyListeners();
    }

    if (alarm.isActive) {
      await NotificationHelper.scheduleAlarm(alarm);
    } else if (alarm.id != null) {
      await NotificationHelper.cancelAlarm(alarm.id!);
    }
  }

  Future<void> deleteAlarm(int id) async {
    await DatabaseHelper.instance.deleteAlarm(id);
    await NotificationHelper.cancelAlarm(id);
    
    _alarms.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
