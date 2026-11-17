import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/models/alarm.dart';
import 'package:yevmiye_takip/providers/alarm_provider.dart';
import 'package:yevmiye_takip/screens/add_alarm_screen.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';
import 'package:yevmiye_takip/theme/app_theme.dart';
import 'package:flutter/foundation.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AlarmProvider>(
        builder: (context, alarmProv, child) {
          if (alarmProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final alarms = alarmProv.alarms;

          if (alarms.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 24, bottom: 8),
                child: Text(
                  context.watch<LocalizationProvider>().translate('alarms'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // FAB için boşluk
                  itemCount: alarms.length,
                  itemBuilder: (context, index) {
                    final alarm = alarms[index];
                    return _buildAlarmTile(context, alarm, alarmProv);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAlarmScreen()),
          );
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm_off, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            context.watch<LocalizationProvider>().translate('no_alarms'),
            style: TextStyle(
              color: AppTheme.textLight,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.watch<LocalizationProvider>().translate(
                  'add_new_alarm_desc',
                ),
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmTile(
    BuildContext context,
    Alarm alarm,
    AlarmProvider prov,
  ) {
    final locProv = Provider.of<LocalizationProvider>(context, listen: false);
    final timeText = locProv.formatAlarmTime(alarm.hour, alarm.minute);
    final nextRing = prov.nextOccurrence(alarm);
    final timeRemaining = nextRing.difference(DateTime.now());
    final repeatDays = alarm.repeatDays
        .map((day) => locProv.translate([
              '',
              'mon',
              'tue',
              'wed',
              'thu',
              'fri',
              'sat',
              'sun',
            ][day]))
        .join(' · ');

    return Dismissible(
      key: Key('alarm_${alarm.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        prov.deleteAlarm(alarm.id!);
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddAlarmScreen(alarm: alarm),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: locProv.currentLanguage == 'ar'
                                ? 28
                                : locProv.currentLanguage == 'en'
                                    ? 34
                                    : 42,
                            fontWeight: FontWeight.w400,
                            color: alarm.isActive
                                ? AppTheme.textLight
                                : AppTheme.textMuted,
                            letterSpacing: -1,
                          ),
                        ),
                        if (alarm.label.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 8,
                              left: 8,
                              right: 8,
                            ),
                            child: Text(
                              '·',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.border,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                alarm.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (alarm.isActive) ...[
                      const SizedBox(height: 4),
                      Text(
                        locProv.formatRemainingTime(timeRemaining),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                    if (repeatDays.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        repeatDays,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: alarm.isActive,
                activeColor: Colors.white,
                activeTrackColor: AppTheme.primary,
                inactiveThumbColor: AppTheme.textMuted,
                inactiveTrackColor: AppTheme.border,
                onChanged: (value) async {
                  final locProv = Provider.of<LocalizationProvider>(
                    context,
                    listen: false,
                  );
                  if (kIsWeb) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(locProv.translate('alarm_mobile_only'))),
                    );
                    return;
                  }
                  final saved = await prov.toggleAlarm(
                    alarm,
                    title: locProv.translate('alarm_notification_title'),
                    body: locProv.translate('alarm_notification_body'),
                    snooze: locProv.translate('snooze_alarm'),
                    stop: locProv.translate('stop_alarm'),
                  );
                  if (!saved && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              locProv.translate('alarm_permission_required'))),
                    );
                    return;
                  }

                  // Eğer alarm açıldıysa kalan süreyi hesapla ve göster
                  if (value == true) {
                    final timeRemainingMsg = locProv.formatRemainingTime(
                      prov.nextOccurrence(alarm).difference(DateTime.now()),
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            timeRemainingMsg,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
