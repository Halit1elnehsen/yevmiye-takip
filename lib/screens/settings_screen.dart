import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/providers/settings_provider.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsProv = Provider.of<SettingsProvider>(context);
    final locProv = Provider.of<LocalizationProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(locProv.translate('settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dil Seçimi
          _buildSectionHeader(locProv.translate('language'), Icons.language),
          Card(
            color: const Color(0xFF16213E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text(locProv.translate('turkish'), style: const TextStyle(color: Colors.white)),
                  value: 'tr',
                  groupValue: locProv.currentLanguage,
                  activeColor: const Color(0xFFFF6B35),
                  onChanged: (val) {
                    if (val != null) locProv.setLanguage(val);
                  },
                ),
                const Divider(color: Color(0xFF0F3460), height: 1),
                RadioListTile<String>(
                  title: Text(locProv.translate('english'), style: const TextStyle(color: Colors.white)),
                  value: 'en',
                  groupValue: locProv.currentLanguage,
                  activeColor: const Color(0xFFFF6B35),
                  onChanged: (val) {
                    if (val != null) locProv.setLanguage(val);
                  },
                ),
                const Divider(color: Color(0xFF0F3460), height: 1),
                RadioListTile<String>(
                  title: Text(locProv.translate('arabic'), style: const TextStyle(color: Colors.white)),
                  value: 'ar',
                  groupValue: locProv.currentLanguage,
                  activeColor: const Color(0xFFFF6B35),
                  onChanged: (val) {
                    if (val != null) locProv.setLanguage(val);
                  },
                ),
              ],
            ),
          ),
          
          // Bildirimler bölümü kaldırıldı
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF6B35), size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
