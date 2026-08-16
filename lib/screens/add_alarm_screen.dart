import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/providers/alarm_provider.dart';

class AddAlarmScreen extends StatefulWidget {
  const AddAlarmScreen({Key? key}) : super(key: key);

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  late int _selectedHour;
  late int _selectedMinute;
  String _label = 'Yevmiye';
  bool _vibrate = true;
  bool _deleteAfter = false; // Şimdilik sadece görsel

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedHour = now.hour;
    _selectedMinute = now.minute;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Uygulama arka plan rengi
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alarm Ekle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 40),
          // Saat Seçici (Cupertino benzeri dev saat görünümü)
          GestureDetector(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFFFF6B35),
                        onPrimary: Colors.white,
                        surface: Color(0xFF16213E),
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (time != null) {
                setState(() {
                  _selectedHour = time.hour;
                  _selectedMinute = time.minute;
                });
              }
            },
            child: Container(
              alignment: Alignment.center,
              child: Text(
                '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Zamanı değiştirmek için saate dokunun',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 50),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF16213E), // Kart rengi
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  
                  // Etiket
                  ListTile(
                    title: const Text('Etiket', style: TextStyle(color: Colors.white, fontSize: 18)),
                    trailing: SizedBox(
                      width: 150,
                      child: TextField(
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.grey),
                        decoration: const InputDecoration(
                          hintText: 'Etiket girin',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) => _label = val,
                        controller: TextEditingController(text: _label)..selection = TextSelection.fromPosition(TextPosition(offset: _label.length)),
                      ),
                    ),
                  ),
                  const Divider(color: Color(0xFF0F3460)),
                  
                  // Melodi (Sadece bilgi, telefondan değişir)
                  ListTile(
                    title: const Text('Alarm Sesi', style: TextStyle(color: Colors.white, fontSize: 18)),
                    trailing: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Telefon Ayarları', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                      ],
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Alarm sesi telefon ayarlarından değiştirilebilir.')),
                      );
                    },
                  ),
                  const Divider(color: Color(0xFF0F3460)),
                  
                  // Titreşim
                  SwitchListTile(
                    title: const Text('Alarm çalarken titret', style: TextStyle(color: Colors.white, fontSize: 18)),
                    value: _vibrate,
                    activeColor: const Color(0xFFFF6B35),
                    onChanged: (val) {
                      setState(() => _vibrate = val);
                    },
                  ),
                  const Divider(color: Color(0xFF0F3460)),
                  
                  // Çaldıktan sonra sil
                  SwitchListTile(
                    title: const Text('Çaldıktan sonra sil', style: TextStyle(color: Colors.white, fontSize: 18)),
                    value: _deleteAfter,
                    activeColor: const Color(0xFFFF6B35),
                    onChanged: (val) {
                      setState(() => _deleteAfter = val);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveAlarm() async {
    final prov = Provider.of<AlarmProvider>(context, listen: false);
    await prov.addAlarm(_selectedHour, _selectedMinute, _label);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⏰ Alarm ${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')} saatine kuruldu!',
          ),
          backgroundColor: const Color(0xFF2ECC71),
        ),
      );
    }
  }
}
