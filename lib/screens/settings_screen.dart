import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/providers/alarm_provider.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';
import 'package:yevmiye_takip/providers/settings_provider.dart';
import 'package:yevmiye_takip/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.translate('settings')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(
              localization.translate('language'), Icons.language),
          Card(
            child: Column(
              children: [
                _languageOption(context, localization, 'tr', 'turkish'),
                const Divider(height: 1),
                _languageOption(context, localization, 'en', 'english'),
                const Divider(height: 1),
                _languageOption(context, localization, 'ar', 'arabic'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
              localization.translate('appearance'), Icons.contrast),
          Card(
            child: SwitchListTile.adaptive(
              secondary: Icon(
                settings.darkModeEnabled ? Icons.dark_mode : Icons.light_mode,
                color: AppTheme.primary,
              ),
              title: Text(localization.translate('dark_mode')),
              subtitle: Text(localization.translate('dark_mode_desc')),
              value: settings.darkModeEnabled,
              onChanged: settings.setDarkModeEnabled,
              activeColor: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              localization.translate('local_data_note'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageOption(
    BuildContext context,
    LocalizationProvider localization,
    String code,
    String label,
  ) {
    return RadioListTile<String>(
      title: Text(localization.translate(label)),
      value: code,
      groupValue: localization.currentLanguage,
      activeColor: AppTheme.primary,
      onChanged: (value) {
        if (value != null) _changeLanguage(context, localization, value);
      },
    );
  }

  Future<void> _changeLanguage(
    BuildContext context,
    LocalizationProvider localization,
    String language,
  ) async {
    await localization.setLanguage(language);
    if (!context.mounted) return;
    await context.read<AlarmProvider>().loadAlarms(
          title: localization.translate('alarm_notification_title'),
          body: localization.translate('alarm_notification_body'),
          snooze: localization.translate('snooze_alarm'),
          stop: localization.translate('stop_alarm'),
        );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
