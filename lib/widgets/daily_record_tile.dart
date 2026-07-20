import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yevmiye_takip/models/worker.dart';
import 'package:yevmiye_takip/models/daily_record.dart';

class DailyRecordTile extends StatelessWidget {
  final Worker worker;
  final DailyRecord? record;
  final Function(WorkStatus) onStatusChanged;

  const DailyRecordTile({
    Key? key,
    required this.worker,
    required this.record,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
    final activeStatus = record?.status;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // İsim ve Yevmiye Bilgisi
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Toplam: ${worker.totalDays.toStringAsFixed(worker.totalDays.truncateToDouble() == worker.totalDays ? 0 : 1)} Gün  •  ${currencyFormatter.format(worker.totalEarnings)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.greenAccent.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormatter.format(worker.dailyWage),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFFF6B35),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Yevmiye Durum Seçim Butonları
            Row(
              children: [
                // Tam Gün
                Expanded(
                  child: _buildStatusButton(
                    context: context,
                    label: 'Tam Gün',
                    icon: Icons.check_circle_outline,
                    activeIcon: Icons.check_circle,
                    buttonStatus: WorkStatus.completed,
                    activeStatus: activeStatus,
                    activeColor: const Color(0xFF2ECC71),
                  ),
                ),
                const SizedBox(width: 8),
                // Yarım Gün
                Expanded(
                  child: _buildStatusButton(
                    context: context,
                    label: 'Yarım Gün',
                    icon: Icons.star_half_outlined,
                    activeIcon: Icons.star_half,
                    buttonStatus: WorkStatus.half,
                    activeStatus: activeStatus,
                    activeColor: const Color(0xFFF39C12),
                  ),
                ),
                const SizedBox(width: 8),
                // Gelmedi
                Expanded(
                  child: _buildStatusButton(
                    context: context,
                    label: 'Gelmedi',
                    icon: Icons.cancel_outlined,
                    activeIcon: Icons.cancel,
                    buttonStatus: WorkStatus.absent,
                    activeStatus: activeStatus,
                    activeColor: const Color(0xFFE74C3C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required WorkStatus buttonStatus,
    required WorkStatus? activeStatus,
    required Color activeColor,
  }) {
    final isActive = activeStatus == buttonStatus;

    return InkWell(
      onTap: () => onStatusChanged(buttonStatus),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : Colors.white12,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? activeColor : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
