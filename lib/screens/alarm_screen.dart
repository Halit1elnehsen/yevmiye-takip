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
    final timeText = '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
    
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<LocalizationProvider>().translate('alarm_deleted'))),
        );
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E), // Tema kart rengi
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: alarm.isActive ? Colors.white : Colors.grey,
                    ),
                  ),
                  if (alarm.label.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        alarm.label,
                        style: TextStyle(
                          fontSize: 14,
                          color: alarm.isActive ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              Switch(
                value: alarm.isActive,
                onChanged: (value) async {
                  await prov.toggleAlarm(alarm);
                  
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
                    
                    final locProv = Provider.of<LocalizationProvider>(context, listen: false);
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
                activeColor: const Color(0xFFFF6B35), // Tema turuncusu
              ),
            ],
          ),
        ),
      ),
    );
  }
}
