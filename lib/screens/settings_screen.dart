import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/providers/settings_provider.dart';
import 'package:yevmiye_takip/utils/backup_helper.dart';
import 'package:yevmiye_takip/utils/notification_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProv, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ================= YEDEKLEME BÖLÜMÜ =================
              _buildSectionTitle('Veri Yedekleme ve Kurtarma'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.backup, color: Color(0xFFFF6B35)),
                        title: const Text('Manuel Yedek Al'),
                        subtitle: const Text('Tüm verilerinizi JSON dosyası olarak kaydedin ve paylaşın.'),
                        onTap: () => _handleBackup(context),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.settings_backup_restore, color: Color(0xFF2ECC71)),
                        title: const Text('Yedekten Geri Yükle'),
                        subtitle: const Text('Daha önce aldığınız yedek dosyasından verilerinizi geri yükleyin.'),
                        onTap: () => _handleRestore(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ================= HAKKINDA BÖLÜMÜ =================
              _buildSectionTitle('Uygulama Hakkında'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF004E89)),
                          SizedBox(width: 10),
                          Text(
                            'Yevmiye Takip v1.0.0',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Bu uygulama şantiyelerde offline olarak işçi yevmiyelerini kolayca takip etmek amacıyla tasarlanmıştır.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 20),
                      const Text(
                        'Özellikler:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      _buildBulletPoint('Tamamen offline çalışma (İnternetsiz mod)'),
                      _buildBulletPoint('Kayıtları anlık SQLite veritabanında saklama'),
                      _buildBulletPoint('JSON formatında yedek alma ve geri yükleme'),
                      _buildBulletPoint('Günlük alarm hatırlatıcı sistemi'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF6B35),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context) async {
    final success = await BackupHelper.backupData();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yedek başarıyla alındı ve paylaşıldı.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yedek alınırken hata oluştu!'),
            backgroundColor: Color(0xFFE74C3C),
          ),
        );
      }
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yedekten Geri Yükle'),
          content: const Text(
            'Yedek dosyasını geri yüklediğinizde, mevcut tüm kayıtlarınız silinecek ve yedek dosyasındaki veriler yazılacaktır. Devam etmek istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await BackupHelper.restoreData();
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veriler yedekten başarıyla geri yüklendi!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Geri yükleme başarısız veya iptal edildi.'),
                        backgroundColor: Color(0xFFE74C3C),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71)),
              child: const Text('Evet, Yükle'),
            ),
          ],
        );
      },
    );
  }
}
