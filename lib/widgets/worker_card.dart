import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:yevmiye_takip/models/worker.dart';
import 'package:yevmiye_takip/models/daily_record.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';
import 'package:yevmiye_takip/theme/app_theme.dart';

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
    final loc = context.watch<LocalizationProvider>();
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );
    final days = worker.totalDays.toStringAsFixed(
      worker.totalDays.truncateToDouble() == worker.totalDays ? 0 : 1,
    );
    final status = _status(loc);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFEAE5DA),
                    foregroundColor: AppTheme.secondary,
                    child: Text(
                      _initials(worker.name),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (worker.phone != null &&
                            worker.phone!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            worker.phone!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(label: status.$1, color: status.$2),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F1EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: loc.translate('total_work'),
                        value: '$days ${loc.translate('day')}',
                      ),
                    ),
                    Container(width: 1, height: 30, color: AppTheme.border),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Metric(
                        label: loc.translate('earnings'),
                        value: formatter.format(worker.totalEarnings),
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('wage_label'),
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formatter.format(worker.dailyWage),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    tooltip: loc.translate('edit'),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: AppTheme.textLight,
                      backgroundColor: const Color(0xFFF4F1EA),
                      minimumSize: const Size(44, 44),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onQuickWage,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(loc.translate('wage_button')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color) _status(LocalizationProvider loc) {
    if (todaysRecord == null) {
      return (loc.translate('not_recorded'), AppTheme.textMuted);
    }
    switch (todaysRecord!.status) {
      case WorkStatus.completed:
        return (
          loc.translate('full_day').replaceAll(' ✓', ''),
          AppTheme.success,
        );
      case WorkStatus.half:
        return (
          loc.translate('half_day').replaceAll(' ½', ''),
          AppTheme.warning,
        );
      case WorkStatus.absent:
        return (loc.translate('absent').replaceAll(' ✗', ''), AppTheme.danger);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts
        .take(2)
        .map((part) => part.isEmpty ? '' : part[0])
        .join()
        .toUpperCase();
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _Metric({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      );
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 126),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      );
}
