import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yevmiye_takip/models/worker.dart';
import 'package:yevmiye_takip/models/daily_record.dart';

class WorkerCard extends StatelessWidget {
  final Worker worker;
  final DailyRecord? todaysRecord;
  final VoidCallback onTap;
  final VoidCallback onQuickWage;
  final VoidCallback onEdit;

  const WorkerCard({
    Key? key,
    required this.worker,
    required this.todaysRecord,
    required this.onTap,
    required this.onQuickWage,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    
    // Bugün çalıştı mı renk durumunu belirle
    Color statusColor = Colors.grey.shade600;
    String statusText = 'Yazılmadı';
    
    if (todaysRecord != null) {
      switch (todaysRecord!.status) {
        case WorkStatus.completed:
          statusColor = const Color(0xFF2ECC71); // Yeşil
          statusText = 'Tam Gün';
          break;
        case WorkStatus.half:
          statusColor = const Color(0xFFF39C12); // Sarı/Turuncu
          statusText = 'Yarım Gün';
          break;
        case WorkStatus.absent:
          statusColor = const Color(0xFFE74C3C); // Kırmızı
          statusText = 'Gelmedi';
          break;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Kısım: İşçi Bilgisi ve Durum Noktası
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (worker.phone != null && worker.phone!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            worker.phone!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Toplam Çalışma: ${worker.totalDays.toStringAsFixed(worker.totalDays.truncateToDouble() == worker.totalDays ? 0 : 1)} Gün',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade300),
                    ),
                    Text(
                      'Kazanç: ${currencyFormatter.format(worker.totalEarnings)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2ECC71),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Orta Kısım: Günlük Ücret ve Hızlı İşlemler
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Günlük Ücret',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormatter.format(worker.dailyWage),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35), // Turuncu yevmiye vurgusu
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Düzenle butonu
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Düzenle',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Yevmiye yaz butonu
                      ElevatedButton.icon(
                        onPressed: onQuickWage,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Yevmiye'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
