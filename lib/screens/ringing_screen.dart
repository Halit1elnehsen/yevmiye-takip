import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';

class RingingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const RingingScreen({Key? key, required this.alarmSettings}) : super(key: key);

  @override
  State<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends State<RingingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _stopAlarm() async {
    await Alarm.stop(widget.alarmSettings.id);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _snoozeAlarm() async {
    final now = DateTime.now();
    // 10 dakika erteleme
    final snoozeTime = now.add(const Duration(minutes: 10));
    
    final snoozedSettings = widget.alarmSettings.copyWith(
      dateTime: snoozeTime,
    );

    await Alarm.stop(widget.alarmSettings.id);
    await Alarm.set(alarmSettings: snoozedSettings);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locProv = Provider.of<LocalizationProvider>(context);
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Koyu arka plan
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animation.value,
                    child: child,
                  );
                },
                child: const Icon(
                  Icons.alarm,
                  size: 120,
                  color: Color(0xFFFF6B35), // Turuncu alarm ikonu
                ),
              ),
              const SizedBox(height: 32),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.alarmSettings.notificationSettings.body,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 80),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildButton(
                    onTap: _stopAlarm,
                    icon: Icons.close,
                    label: locProv.translate('stop_alarm') ?? 'Kapat',
                    color: const Color(0xFFE74C3C), // Kırmızı
                  ),
                  _buildButton(
                    onTap: _snoozeAlarm,
                    icon: Icons.snooze,
                    label: locProv.translate('snooze_alarm') ?? '10dk Ertele',
                    color: const Color(0xFFF39C12), // Sarı/Turuncu
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
