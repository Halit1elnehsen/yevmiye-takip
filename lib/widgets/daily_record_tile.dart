import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:yevmiye_takip/models/worker.dart';
import 'package:yevmiye_takip/models/daily_record.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';

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
    final locProv = Provider.of<LocalizationProvider>(context);
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
                        '${locProv.translate('total')}: ${worker.totalDays.toStringAsFixed(worker.totalDays.truncateToDouble() == worker.totalDays ? 0 : 1)} ${locProv.translate('day')}  •  ${currencyFormatter.format(worker.totalEarnings)}',
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
                    label: locProv.translate('full_day').replaceAll(' ✓', ''),
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
                    label: locProv.translate('half_day').replaceAll(' ½', ''),
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
                    label: locProv.translate('absent').replaceAll(' ✗', ''),
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
    final isActive = buttonStatus == activeStatus;
    
    return Material(
      color: isActive ? activeColor.withOpacity(0.2) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isActive ? activeColor : Colors.grey.shade700,
          width: isActive ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => onStatusChanged(buttonStatus),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? activeColor : Colors.grey.shade400,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? activeColor : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
