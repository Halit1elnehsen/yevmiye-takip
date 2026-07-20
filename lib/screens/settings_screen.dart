import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/providers/settings_provider.dart';
import 'package:yevmiye_takip/utils/backup_helper.dart';
import 'package:yevmiye_takip/utils/notification_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProv, child) {
          final timeText = '${settingsProv.notificationHour.toString().padLeft(2, '0')}:${settingsProv.notificationMinute.toString().padLeft(2, '0')}';

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

              // ================= BİLDİRİMLER BÖLÜMÜ =================
              _buildSectionTitle('Günlük Yevmiye Hatırlatma'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.notifications_active, color: Color(0xFFF39C12)),
                        title: const Text('Hatırlatıcı Bildirimler'),
                        subtitle: const Text('Her gün belirlenen saatte yevmiye yazma bildirimi gönderir.'),
                        value: settingsProv.notificationsEnabled,
                        onChanged: (value) async {
                          await settingsProv.setNotificationsEnabled(value);
                          if (value) {
                            final granted = await NotificationHelper.requestPermissions();
                            if (granted) {
                              await NotificationHelper.scheduleDailyReminder(
                                settingsProv.notificationHour,
                                settingsProv.notificationMinute,
                              );
                            }
                          } else {
                            await NotificationHelper.cancelAllNotifications();
                          }
                        },
                      ),
                      if (settingsProv.notificationsEnabled) ...[
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.access_time, color: Colors.grey),
                          title: const Text('Hatırlatma Saati'),
                          subtitle: Text('Bildirim her gün $timeText saatinde gelecektir.'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _selectTime(context, settingsProv),
                        ),
                      ],
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
                      _buildBulletPoint('Tarih filtresiyle PDF ve Excel rapor oluşturma'),
                      _buildBulletPoint('E-posta, WhatsApp ile rapor paylaşımı'),
                      _buildBulletPoint('JSON formatında yedek alma ve geri yükleme'),
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
                Navigator.pop(context); // Dialog kapat
                final success = await BackupHelper.restoreData();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veriler yedekten başarıyla geri yüklendi! Uygulama güncellendi.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Geri yükleme başarısız veya iptal edildi.'),
                      backgroundColor: Color(0xFFE74C3C),
                    ),
                  );
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

  Future<void> _selectTime(BuildContext context, SettingsProvider settingsProv) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settingsProv.notificationHour,
        minute: settingsProv.notificationMinute,
      ),
      helpText: 'Hatırlatma Saatini Seçin',
      cancelText: 'İptal',
      confirmText: 'Ayarla',
    );

    if (pickedTime != null) {
      await settingsProv.setNotificationTime(pickedTime.hour, pickedTime.minute);
      if (settingsProv.notificationsEnabled) {
        await NotificationHelper.scheduleDailyReminder(pickedTime.hour, pickedTime.minute);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Günlük hatırlatma saati ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')} olarak güncellendi.',
          ),
        ),
      );
    }
  }
}
