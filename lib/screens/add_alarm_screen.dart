import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yevmiye_takip/screens/ringtone_picker_screen.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/providers/alarm_provider.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';
import 'package:yevmiye_takip/models/alarm.dart';
import 'package:yevmiye_takip/theme/app_theme.dart';

class AddAlarmScreen extends StatefulWidget {
  final Alarm? alarm;
  const AddAlarmScreen({Key? key, this.alarm}) : super(key: key);

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  late int _selectedHour;
  late int _selectedMinute;
  late String _label;
  late final TextEditingController _labelController;
  bool _vibrate = true;
  bool _isPm = false;
  String _ringtoneName = 'default';
  String? _ringtonePath;

  // Gün tekrarları (0: Pzt, 6: Paz)
  final List<bool> _repeatDays = List.filled(7, false);

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();

    // Eğer alarm düzenleniyorsa değerleri doldur
    if (widget.alarm != null) {
      _selectedHour = widget.alarm!.hour;
      _selectedMinute = widget.alarm!.minute;
      _label = widget.alarm!.label;
      _ringtonePath = widget.alarm!.ringtonePath;
      _ringtoneName =
          _ringtonePath == null ? 'default' : p.basename(_ringtonePath!);
      _vibrate = widget.alarm!.vibrate;
      for (final day in widget.alarm!.repeatDays) {
        if (day >= DateTime.monday && day <= DateTime.sunday) {
          _repeatDays[day - 1] = true;
        }
      }
    } else {
      final nextMinute = DateTime.now().add(const Duration(minutes: 1));
      _selectedHour = nextMinute.hour;
      _selectedMinute = nextMinute.minute;
      _label = '';
    }
    _labelController = TextEditingController(text: _label);
    _isPm = _selectedHour >= 12;
    final usesAmPm = Provider.of<LocalizationProvider>(context, listen: false)
            .currentLanguage ==
        'en';
    final displayHour = usesAmPm ? ((_selectedHour + 11) % 12) : _selectedHour;
    _hourController = FixedExtentScrollController(initialItem: displayHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locProv = Provider.of<LocalizationProvider>(context);
    final dayNames = [
      locProv.translate('mon'),
      locProv.translate('tue'),
      locProv.translate('wed'),
      locProv.translate('thu'),
      locProv.translate('fri'),
      locProv.translate('sat'),
      locProv.translate('sun'),
    ];
    final usesAmPm = locProv.currentLanguage == 'en';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.alarm != null
              ? locProv.translate('alarm_edit')
              : locProv.translate('alarm_add'),
          style: TextStyle(
            color: AppTheme.textLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: locProv.translate('save'),
            icon: const Icon(
              Icons.check_rounded,
              color: AppTheme.primary,
              size: 28,
            ),
            onPressed: _saveAlarm,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Özel Tasarım Kaydırmalı Saat Seçici
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Seçili alanı belirten arka plan çizgisi
                Container(
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // SAAT
                    SizedBox(
                      width: 80,
                      child: ListWheelScrollView.useDelegate(
                        controller: _hourController,
                        itemExtent: 60,
                        perspective: 0.005,
                        diameterRatio: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedHour = usesAmPm
                                ? (index + 1) % 12 + (_isPm ? 12 : 0)
                                : index;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: usesAmPm ? 12 : 24,
                          builder: (context, index) {
                            final displayHour = usesAmPm
                                ? ((_selectedHour + 11) % 12)
                                : _selectedHour;
                            final isSelected = displayHour == index;
                            return Center(
                              child: Text(
                                locProv.formatArabicNumbers(
                                  (usesAmPm ? index + 1 : index)
                                      .toString()
                                      .padLeft(2, '0'),
                                ),
                                style: TextStyle(
                                  fontSize: isSelected ? 40 : 30,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.textMuted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Text(
                      ':',
                      style: TextStyle(
                        fontSize: 40,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // DAKİKA
                    SizedBox(
                      width: 80,
                      child: ListWheelScrollView.useDelegate(
                        controller: _minuteController,
                        itemExtent: 60,
                        perspective: 0.005,
                        diameterRatio: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() => _selectedMinute = index);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 60,
                          builder: (context, index) {
                            final isSelected = _selectedMinute == index;
                            return Center(
                              child: Text(
                                locProv.formatArabicNumbers(
                                  index.toString().padLeft(2, '0'),
                                ),
                                style: TextStyle(
                                  fontSize: isSelected ? 40 : 30,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.textMuted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (usesAmPm) ...[
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPeriodButton(locProv, isPm: false),
                          const SizedBox(height: 6),
                          _buildPeriodButton(locProv, isPm: true),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Alt Ayarlar
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                children: [
                  const SizedBox(height: 25),

                  // Gün Seçici (Tekrar)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      locProv.translate('repeat'),
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _repeatDays[index] = !_repeatDays[index];
                          });
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: _repeatDays[index]
                              ? AppTheme.primary
                              : AppTheme.surface,
                          child: Text(
                            dayNames[index],
                            style: TextStyle(
                              color: _repeatDays[index]
                                  ? Colors.white
                                  : AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: AppTheme.border),

                  // Alarm Sesi (Dosya Seçici)
                  ListTile(
                    title: Text(
                      locProv.translate('ringtone'),
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      _ringtonePath != null
                          ? _ringtoneName
                          : locProv.translate('default_sound'),
                      style: const TextStyle(color: AppTheme.primary),
                    ),
                    trailing: Icon(
                      Icons.library_music,
                      color: AppTheme.textMuted,
                    ),
                    onTap: _pickAudioFile,
                  ),
                  Divider(color: AppTheme.border),

                  // Titreşim
                  SwitchListTile(
                    title: Text(
                      locProv.translate('vibrate'),
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 16,
                      ),
                    ),
                    value: _vibrate,
                    activeColor: AppTheme.primary,
                    onChanged: (val) {
                      setState(() => _vibrate = val);
                    },
                  ),
                  Divider(color: AppTheme.border),

                  // Etiket
                  ListTile(
                    title: Text(
                      locProv.translate('label'),
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 16,
                      ),
                    ),
                    trailing: SizedBox(
                      width: 150,
                      child: TextField(
                        textAlign: TextAlign.right,
                        style: TextStyle(color: AppTheme.textLight),
                        decoration: InputDecoration(
                          hintText: locProv.translate('label'),
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) => _label = val,
                        controller: _labelController,
                      ),
                    ),
                  ),

                  // Sil Butonu (sadece düzenleme modunda)
                  if (widget.alarm != null) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE74C3C), // Kırmızı
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: Text(
                        locProv.translate('delete_alarm'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () {
                        if (widget.alarm!.id != null) {
                          Provider.of<AlarmProvider>(
                            context,
                            listen: false,
                          ).deleteAlarm(widget.alarm!.id!);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(
    LocalizationProvider localization, {
    required bool isPm,
  }) {
    final selected = _isPm == isPm;
    return SizedBox(
      width: 52,
      height: 42,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _isPm = isPm;
            final hour12 = ((_selectedHour + 11) % 12) + 1;
            _selectedHour = (hour12 % 12) + (isPm ? 12 : 0);
          });
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: selected ? Colors.white : AppTheme.textMuted,
          backgroundColor: selected ? AppTheme.primary : AppTheme.surface,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          localization.translate(isPm ? 'pm_format' : 'am_format'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _pickAudioFile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RingtonePickerScreen(currentRingtonePath: _ringtonePath),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        _ringtonePath = result['path'];
        _ringtoneName = result['name']!;
      });
    }
  }

  Future<void> _saveAlarm() async {
    final provider = Provider.of<AlarmProvider>(context, listen: false);
    final localization =
        Provider.of<LocalizationProvider>(context, listen: false);
    final ringtonePath = await _persistRingtone();
    final repeatDays = List<int>.generate(7, (index) => index + 1)
        .where((day) => _repeatDays[day - 1])
        .toList();

    final saved = widget.alarm != null
        ? await provider.updateAlarm(
            widget.alarm!.copyWith(
              hour: _selectedHour,
              minute: _selectedMinute,
              label: _labelController.text.trim(),
              ringtonePath: ringtonePath,
              repeatDays: repeatDays,
              vibrate: _vibrate,
            ),
            title: localization.translate('alarm_notification_title'),
            body: localization.translate('alarm_notification_body'),
            snooze: localization.translate('snooze_alarm'),
            stop: localization.translate('stop_alarm'),
          )
        : await provider.addAlarm(
            _selectedHour,
            _selectedMinute,
            _labelController.text.trim(),
            ringtonePath: ringtonePath,
            repeatDays: repeatDays,
            vibrate: _vibrate,
            title: localization.translate('alarm_notification_title'),
            body: localization.translate('alarm_notification_body'),
            snooze: localization.translate('snooze_alarm'),
            stop: localization.translate('stop_alarm'),
          );

    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localization.translate('alarm_permission_required'))),
      );
      return;
    }

    Navigator.pop(context);
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.translate('alarm_mobile_only'))),
      );
    }
  }

  Future<String?> _persistRingtone() async {
    final sourcePath = _ringtonePath;
    if (sourcePath == null || kIsWeb || sourcePath.startsWith('assets/')) {
      return sourcePath;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final ringtoneDirectory =
          Directory(p.join(directory.path, 'alarm_sounds'));
      await ringtoneDirectory.create(recursive: true);
      if (p.isWithin(ringtoneDirectory.path, sourcePath)) return sourcePath;

      final extension =
          p.extension(sourcePath).isEmpty ? '.audio' : p.extension(sourcePath);
      final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';
      final savedFile = await File(sourcePath).copy(
        p.join(ringtoneDirectory.path, fileName),
      );
      return savedFile.path;
    } catch (error) {
      debugPrint('Could not persist selected ringtone: $error');
      return sourcePath;
    }
  }
}
