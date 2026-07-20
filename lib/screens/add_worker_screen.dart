import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yevmiye_takip/models/worker.dart';
import 'package:yevmiye_takip/providers/worker_provider.dart';
import 'package:yevmiye_takip/widgets/custom_button.dart';

class AddWorkerScreen extends StatefulWidget {
  final Worker? worker;

  const AddWorkerScreen({Key? key, this.worker}) : super(key: key);

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _wageController;
  bool _isActive = true;

  bool get isEditMode => widget.worker != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.worker?.name ?? '');
    _phoneController = TextEditingController(text: widget.worker?.phone ?? '');
    _wageController = TextEditingController(
      text: widget.worker != null ? widget.worker!.dailyWage.toInt().toString() : '',
    );
    _isActive = widget.worker?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _wageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'İşçi Düzenle' : 'Yeni İşçi Ekle'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İsim Alanı
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    hintText: 'Örn: Ahmet Yılmaz',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 16),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen işçi adını girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Telefon Alanı
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefon Numarası',
                    hintText: 'Örn: 05551234567',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Günlük Ücret Alanı
                TextFormField(
                  controller: _wageController,
                  decoration: const InputDecoration(
                    labelText: 'Günlük Ücret (₺)',
                    hintText: 'Örn: 1500',
                    prefixIcon: Icon(Icons.money),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen günlük ücret girin';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Lütfen geçerli bir ücret girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Aktif/Pasif Durumu (Sadece düzenleme modunda)
                if (isEditMode) ...[
                  SwitchListTile(
                    title: const Text('Çalışan Aktif mi?'),
                    subtitle: const Text('Pasif yapılırsa günlük takip listesinde görünmez.'),
                    value: _isActive,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (val) {
                      setState(() {
                        _isActive = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),

                // Kaydet Butonu
                CustomButton(
                  text: isEditMode ? 'Güncelle' : 'Kaydet',
                  icon: Icons.save,
                  onPressed: _saveForm,
                  variant: ButtonVariant.primary,
                ),
                const SizedBox(height: 12),

                // Silme Butonu (Sadece düzenleme modunda)
                if (isEditMode)
                  CustomButton(
                    text: 'İşçiyi Sil',
                    icon: Icons.delete,
                    onPressed: _showDeleteConfirmDialog,
                    variant: ButtonVariant.danger,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final dailyWage = double.parse(_wageController.text);

      final workerProvider = Provider.of<WorkerProvider>(context, listen: false);

      if (isEditMode) {
        final updatedWorker = widget.worker!.copyWith(
          name: name,
          phone: phone.isNotEmpty ? phone : null,
          dailyWage: dailyWage,
          isActive: _isActive,
        );
        workerProvider.updateWorker(updatedWorker);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşçi bilgileri güncellendi.')),
        );
      } else {
        final newWorker = Worker(
          name: name,
          phone: phone.isNotEmpty ? phone : null,
          dailyWage: dailyWage,
        );
        workerProvider.addWorker(newWorker);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yeni işçi başarıyla eklendi.')),
        );
      }

      Navigator.pop(context);
    }
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('İşçiyi Sil'),
          content: Text(
            '${widget.worker!.name} adlı işçiyi silmek istediğinize emin misiniz? Bu işçiye ait tüm geçmiş yevmiye ve avans kayıtları da silinecektir!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
                workerProvider.deleteWorker(widget.worker!.id!);
                Navigator.pop(context); // Dialog kapat
                Navigator.pop(context); // Ekranı kapat
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('İşçi başarıyla silindi.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C)),
              child: const Text('Evet, Sil'),
            ),
          ],
        );
      },
    );
  }
}
