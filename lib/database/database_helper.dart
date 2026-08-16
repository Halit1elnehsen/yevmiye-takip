import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:yevmiye_takip/models/worker.dart';
import 'package:yevmiye_takip/models/daily_record.dart';
import 'package:yevmiye_takip/models/alarm.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('yevmiye_takip.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    // 1. İşçiler Tablosu
    await db.execute('''
      CREATE TABLE workers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        daily_wage REAL NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Günlük Kayıtlar Tablosu (worker_id + date birleşimi benzersiz)
    await db.execute('''
      CREATE TABLE daily_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        worker_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        amount REAL NOT NULL,
        is_paid INTEGER DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE,
        UNIQUE (worker_id, date)
      )
    ''');

    // 3. Ayarlar Tablosu
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // 4. Alarmlar Tablosu (v3 ile eklendi)
    await db.execute('''
      CREATE TABLE alarms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1,
        label TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Varsayılan ayarları ekle
    await db.insert('settings', {'key': 'notification_hour', 'value': '17'});
    await db.insert('settings', {'key': 'notification_minute', 'value': '00'});
    await db.insert('settings', {'key': 'notification_enabled', 'value': '1'});
  }

  // v1 -> v2 migrasyon: avans tablosunu kaldır, tekrar eden kayıtları temizle, UNIQUE kısıtlaması ekle
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Avans tablosunu kaldır
      await db.execute('DROP TABLE IF EXISTS advances');

      // Tekrar eden (worker_id, date) kayıtlarını temizle - en yüksek id'li olanı tut
      await db.execute('''
        DELETE FROM daily_records
        WHERE id NOT IN (
          SELECT MAX(id)
          FROM daily_records
          GROUP BY worker_id, date
        )
      ''');

      // daily_records tablosunu UNIQUE kısıtlamasıyla yeniden oluştur
      await db.execute('ALTER TABLE daily_records RENAME TO daily_records_old');

      await db.execute('''
        CREATE TABLE daily_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          worker_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          status TEXT NOT NULL,
          amount REAL NOT NULL,
          is_paid INTEGER DEFAULT 0,
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (worker_id) REFERENCES workers (id) ON DELETE CASCADE,
          UNIQUE (worker_id, date)
        )
      ''');

      // Eski verileri yeni tabloya taşı
      await db.execute('''
        INSERT INTO daily_records (id, worker_id, date, status, amount, is_paid, notes, created_at)
        SELECT id, worker_id, date, status, amount, is_paid, notes, created_at
        FROM daily_records_old
      ''');

      await db.execute('DROP TABLE daily_records_old');
    }

    if (oldVersion < 3) {
      // Alarmlar tablosunu ekle
      await db.execute('''
        CREATE TABLE IF NOT EXISTS alarms (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          hour INTEGER NOT NULL,
          minute INTEGER NOT NULL,
          is_active INTEGER DEFAULT 1,
          label TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // Eski ayardaki alarmı tabloya taşı
      final List<Map<String, dynamic>> maps = await db.query('settings');
      int hour = 17;
      int minute = 0;
      bool isEnabled = false;

      for (var map in maps) {
        if (map['key'] == 'notification_hour') hour = int.tryParse(map['value']) ?? 17;
        if (map['key'] == 'notification_minute') minute = int.tryParse(map['value']) ?? 0;
        if (map['key'] == 'notification_enabled') isEnabled = map['value'] == '1';
      }

      if (isEnabled) {
        await db.insert('alarms', {
          'hour': hour,
          'minute': minute,
          'is_active': 1,
          'label': 'Günlük Alarm',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  // ================= ALARM İŞLEMLERİ =================

  Future<int> insertAlarm(Alarm alarm) async {
    final db = await instance.database;
    return await db.insert('alarms', alarm.toMap());
  }

  Future<List<Alarm>> getAllAlarms() async {
    final db = await instance.database;
    final maps = await db.query('alarms', orderBy: 'hour ASC, minute ASC');
    return maps.map((map) => Alarm.fromMap(map)).toList();
  }

  Future<int> updateAlarm(Alarm alarm) async {
    final db = await instance.database;
    return await db.update(
      'alarms',
      alarm.toMap(),
      where: 'id = ?',
      whereArgs: [alarm.id],
    );
  }

  Future<int> deleteAlarm(int id) async {
    final db = await instance.database;
    return await db.delete(
      'alarms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= İŞÇİ İŞLEMLERİ =================

  Future<int> insertWorker(Worker worker) async {
    final db = await instance.database;
    return await db.insert('workers', worker.toMap());
  }

  Future<List<Worker>> getAllWorkers({bool onlyActive = false}) async {
    final db = await instance.database;
    final where = onlyActive ? 'WHERE w.is_active = 1' : '';
    
    final result = await db.rawQuery('''
      SELECT w.*, 
        COALESCE(SUM(
          CASE 
            WHEN d.status = 'completed' THEN 1.0 
            WHEN d.status = 'half' THEN 0.5 
            ELSE 0 
          END
        ), 0) as total_days,
        COALESCE(SUM(
          CASE 
            WHEN d.status != 'absent' THEN d.amount 
            ELSE 0 
          END
        ), 0) as total_earnings
      FROM workers w
      LEFT JOIN daily_records d ON w.id = d.worker_id
      $where
      GROUP BY w.id
      ORDER BY w.name ASC
    ''');
    
    return result.map((json) => Worker.fromMap(json)).toList();
  }

  Future<Worker?> getWorkerById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'workers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Worker.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateWorker(Worker worker) async {
    final db = await instance.database;
    final updatedWorker = worker.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'workers',
      updatedWorker.toMap(),
      where: 'id = ?',
      whereArgs: [worker.id],
    );
  }

  Future<int> deleteWorker(int id) async {
    final db = await instance.database;
    // SQLite ON DELETE CASCADE set edildiği için işçi silinince yevmiye kayıtları da otomatik silinir
    return await db.delete(
      'workers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Worker>> searchWorkers(String query) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT w.*, 
        COALESCE(SUM(
          CASE 
            WHEN d.status = 'completed' THEN 1.0 
            WHEN d.status = 'half' THEN 0.5 
            ELSE 0 
          END
        ), 0) as total_days,
        COALESCE(SUM(
          CASE 
            WHEN d.status != 'absent' THEN d.amount 
            ELSE 0 
          END
        ), 0) as total_earnings
      FROM workers w
      LEFT JOIN daily_records d ON w.id = d.worker_id
      WHERE w.name LIKE ?
      GROUP BY w.id
      ORDER BY w.name ASC
    ''', ['%$query%']);
    return result.map((json) => Worker.fromMap(json)).toList();
  }

  // ================= GÜNLÜK KAYIT İŞLEMLERİ =================

  Future<int> insertDailyRecord(DailyRecord record) async {
    final db = await instance.database;
    // Aynı günde aynı işçi için kayıt varsa güncelle, yoksa ekle (upsert)
    final existing = await db.query(
      'daily_records',
      where: 'worker_id = ? AND date = ?',
      whereArgs: [record.workerId, record.date],
    );

    if (existing.isNotEmpty) {
      return await db.update(
        'daily_records',
        record.toMap(),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      return await db.insert('daily_records', record.toMap());
    }
  }

  Future<List<DailyRecord>> getDailyRecordsByDate(String date) async {
    final db = await instance.database;
    final result = await db.query(
      'daily_records',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.map((json) => DailyRecord.fromMap(json)).toList();
  }

  Future<List<DailyRecord>> getDailyRecordsByWorker(int workerId) async {
    final db = await instance.database;
    final result = await db.query(
      'daily_records',
      where: 'worker_id = ?',
      whereArgs: [workerId],
      orderBy: 'date DESC',
    );
    return result.map((json) => DailyRecord.fromMap(json)).toList();
  }

  Future<List<DailyRecord>> getDailyRecordsByDateRange(String startDate, String endDate) async {
    final db = await instance.database;
    final result = await db.query(
      'daily_records',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    return result.map((json) => DailyRecord.fromMap(json)).toList();
  }

  Future<int> deleteDailyRecord(int id) async {
    final db = await instance.database;
    return await db.delete(
      'daily_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Tüm işçileri tam gün olarak işaretle - her işçi için insertDailyRecord çağırarak upsert yapar
  Future<void> markAllCompleted(String date, List<Worker> workers) async {
    for (var worker in workers) {
      final record = DailyRecord(
        workerId: worker.id!,
        date: date,
        status: WorkStatus.completed,
        amount: worker.dailyWage,
      );
      await insertDailyRecord(record);
    }
  }

  Future<void> undoMarkAll(String date, List<Worker> workers) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var worker in workers) {
      batch.delete(
        'daily_records',
        where: 'worker_id = ? AND date = ?',
        whereArgs: [worker.id, date],
      );
    }
    await batch.commit(noResult: true);
  }

  // Belirtilen tarihte devamsız olmayan kayıt var mı kontrol et
  Future<bool> hasRecordsForDate(String date) async {
    final db = await instance.database;
    final result = await db.query(
      'daily_records',
      where: 'date = ? AND status != ?',
      whereArgs: [date, 'absent'],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ================= AYAR İŞLEMLERİ =================

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ================= YEDEKLEME & GERİ YÜKLEME =================

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await instance.database;
    final workers = await db.query('workers');
    final dailyRecords = await db.query('daily_records');
    final settings = await db.query('settings');

    return {
      'workers': workers,
      'daily_records': dailyRecords,
      'settings': settings,
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      // 1. Mevcut tüm verileri temizle
      await txn.delete('daily_records');
      await txn.delete('workers');
      await txn.delete('settings');

      // 2. Verileri geri yükle
      if (data['workers'] != null) {
        for (var row in data['workers']) {
          await txn.insert('workers', Map<String, dynamic>.from(row));
        }
      }
      if (data['daily_records'] != null) {
        for (var row in data['daily_records']) {
          await txn.insert('daily_records', Map<String, dynamic>.from(row));
        }
      }
      if (data['settings'] != null) {
        for (var row in data['settings']) {
          await txn.insert('settings', Map<String, dynamic>.from(row));
        }
      }
    });
  }

  // ================= İSTATİSTİK & RAPORLAR =================

  Future<Map<String, dynamic>> getWorkerSummary(int workerId, String startDate, String endDate) async {
    final db = await instance.database;

    // Yevmiye toplamı
    final recordResult = await db.rawQuery('''
      SELECT 
        SUM(amount) as total_earnings,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as full_days,
        COUNT(CASE WHEN status = 'half' THEN 1 END) as half_days,
        COUNT(CASE WHEN status = 'absent' THEN 1 END) as absent_days
      FROM daily_records 
      WHERE worker_id = ? AND date BETWEEN ? AND ?
    ''', [workerId, startDate, endDate]);

    final double earnings = (recordResult.first['total_earnings'] as num?)?.toDouble() ?? 0.0;
    final int fullDays = recordResult.first['full_days'] as int? ?? 0;
    final int halfDays = recordResult.first['half_days'] as int? ?? 0;
    final int absentDays = recordResult.first['absent_days'] as int? ?? 0;

    return {
      'total_earnings': earnings,
      'full_days': fullDays,
      'half_days': halfDays,
      'absent_days': absentDays,
    };
  }
}
