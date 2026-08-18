import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/models/alarm.dart';
import 'package:yevmiye_takip/providers/alarm_provider.dart';
import 'package:yevmiye_takip/screens/add_alarm_screen.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Uygulama lacivert tema rengi
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
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
        backgroundColor: const Color(0xFFFF6B35), // Tema turuncusu
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
          const Icon(Icons.alarm_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            context.watch<LocalizationProvider>().translate('no_alarms'),
            style: const TextStyle(color: Colors.grey, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            context.watch<LocalizationProvider>().translate('add_new_alarm_desc'),
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmTile(BuildContext context, Alarm alarm, AlarmProvider prov) {
    final locProv = Provider.of<LocalizationProvider>(context, listen: false);
    final isTurkish = locProv.currentLanguage == 'tr';
    
    String timeText;
    String amPm = '';
    
    if (isTurkish) {
      timeText = '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
    } else {
      int displayHour = alarm.hour % 12;
      if (displayHour == 0) displayHour = 12;
      amPm = alarm.hour >= 12 ? (locProv.translate('pm_format') ?? 'PM') : (locProv.translate('am_format') ?? 'AM');
      timeText = '${displayHour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
    }
    
    timeText = locProv.formatArabicNumbers(timeText);
    
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
            color: const Color(0xFF232323), // Lüks koyu gri
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w400,
                        color: alarm.isActive ? Colors.white : Colors.grey.shade600,
                        letterSpacing: -1,
                      ),
                    ),
                    if (!isTurkish)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          amPm,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: alarm.isActive ? Colors.grey.shade400 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    if (alarm.label.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                        child: Text(
                          '|',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
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
                              color: alarm.isActive ? Colors.grey.shade500 : Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: alarm.isActive,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFFFF6B35), // Turuncu
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade800,
                onChanged: (value) async {
                  final locProv = Provider.of<LocalizationProvider>(context, listen: false);
                  await prov.toggleAlarm(
                    alarm,
                    title: locProv.translate('alarm_notification_title') ?? '⏰ YEVMİYE ALARM! ⏰',
                    body: locProv.translate('alarm_notification_body') ?? 'Yevmiyeleri yazmayı unutma!',
                    stop: locProv.translate('close') ?? 'Kapat',
                  );
                  
                  // Eğer alarm açıldıysa kalan süreyi hesapla ve göster
                  if (value == true) {
                    final now = DateTime.now();
                    DateTime alarmDate = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
                    
                    if (alarmDate.isBefore(now)) {
                      alarmDate = alarmDate.add(const Duration(days: 1));
                    }
                    
                    final difference = alarmDate.difference(now);
                    final hours = difference.inHours;
                    final minutes = difference.inMinutes % 60;
                    
                    String timeRemainingMsg = locProv.translate('time_left');
                    if (hours > 0) timeRemainingMsg += '$hours ${locProv.translate('hours')}';
                    if (minutes > 0) timeRemainingMsg += '$minutes ${locProv.translate('minutes')}';
                    if (hours == 0 && minutes == 0) timeRemainingMsg += locProv.translate('less_than_minute');
                    timeRemainingMsg += locProv.translate('left');
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            timeRemainingMsg,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF2ECC71),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
