import 'dart:io';
import 'dart:math';

import 'package:alarm/alarm.dart' as alarm_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yevmiye_takip/database/database_helper.dart';
import 'package:yevmiye_takip/models/alarm.dart';

class AlarmProvider with ChangeNotifier {
  static const _alarmPermissionChannel =
      MethodChannel('com.yevmiye/alarm_permissions');
  List<Alarm> _alarms = [];
  bool _isLoading = false;

  List<Alarm> get alarms => _alarms;
  bool get isLoading => _isLoading;

  Future<bool> requestAlarmPermissions() async {
    if (kIsWeb) return true;

    final notification = await Permission.notification.request();
    if (!notification.isGranted) return false;

    if (alarm_pkg.Alarm.android) {
      final exactAlarm = await Permission.scheduleExactAlarm.request();
      if (!exactAlarm.isGranted) return false;

      final hasFullScreenPermission = await _alarmPermissionChannel
              .invokeMethod<bool>('hasFullScreenIntentPermission') ??
          true;
      if (!hasFullScreenPermission) {
        await _alarmPermissionChannel
            .invokeMethod<void>('openFullScreenIntentSettings');
        return false;
      }
    }
    return true;
  }

  Future<void> loadAlarms({
    String title = 'Wage reminder',
    String body = 'Record today’s wages.',
    String snooze = 'Snooze 10m',
    String stop = 'Stop',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _alarms = await DatabaseHelper.instance.getAllAlarms();
      if (!kIsWeb) {
        final pluginAlarms = await alarm_pkg.Alarm.getAlarms();
        final persistedIds = <int>{};
        for (final alarm in _alarms) {
          if (alarm.id == null) continue;
          final systemId = alarm.systemAlarmId ?? alarm.id!;
          if (!alarm.isActive) {
            if (alarm.systemAlarmId != null) {
              await alarm_pkg.Alarm.stop(alarm.systemAlarmId!);
            }
            if (alarm.systemAlarmId != alarm.id) {
              await alarm_pkg.Alarm.stop(alarm.id!);
            }
            continue;
          }
          persistedIds.add(systemId);
          if (!alarm_pkg.Alarm.ringing.value.containsId(systemId)) {
            await _schedule(alarm, systemId,
                title: title, body: body, snooze: snooze, stop: stop);
          }
        }

        final ringingIds =
            alarm_pkg.Alarm.ringing.value.alarms.map((item) => item.id).toSet();
        for (final oldAlarm in pluginAlarms) {
          if (!persistedIds.contains(oldAlarm.id) &&
              !ringingIds.contains(oldAlarm.id)) {
            await alarm_pkg.Alarm.stop(oldAlarm.id);
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

  Future<bool> addAlarm(
    int hour,
    int minute,
    String label, {
    String? ringtonePath,
    List<int> repeatDays = const [],
    bool vibrate = true,
    String title = 'Wage reminder',
    String body = 'Record today’s wages.',
    String snooze = 'Snooze 10m',
    String stop = 'Stop',
  }) async {
    if (!await requestAlarmPermissions()) return false;

    final alarm = Alarm(
      hour: hour,
      minute: minute,
      label: label,
      ringtonePath: ringtonePath,
      repeatDays: repeatDays,
      vibrate: vibrate,
      createdAt: DateTime.now().toIso8601String(),
    );
    final id = await DatabaseHelper.instance.insertAlarm(alarm);
    final newAlarm = alarm.copyWith(id: id);
    _alarms = [..._alarms, newAlarm]..sort(_compareAlarms);

    if (!kIsWeb) {
      await _schedule(
        newAlarm,
        id,
        title: title,
        body: body,
        snooze: snooze,
        stop: stop,
      );
    }
    notifyListeners();
    return true;
  }

  Future<bool> toggleAlarm(
    Alarm alarm, {
    String title = 'Wage reminder',
    String body = 'Record today’s wages.',
    String snooze = 'Snooze 10m',
    String stop = 'Stop',
  }) async {
    final newStatus = !alarm.isActive;
    if (newStatus && !await requestAlarmPermissions()) return false;

    final updatedAlarm = alarm.copyWith(isActive: newStatus);
    await DatabaseHelper.instance.updateAlarm(updatedAlarm);

    if (!kIsWeb && alarm.id != null) {
      await alarm_pkg.Alarm.stop(alarm.systemAlarmId ?? alarm.id!);
      if (alarm.systemAlarmId != null && alarm.systemAlarmId != alarm.id) {
        await alarm_pkg.Alarm.stop(alarm.id!);
      }
      if (newStatus) {
        await _schedule(updatedAlarm, alarm.systemAlarmId ?? alarm.id!,
            title: title, body: body, snooze: snooze, stop: stop);
      }
    }
    _replace(updatedAlarm);
    return true;
  }

  Future<bool> updateAlarm(
    Alarm alarm, {
    String title = 'Wage reminder',
    String body = 'Record today’s wages.',
    String snooze = 'Snooze 10m',
    String stop = 'Stop',
  }) async {
    if (alarm.isActive && !await requestAlarmPermissions()) return false;
    await DatabaseHelper.instance.updateAlarm(alarm);

    if (!kIsWeb && alarm.id != null) {
      await alarm_pkg.Alarm.stop(alarm.systemAlarmId ?? alarm.id!);
      if (alarm.systemAlarmId != null && alarm.systemAlarmId != alarm.id) {
        await alarm_pkg.Alarm.stop(alarm.id!);
      }
      if (alarm.isActive) {
        await _schedule(alarm, alarm.systemAlarmId ?? alarm.id!,
            title: title, body: body, snooze: snooze, stop: stop);
      }
    }
    _replace(alarm);
    return true;
  }

  /// Called as soon as an alarm starts ringing. Repeating alarms are moved to
  /// a new system ID so stopping the current occurrence cannot cancel the next.
  Future<void> handleAlarmRinging(
    alarm_pkg.AlarmSettings ringing, {
    String title = 'Wage reminder',
    String body = 'Record today’s wages.',
    String snooze = 'Snooze 10m',
    String stop = 'Stop',
  }) async {
    if (kIsWeb) return;
    final parentId = int.tryParse(ringing.payload ?? '');
    final index = _alarms.indexWhere((alarm) =>
        alarm.id == parentId ||
        (alarm.systemAlarmId ?? alarm.id) == ringing.id);
    if (index == -1) return;

    final alarm = _alarms[index];
    if (!alarm.isActive ||
        (alarm.systemAlarmId != null && alarm.systemAlarmId != ringing.id)) {
      return;
    }
    if (alarm.repeatDays.isEmpty) {
      final inactive = alarm.copyWith(
        isActive: false,
        clearSystemAlarmId: true,
      );
      await DatabaseHelper.instance.updateAlarm(inactive);
      _replace(inactive);
      return;
    }

    final nextSystemId = await _newSystemId();
    final updated = alarm.copyWith(systemAlarmId: nextSystemId);
    await DatabaseHelper.instance.updateAlarm(updated);
    _replace(updated);
    await _schedule(
      updated,
      nextSystemId,
      after: ringing.dateTime,
      title: title,
      body: body,
      snooze: snooze,
      stop: stop,
    );
  }

  Future<void> deleteAlarm(int id) async {
    final matching = _alarms.where((item) => item.id == id);
    final alarm = matching.isEmpty ? null : matching.first;
    await DatabaseHelper.instance.deleteAlarm(id);
    if (!kIsWeb && alarm != null) {
      await alarm_pkg.Alarm.stop(alarm.systemAlarmId ?? id);
      if (alarm.systemAlarmId != null && alarm.systemAlarmId != id) {
        await alarm_pkg.Alarm.stop(id);
      }
    }
    _alarms = List.from(_alarms)..removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<void> _schedule(
    Alarm alarm,
    int systemId, {
    DateTime? after,
    required String title,
    required String body,
    required String snooze,
    required String stop,
  }) async {
    if (kIsWeb || alarm.id == null || !alarm.isActive) return;
    final next = nextOccurrence(alarm, after: after ?? DateTime.now());
    final audioPath = alarm.ringtonePath;
    final usableAudioPath = audioPath == null ||
            audioPath.startsWith('assets/') ||
            await File(audioPath).exists()
        ? audioPath
        : null;

    final settings = alarm_pkg.AlarmSettings(
      id: systemId,
      dateTime: next,
      payload: alarm.id.toString(),
      assetAudioPath: usableAudioPath,
      loopAudio: true,
      vibrate: alarm.vibrate,
      volumeSettings: alarm_pkg.VolumeSettings.fade(
        volume: 1,
        fadeDuration: const Duration(seconds: 3),
      ),
      notificationSettings: alarm_pkg.NotificationSettings(
        title: title,
        body: alarm.label.isNotEmpty ? alarm.label : body,
        stopButton: stop,
        androidSnoozeButton: snooze,
        androidStopAlarmOnDismiss: false,
        icon: null,
      ),
      androidSnoozeDuration: const Duration(minutes: 10),
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
    );
    await alarm_pkg.Alarm.set(alarmSettings: settings);
  }

  DateTime nextOccurrence(Alarm alarm, {DateTime? after}) {
    after ??= DateTime.now();
    for (var offset = 0; offset <= 7; offset++) {
      final date = DateTime(after.year, after.month, after.day + offset,
          alarm.hour, alarm.minute);
      if (alarm.repeatDays.isNotEmpty &&
          !alarm.repeatDays.contains(date.weekday)) continue;
      if (date.isAfter(after)) return date;
    }
    // A nonempty repeat set always yields a date within seven days.
    return DateTime(
        after.year, after.month, after.day + 1, alarm.hour, alarm.minute);
  }

  Future<int> _newSystemId() async {
    final used =
        (await alarm_pkg.Alarm.getAlarms()).map((item) => item.id).toSet();
    final random = Random.secure();
    int candidate;
    do {
      candidate = 100000 + random.nextInt(2000000000);
    } while (used.contains(candidate) ||
        _alarms.any((alarm) => alarm.id == candidate));
    return candidate;
  }

  void _replace(Alarm alarm) {
    final index = _alarms.indexWhere((item) => item.id == alarm.id);
    if (index == -1) return;
    _alarms[index] = alarm;
    _alarms.sort(_compareAlarms);
    notifyListeners();
  }

  int _compareAlarms(Alarm a, Alarm b) {
    if (a.hour == b.hour) return a.minute.compareTo(b.minute);
    return a.hour.compareTo(b.hour);
  }
}
