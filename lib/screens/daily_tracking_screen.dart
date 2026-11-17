import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:yevmiye_takip/providers/worker_provider.dart';
import 'package:yevmiye_takip/providers/record_provider.dart';
import 'package:yevmiye_takip/widgets/daily_record_tile.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';
import 'package:yevmiye_takip/theme/app_theme.dart';

class DailyTrackingScreen extends StatefulWidget {
  const DailyTrackingScreen({Key? key}) : super(key: key);

  @override
  State<DailyTrackingScreen> createState() => _DailyTrackingScreenState();
}

class _DailyTrackingScreenState extends State<DailyTrackingScreen> {
  late DateTime _selectedDate;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  bool _showUndoButton = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadData();
  }

  void _loadData() {
    final dateStr = _dateFormat.format(_selectedDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerProvider>(
        context,
        listen: false,
      ).loadWorkers();
      Provider.of<RecordProvider>(
        context,
        listen: false,
      ).loadRecordsByDate(dateStr);
    });
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _showUndoButton = false;
    });
    _loadData();
  }

  void _setToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _showUndoButton = false;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final locProv = Provider.of<LocalizationProvider>(context);
    final String locale;
    switch (locProv.currentLanguage) {
      case 'en':
        locale = 'en_US';
        break;
      case 'ar':
        locale = 'ar';
        break;
      default:
        locale = 'tr_TR';
    }
    final displayFormat = DateFormat('dd MMMM yyyy, EEEE', locale);
    final currencyFormatter = NumberFormat.currency(
      locale: locale,
      symbol: '₺',
      decimalDigits: 0,
    );

    return Scaffold(
      body: Column(
        children: [
          // Tarih Seçici Bölümü
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: AppTheme.cardBg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: context.watch<LocalizationProvider>().translate(
                        'previous_day',
                      ),
                  icon: const Icon(Icons.chevron_left_rounded, size: 24),
                  onPressed: () => _changeDate(-1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        displayFormat.format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_dateFormat.format(_selectedDate) !=
                          _dateFormat.format(DateTime.now()))
                        TextButton(
                          onPressed: _setToday,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            context.watch<LocalizationProvider>().translate(
                                  'return_today',
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.watch<LocalizationProvider>().translate(
                        'next_day',
                      ),
                  icon: const Icon(Icons.chevron_right_rounded, size: 24),
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
          ),

          // Liste Görünümü
          Expanded(
            child: Consumer2<WorkerProvider, RecordProvider>(
              builder: (context, workerProv, recordProv, child) {
                if (workerProv.isLoading || recordProv.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final workers = workerProv.workers
                    .where((worker) => worker.isActive)
                    .toList();

                if (workers.isEmpty) {
                  return Center(
                    child: Text(
                      context.watch<LocalizationProvider>().translate(
                            'no_active_workers_to_track',
                          ),
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    final record = recordProv.dailyRecords[worker.id];

                    return DailyRecordTile(
                      worker: worker,
                      record: record,
                      onStatusChanged: (status) async {
                        await recordProv.updateRecordStatus(worker, status);
                        workerProv.loadWorkers();
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Alt Özet ve Toplu İşlemler Paneli
          Consumer2<WorkerProvider, RecordProvider>(
            builder: (context, workerProv, recordProv, child) {
              final activeWorkers = workerProv.workers
                  .where((worker) => worker.isActive)
                  .toList();
              if (activeWorkers.isEmpty) {
                return const SizedBox.shrink();
              }

              final total = recordProv.totalDailyPayment;
              final count = recordProv.workingWorkersCount;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  border: Border(top: BorderSide(color: AppTheme.border)),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rapor Özeti
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.watch<LocalizationProvider>().translate(
                                      'worker_count',
                                    ),
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$count / ${activeWorkers.length} ${context.watch<LocalizationProvider>().translate('person')}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                context.watch<LocalizationProvider>().translate(
                                      'total_daily_wage',
                                    ),
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormatter.format(total),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Toplu butonlar
                      Row(
                        children: [
                          if (_showUndoButton) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await recordProv.undoMarkAll(activeWorkers);
                                  workerProv.loadWorkers();
                                  setState(() {
                                    _showUndoButton = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context
                                            .read<LocalizationProvider>()
                                            .translate('wages_undone'),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.undo),
                                label: Text(
                                  context
                                      .watch<LocalizationProvider>()
                                      .translate('undo'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await recordProv
                                    .markAllAsCompleted(activeWorkers);
                                workerProv.loadWorkers();
                                setState(() {
                                  _showUndoButton = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context
                                          .read<LocalizationProvider>()
                                          .translate(
                                            'remaining_completed_success',
                                          ),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.secondary,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.done_all),
                              label: Text(
                                context.watch<LocalizationProvider>().translate(
                                      'complete_remaining',
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
