import 'package:flutter/material.dart';
import 'package:yevmiye_takip/database/database_helper.dart';
import 'package:yevmiye_takip/models/worker.dart';

class WorkerProvider extends ChangeNotifier {
  List<Worker> _workers = [];
  bool _isLoading = false;

  List<Worker> get workers => _workers;
  bool get isLoading => _isLoading;

  Future<void> loadWorkers({bool onlyActive = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _workers = await DatabaseHelper.instance.getAllWorkers(onlyActive: onlyActive);
    } catch (e) {
      debugPrint('Workers load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWorker(Worker worker) async {
    try {
      await DatabaseHelper.instance.insertWorker(worker);
      await loadWorkers();
    } catch (e) {
      debugPrint('Worker add error: $e');
    }
  }

  Future<void> updateWorker(Worker worker) async {
    try {
      await DatabaseHelper.instance.updateWorker(worker);
      await loadWorkers();
    } catch (e) {
      debugPrint('Worker update error: $e');
    }
  }

  Future<void> deleteWorker(int id) async {
    try {
      await DatabaseHelper.instance.deleteWorker(id);
      await loadWorkers();
    } catch (e) {
      debugPrint('Worker delete error: $e');
    }
  }

  Future<void> searchWorkers(String query) async {
    if (query.trim().isEmpty) {
      await loadWorkers();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _workers = await DatabaseHelper.instance.searchWorkers(query);
    } catch (e) {
      debugPrint('Worker search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
