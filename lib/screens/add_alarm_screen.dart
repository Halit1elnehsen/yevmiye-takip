import 'package:flutter/material.dart';
import 'package:yevmiye_takip/screens/ringtone_picker_screen.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/providers/alarm_provider.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';
import 'package:yevmiye_takip/models/alarm.dart';

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
  bool _vibrate = true;
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
    } else {
      _selectedHour = DateTime.now().hour;
      _selectedMinute = (DateTime.now().minute + 1) % 60;
      _label = '';
    }

    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locProv = Provider.of<LocalizationProvider>(context);
    final dayNames = [locProv.translate('mon'), locProv.translate('tue'), locProv.translate('wed'), locProv.translate('thu'), locProv.translate('fri'), locProv.translate('sat'), locProv.translate('sun')];
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Arka plan
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.alarm != null ? locProv.translate('alarm_edit') : locProv.translate('alarm_add'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFFFF6B35), size: 32),
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
                    color: const Color(0xFF16213E),
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
                          setState(() => _selectedHour = index);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 24,
                          builder: (context, index) {
                            final isSelected = _selectedHour == index;
                            return Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: isSelected ? 40 : 30,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFFFF6B35) : Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const Text(':', style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
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
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: isSelected ? 40 : 30,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFFFF6B35) : Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
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
              decoration: const BoxDecoration(
                color: Color(0xFF16213E), // Kart rengi
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                children: [
                  const SizedBox(height: 25),
                  
                  // Gün Seçici (Tekrar)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(locProv.translate('repeat'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                          backgroundColor: _repeatDays[index] ? const Color(0xFFFF6B35) : const Color(0xFF0F3460),
                          child: Text(
                            dayNames[index],
                            style: TextStyle(
                              color: _repeatDays[index] ? Colors.white : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFF0F3460)),
                  
                  // Alarm Sesi (Dosya Seçici)
                  ListTile(
                    title: Text(locProv.translate('ringtone'), style: const TextStyle(color: Colors.white, fontSize: 18)),
                    subtitle: Text(_ringtonePath != null ? _ringtoneName : locProv.translate('default_sound'), style: const TextStyle(color: Color(0xFFFF6B35))),
                    trailing: const Icon(Icons.library_music, color: Colors.grey),
                    onTap: _pickAudioFile,
                  ),
                  const Divider(color: Color(0xFF0F3460)),
                  
                  // Titreşim
                  SwitchListTile(
                    title: Text(locProv.translate('vibrate'), style: const TextStyle(color: Colors.white, fontSize: 18)),
                    value: _vibrate,
                    activeColor: const Color(0xFFFF6B35),
                    onChanged: (val) {
                      setState(() => _vibrate = val);
                    },
                  ),
                  const Divider(color: Color(0xFF0F3460)),
                  
                  // Etiket
                  ListTile(
                    title: Text(locProv.translate('label'), style: const TextStyle(color: Colors.white, fontSize: 18)),
                    trailing: SizedBox(
                      width: 150,
                      child: TextField(
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFFFF6B35)),
                        decoration: InputDecoration(
                          hintText: locProv.translate('label'),
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) => _label = val,
                        controller: TextEditingController(text: _label)..selection = TextSelection.fromPosition(TextPosition(offset: _label.length)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: Text(locProv.translate('delete_alarm'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      onPressed: () {
                        if (widget.alarm!.id != null) {
                          Provider.of<AlarmProvider>(context, listen: false).deleteAlarm(widget.alarm!.id!);
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

  Future<void> _pickAudioFile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RingtonePickerScreen(currentRingtonePath: _ringtonePath),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        _ringtonePath = result['path'];
        _ringtoneName = result['name']!;
      });
    }
  }

  void _saveAlarm() async {
    final prov = Provider.of<AlarmProvider>(context, listen: false);
    
    if (widget.alarm != null) {
      // Güncelle
      final updatedAlarm = widget.alarm!.copyWith(
        hour: _selectedHour,
        minute: _selectedMinute,
        label: _label,
      );
      await prov.updateAlarm(updatedAlarm);
    } else {
      // Yeni Ekle
      await prov.addAlarm(_selectedHour, _selectedMinute, _label); // _ringtonePath de eklenebilir
    }
    
    // Kalan süreyi hesapla
    final now = DateTime.now();
    DateTime alarmDate = DateTime(now.year, now.month, now.day, _selectedHour, _selectedMinute);
    
    // Eğer seçilen saat şu andan önceyse, alarm yarına kurulur
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

    if (mounted) {
      Navigator.pop(context);
      
      // Kaydedildiğinde altta kalan süreyi gösteren mesaj (SnackBar)
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
}



