class Alarm {
  final int? id;
  final int hour;
  final int minute;
  final bool isActive;
  final String label;
  final String? ringtonePath;
  final String createdAt;

  Alarm({
    this.id,
    required this.hour,
    required this.minute,
    this.isActive = true,
    this.label = 'Yevmiye',
    this.ringtonePath,
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
    String? createdAt,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isActive: isActive ?? this.isActive,
      label: label ?? this.label,
      ringtonePath: ringtonePath ?? this.ringtonePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
