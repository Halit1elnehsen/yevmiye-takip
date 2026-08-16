import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';


class RingtonePickerScreen extends StatefulWidget {
  final String? currentRingtonePath;
  
  const RingtonePickerScreen({Key? key, this.currentRingtonePath}) : super(key: key);

  @override
  State<RingtonePickerScreen> createState() => _RingtonePickerScreenState();
}

class _RingtonePickerScreenState extends State<RingtonePickerScreen> {
  // Varsayılan sistem sesleri (örnek liste)
  final List<Map<String, String>> _defaultRingtones = [
    {'name': 'Alarm clock', 'duration': '00:03', 'path': 'default'},
    {'name': 'Beep', 'duration': '00:02', 'path': 'default'},
    {'name': 'Breeze', 'duration': '00:17', 'path': 'default'},
    {'name': 'Chimes', 'duration': '00:08', 'path': 'default'},
    {'name': 'Daydream', 'duration': '00:32', 'path': 'default'},
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
          _myRingtone = {'name': name, 'path': path, 'duration': 'Özel Müzik'};
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
                  // Üst Butonlar (Yerel Zil Sesi / Ön Yüklü)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickAudioFile,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.music_note, color: Color(0xFFF39C12)),
                                const SizedBox(width: 8),
                                Text(locProv.translate('local_ringtone'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.folder, color: Color(0xFFF1C40F)),
                              const SizedBox(width: 8),
                              Text(locProv.translate('preloaded'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Benim Zil Seslerim
                  Text(locProv.translate('my_ringtones'), style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
              child: Text(locProv.translate('system_sounds'), style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // FAB için boşluk
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAudioFile,
        backgroundColor: const Color(0xFFFF6B35), // Kullanıcının istediği turuncu renk
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildRingtoneItem(Map<String, String> ringtone, LocalizationProvider locProv) {
    final bool isSelected = widget.currentRingtonePath == ringtone['path'] || 
                           (widget.currentRingtonePath == null && ringtone['path'] == 'default');
    
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ringtone['name']!,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ringtone['duration']!,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _applyRingtone(ringtone),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? const Color(0xFFFF6B35) : const Color(0xFF1E1E1E), // Turuncu / Koyu Gri
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(isSelected ? locProv.translate('selected') : locProv.translate('apply')),
            ),
          ],
        ),
      ),
    );
  }
}

