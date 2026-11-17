import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:yevmiye_takip/models/worker.dart';
import 'package:yevmiye_takip/models/daily_record.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';
import 'package:yevmiye_takip/theme/app_theme.dart';

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
    final loc = context.watch<LocalizationProvider>();
    final locale = loc.currentLanguage == 'en'
        ? 'en_US'
        : loc.currentLanguage == 'ar'
            ? 'ar'
            : 'tr_TR';
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '₺',
      decimalDigits: 0,
    );
    final days = worker.totalDays.toStringAsFixed(
      worker.totalDays.truncateToDouble() == worker.totalDays ? 0 : 1,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: const Color(0xFFEAE5DA),
                  foregroundColor: AppTheme.secondary,
                  child: Text(
                    worker.name.trim().isNotEmpty
                        ? worker.name.trim()[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${loc.translate('total')}: $days ${loc.translate('day')}  ·  ${formatter.format(worker.totalEarnings)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatter.format(worker.dailyWage),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _statusButton(
                    context,
                    loc.translate('full_day').replaceAll(' ✓', ''),
                    WorkStatus.completed,
                    AppTheme.success,
                    Icons.check_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statusButton(
                    context,
                    loc.translate('half_day').replaceAll(' ½', ''),
                    WorkStatus.half,
                    AppTheme.warning,
                    Icons.timelapse_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statusButton(
                    context,
                    loc.translate('absent').replaceAll(' ✗', ''),
                    WorkStatus.absent,
                    AppTheme.danger,
                    Icons.close_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusButton(
    BuildContext context,
    String label,
    WorkStatus value,
    Color color,
    IconData icon,
  ) {
    final active = record?.status == value;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Material(
        color: active ? color.withValues(alpha: 0.1) : const Color(0xFFF7F5F0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: active ? color : AppTheme.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => onStatusChanged(value),
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  active ? Icons.check_rounded : icon,
                  color: active ? color : AppTheme.textMuted,
                  size: 17,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: active ? color : AppTheme.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
