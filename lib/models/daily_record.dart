enum WorkStatus { completed, half, absent }

class DailyRecord {
  final int? id;
  final int workerId;
  final String date; // YYYY-MM-DD format
  final WorkStatus status;
  final double amount;
  final bool isPaid;
  final String? notes;
  final DateTime createdAt;

  DailyRecord({
    this.id,
    required this.workerId,
    required this.date,
    required this.status,
    required this.amount,
    this.isPaid = false,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'worker_id': workerId,
      'date': date,
      'status': status.name,
      'amount': amount,
      'is_paid': isPaid ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DailyRecord.fromMap(Map<String, dynamic> map) {
    return DailyRecord(
      id: map['id'] as int?,
      workerId: map['worker_id'] as int,
      date: map['date'] as String,
      status: WorkStatus.values.byName(map['status'] as String),
      amount: (map['amount'] as num).toDouble(),
      isPaid: (map['is_paid'] as int) == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  DailyRecord copyWith({
    int? id,
    int? workerId,
    String? date,
    WorkStatus? status,
    double? amount,
    bool? isPaid,
    String? notes,
    DateTime? createdAt,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      date: date ?? this.date,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
