import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';
import 'package:flutter/services.dart';


class RingtonePickerScreen extends StatefulWidget {
  final String? currentRingtonePath;
  
  const RingtonePickerScreen({Key? key, this.currentRingtonePath}) : super(key: key);

  @override
  State<RingtonePickerScreen> createState() => _RingtonePickerScreenState();
}

class _RingtonePickerScreenState extends State<RingtonePickerScreen> {
  final List<Map<String, String>> _defaultRingtones = [
    {'name': 'Alarm Clock', 'duration': '00:05', 'path': 'assets/alarm1.wav'},
    {'name': 'Beep', 'duration': '00:03', 'path': 'assets/alarm2.wav'},
    {'name': 'Breeze', 'duration': '00:10', 'path': 'assets/ring1.wav'},
    {'name': 'Chimes', 'duration': '00:08', 'path': 'assets/chimes.wav'},
  ];

  // Kullanıcının seçtiği özel ses (Şu an tek bir ses tutuluyor, veritabanına genişletilebilir)
  Map<String, String>? _myRingtone;

  @override
  void initState() {
    super.initState();
    if (widget.currentRingtonePath != null && widget.currentRingtonePath != 'default') {
      final name = widget.currentRingtonePath!.split('/').last;
      _myRingtone = {'name': name, 'path': widget.currentRingtonePath!, 'duration': 'Özel Müzik'};
    }
  }

  // MethodChannel for native Music Picker
  static const platform = MethodChannel('com.yevmiye/ringtone');

  Future<void> _showPickerOptions(BuildContext context) async {
    final locProv = Provider.of<LocalizationProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(locProv.translate('ringtones_title'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.music_note, color: Color(0xFFFF6B35), size: 30),
                title: Text(locProv.translate('from_music_app') ?? 'Müzik Uygulamasından', style: const TextStyle(color: Colors.white, fontSize: 18)),
                subtitle: Text(locProv.translate('from_music_app_desc') ?? 'Telefondaki müziklerden seç', style: const TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.pop(context);
                  _pickMusicNative();
                },
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.folder, color: Color(0xFFF1C40F), size: 30),
                title: Text(locProv.translate('from_file_manager') ?? 'Dosya Yöneticisinden', style: const TextStyle(color: Colors.white, fontSize: 18)),
                subtitle: Text(locProv.translate('from_file_manager_desc') ?? 'Dosyalar uygulamasından seç', style: const TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAudioFile();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMusicNative() async {
    try {
      final Map<dynamic, dynamic>? result = await platform.invokeMethod('pickMusic');
      if (result != null) {
        setState(() {
          _myRingtone = {
            'name': result['name'] ?? 'Özel Müzik',
            'path': result['path'] ?? '',
            'duration': 'Müzik'
          };
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        final locProv = Provider.of<LocalizationProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(locProv.translate('file_error'))),
        );
      }
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final name = result.files.single.name;
        
        setState(() {
          _myRingtone = {'name': name, 'path': path, 'duration': 'Dosya'};
        });
      }
    } catch (e) {
      if (mounted) {
        final locProv = Provider.of<LocalizationProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(locProv.translate('file_error'))),
        );
      }
    }
  }

  void _applyRingtone(Map<String, String> ringtone) {
    Navigator.pop(context, ringtone);
  }

  @override
  Widget build(BuildContext context) {
    final locProv = Provider.of<LocalizationProvider>(context);
    return Scaffold(
      backgroundColor: Colors.black, // MIUI tasarımı için simsiyah arka plan
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(locProv.translate('ringtones_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner veya Büyük Seçenekler
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickMusicNative,
                          child: Container(
                            height: 70,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B35).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.music_note, color: Color(0xFFFF6B35)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    locProv.translate('from_music_app') ?? 'Choose local ringtone',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickAudioFile,
                          child: Container(
                            height: 70,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1C40F).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.folder, color: Color(0xFFF1C40F)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    locProv.translate('from_file_manager') ?? 'Pre-installed ringtones',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Benim Zil Seslerim
                  Text(locProv.translate('my_ringtones') ?? 'My ringtones', style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          
          if (_myRingtone != null)
            SliverToBoxAdapter(
              child: _buildRingtoneItem(_myRingtone!, locProv),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(locProv.translate('no_custom_music'), style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
              ),
            ),
            
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 8.0),
              child: Text(locProv.translate('system_sounds') ?? 'Alarms', style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
          
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildRingtoneItem(_defaultRingtones[index], locProv);
              },
              childCount: _defaultRingtones.length,
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildRingtoneItem(Map<String, String> ringtone, LocalizationProvider locProv) {
    final bool isSelected = widget.currentRingtonePath == ringtone['path'] || 
                           (widget.currentRingtonePath == null && ringtone['path'] == 'assets/alarm1.wav');
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        ringtone['name']!,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        ringtone['duration']!,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      trailing: ElevatedButton(
        onPressed: () => _applyRingtone(ringtone),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFFFF6B35) : const Color(0xFF1E3A5F), // MIUI tarzı koyu mavi
          foregroundColor: isSelected ? Colors.white : const Color(0xFF64B5F6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          minimumSize: const Size(80, 36),
        ),
        child: Text(isSelected ? (locProv.translate('selected') ?? 'Selected') : (locProv.translate('apply') ?? 'Apply')),
      ),
    );
  }
}

