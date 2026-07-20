class Worker {
  final int? id;
  final String name;
  final String? phone;
  final double dailyWage;
  final bool isActive;
  final double totalDays;
  final double totalEarnings;
  final DateTime createdAt;
  final DateTime updatedAt;

  Worker({
    this.id,
    required this.name,
    this.phone,
    required this.dailyWage,
    this.isActive = true,
    this.totalDays = 0.0,
    this.totalEarnings = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'daily_wage': dailyWage,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // We don't save total_days and total_earnings since they are calculated
    };
  }

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      dailyWage: (map['daily_wage'] as num).toDouble(),
      isActive: (map['is_active'] as int) == 1,
      totalDays: (map['total_days'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (map['total_earnings'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Worker copyWith({
    int? id,
    String? name,
    String? phone,
    double? dailyWage,
    bool? isActive,
    double? totalDays,
    double? totalEarnings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      dailyWage: dailyWage ?? this.dailyWage,
      isActive: isActive ?? this.isActive,
      totalDays: totalDays ?? this.totalDays,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
