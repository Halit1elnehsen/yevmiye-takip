import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:yevmiye_takip/database/database_helper.dart';

class BackupHelper {
  /// Tüm veritabanı verilerini JSON olarak dışa aktarır ve paylaşım ekranını açar.
  static Future<bool> backupData() async {
    try {
      final data = await DatabaseHelper.instance.exportAllData();
      final jsonString = jsonEncode(data);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toString().substring(0, 19).replaceAll(':', '-').replaceAll(' ', '_');
      final file = File('${directory.path}/yevmiye_yedek_$timestamp.json');

      await file.writeAsString(jsonString);

      if (!kIsWeb) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Yevmiye Takip Yedek Dosyası ($timestamp)',
          text: 'Bu dosya Yevmiye Takip uygulamasındaki tüm verilerinizi içerir. Güvenli bir yerde saklayın.',
        );
      }
      return true;
    } catch (e) {
      debugPrint('Backup error: $e');
      return false;
    }
  }

  /// Kullanıcıya yedek dosyası seçtirip veritabanını geri yükler.
  static Future<bool> restoreData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        // Basit bütünlük kontrolü: Gerekli tablolar JSON'da var mı?
        if (data.containsKey('workers') &&
            data.containsKey('daily_records')) {
          await DatabaseHelper.instance.importAllData(data);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }
}
