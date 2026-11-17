import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';

class RingingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const RingingScreen({super.key, required this.alarmSettings});

  @override
  State<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends State<RingingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.94,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _stopAlarm() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    await Alarm.stop(widget.alarmSettings.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _snoozeAlarm() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    final snoozed = widget.alarmSettings.copyWith(
      dateTime: DateTime.now().add(const Duration(minutes: 10)),
    );
    await Alarm.stop(widget.alarmSettings.id);
    await Alarm.set(alarmSettings: snoozed);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationProvider>();
    final now = DateTime.now();
    final timeText = localization.formatAlarmTime(now.hour, now.minute);
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF101512),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _pulse,
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFC65A2E).withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFC65A2E)
                                  .withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.alarm_rounded,
                            size: 48,
                            color: Color(0xFFF08B5D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),
                      Text(
                        localization.translate('alarm_ringing'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFAEB9B0),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          timeText,
                          style: const TextStyle(
                            color: Color(0xFFF5F2EA),
                            fontSize: 72,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -2.2,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.alarmSettings.notificationSettings.body,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD1D9D2),
                          fontSize: 20,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 52),
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: FilledButton.icon(
                          onPressed: _stopping ? null : _stopAlarm,
                          icon:
                              const Icon(Icons.stop_circle_outlined, size: 24),
                          label: Text(
                            localization.translate('stop_alarm'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFC65A2E),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF74422F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _stopping ? null : _snoozeAlarm,
                          icon: const Icon(Icons.snooze_rounded),
                          label: Text(localization.translate('snooze_alarm')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            side: const BorderSide(color: Color(0xFF47534A)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
