class Alarm {
  final int? id;
  final int hour;
  final int minute;
  final bool isActive;
  final String label;
  final String? ringtonePath;
  final List<int> repeatDays;
  final bool vibrate;
  final int? systemAlarmId;
  final String createdAt;

  Alarm({
    this.id,
    required this.hour,
    required this.minute,
    this.isActive = true,
    this.label = 'Yevmiye',
    this.ringtonePath,
    this.repeatDays = const [],
    this.vibrate = true,
    this.systemAlarmId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'is_active': isActive ? 1 : 0,
      'label': label,
      'ringtone_path': ringtonePath,
      'repeat_days': repeatDays.join(','),
      'vibrate': vibrate ? 1 : 0,
      'system_alarm_id': systemAlarmId,
      'created_at': createdAt,
    };
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'],
      hour: map['hour'],
      minute: map['minute'],
      isActive: map['is_active'] == 1,
      label: map['label'] ?? '',
      ringtonePath: map['ringtone_path'],
      repeatDays: (map['repeat_days'] as String? ?? '')
          .split(',')
          .where((day) => day.isNotEmpty)
          .map(int.parse)
          .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
          .toSet()
          .toList()
        ..sort(),
      vibrate: (map['vibrate'] as int? ?? 1) == 1,
      systemAlarmId: map['system_alarm_id'] as int?,
      createdAt: map['created_at'],
    );
  }

  Alarm copyWith({
    int? id,
    int? hour,
    int? minute,
    bool? isActive,
    String? label,
    String? ringtonePath,
    List<int>? repeatDays,
    bool? vibrate,
    int? systemAlarmId,
    bool clearSystemAlarmId = false,
    String? createdAt,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isActive: isActive ?? this.isActive,
      label: label ?? this.label,
      ringtonePath: ringtonePath ?? this.ringtonePath,
      repeatDays: repeatDays ?? this.repeatDays,
      vibrate: vibrate ?? this.vibrate,
      systemAlarmId:
          clearSystemAlarmId ? null : systemAlarmId ?? this.systemAlarmId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
