import 'package:flutter/material.dart';
import 'package:yevmiye_takip/database/database_helper.dart';
import 'package:yevmiye_takip/models/worker.dart';
import 'package:yevmiye_takip/models/daily_record.dart';

class RecordProvider extends ChangeNotifier {
  Map<int, DailyRecord> _dailyRecords = {}; // workerId -> DailyRecord
  bool _isLoading = false;
  String _currentDate = '';

  Map<int, DailyRecord> get dailyRecords => _dailyRecords;
  bool get isLoading => _isLoading;
  String get currentDate => _currentDate;

  // Günlük toplam ödeme tutarı (devamsız olanlar hariç)
  double get totalDailyPayment {
    double total = 0.0;
    _dailyRecords.forEach((_, record) {
      if (record.status != WorkStatus.absent) {
        total += record.amount;
      }
    });
    return total;
  }

  // Çalışan işçi sayısı (devamsız olanlar hariç)
  int get workingWorkersCount {
    int count = 0;
    _dailyRecords.forEach((_, record) {
      if (record.status != WorkStatus.absent) {
        count++;
      }
    });
    return count;
  }

  // Belirtilen tarihe ait kayıtları yükle
  Future<void> loadRecordsByDate(String date) async {
    _currentDate = date;
    _isLoading = true;
    notifyListeners();

    try {
      final records = await DatabaseHelper.instance.getDailyRecordsByDate(date);
      _dailyRecords = {for (var r in records) r.workerId: r};
    } catch (e) {
      debugPrint('Records load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // İşçinin günlük durumunu güncelle
  Future<void> updateRecordStatus(Worker worker, WorkStatus status) async {
    double amount = 0.0;
    if (status == WorkStatus.completed) {
      amount = worker.dailyWage;
    } else if (status == WorkStatus.half) {
      amount = worker.dailyWage / 2;
    }

    final record = DailyRecord(
      workerId: worker.id!,
      date: _currentDate,
      status: status,
      amount: amount,
    );

    try {
      await DatabaseHelper.instance.insertDailyRecord(record);
      _dailyRecords[worker.id!] = record;
      notifyListeners();
    } catch (e) {
      debugPrint('Record update error: $e');
    }
  }

  // Kalan (kaydı girilmemiş) işçileri tam gün olarak işaretle
  Future<void> markAllAsCompleted(List<Worker> workers) async {
    try {
      // Sadece henüz kaydı olmayan işçileri filtrele
      final workersToMark = workers.where((w) => !_dailyRecords.containsKey(w.id)).toList();
      
      if (workersToMark.isEmpty) return; // Zaten herkesin kaydı varsa işlem yapma

      await DatabaseHelper.instance.markAllCompleted(_currentDate, workersToMark);
      
      for (var worker in workersToMark) {
        _dailyRecords[worker.id!] = DailyRecord(
          workerId: worker.id!,
          date: _currentDate,
          status: WorkStatus.completed,
          amount: worker.dailyWage,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Mark all completed error: $e');
    }
  }

  // Tümünü işaretle geri al
  Future<void> undoMarkAll(List<Worker> workers) async {
    try {
      await DatabaseHelper.instance.undoMarkAll(_currentDate, workers);
      for (var worker in workers) {
        _dailyRecords.remove(worker.id!);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Undo mark all error: $e');
    }
  }

  // Rapor verisi yükleyici - tarih aralığına göre kayıtları getir
  Future<List<DailyRecord>> getRecordsByDateRange(String start, String end) async {
    return await DatabaseHelper.instance.getDailyRecordsByDateRange(start, end);
  }
}
