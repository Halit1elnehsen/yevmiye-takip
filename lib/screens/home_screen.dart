import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart' as alarm_pkg;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:yevmiye_takip/models/worker.dart';
import 'package:yevmiye_takip/models/daily_record.dart';
import 'package:yevmiye_takip/providers/worker_provider.dart';
import 'package:yevmiye_takip/providers/record_provider.dart';
import 'package:yevmiye_takip/widgets/worker_card.dart';
import 'package:yevmiye_takip/screens/add_worker_screen.dart';
import 'package:yevmiye_takip/screens/daily_tracking_screen.dart';
import 'package:yevmiye_takip/screens/settings_screen.dart';
import 'package:yevmiye_takip/screens/alarm_screen.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';
import 'package:yevmiye_takip/theme/app_theme.dart';
import 'package:yevmiye_takip/providers/alarm_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final String _todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<WorkerProvider>(context, listen: false).loadWorkers();
      await Provider.of<RecordProvider>(
        context,
        listen: false,
      ).loadRecordsByDate(_todayDateStr);
      final localization = Provider.of<LocalizationProvider>(
        context,
        listen: false,
      );
      await localization.initialized;
      if (!mounted) return;
      final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
      await alarmProvider.loadAlarms(
        title: localization.translate('alarm_notification_title'),
        body: localization.translate('alarm_notification_body'),
        snooze: localization.translate('snooze_alarm'),
        stop: localization.translate('stop_alarm'),
      );
      for (final ringing in alarm_pkg.Alarm.ringing.value.alarms) {
        await alarmProvider.handleAlarmRinging(
          ringing,
          title: localization.translate('alarm_notification_title'),
          body: localization.translate('alarm_notification_body'),
          snooze: localization.translate('snooze_alarm'),
          stop: localization.translate('stop_alarm'),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3 tab: İşçiler, Yevmiye Yaz, Alarm
    final List<Widget> screens = [
      _buildWorkersTab(),
      const DailyTrackingScreen(),
      const AlarmScreen(),
    ];

    final List<String> titles = [
      context.watch<LocalizationProvider>().translate('workers'),
      context.watch<LocalizationProvider>().translate('daily_tracking'),
      context.watch<LocalizationProvider>().translate('alarms'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        titleSpacing: 20,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) {
                Provider.of<WorkerProvider>(
                  context,
                  listen: false,
                ).loadWorkers();
              });
            },
            tooltip: context.watch<LocalizationProvider>().translate(
                  'settings',
                ),
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            Provider.of<WorkerProvider>(context, listen: false).loadWorkers();
            Provider.of<RecordProvider>(context, listen: false)
                .loadRecordsByDate(_todayDateStr);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: context.watch<LocalizationProvider>().translate('workers'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: context.watch<LocalizationProvider>().translate(
                  'daily_tracking',
                ),
          ),
          NavigationDestination(
            icon: const Icon(Icons.alarm),
            selectedIcon: const Icon(Icons.alarm_on),
            label: context.watch<LocalizationProvider>().translate('alarms'),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToAddWorker(),
              icon: const Icon(Icons.add),
              label: Text(
                context.watch<LocalizationProvider>().translate('add_worker'),
              ),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
    );
  }

  // ================= WORKERS TAB =================

  Widget _buildWorkersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE5DA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.watch<LocalizationProvider>().translate(
                              'today',
                            ),
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          'd MMMM yyyy',
                          _dateLocale(context),
                        ).format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Consumer<WorkerProvider>(
                    builder: (context, provider, _) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        '${provider.workers.length}  ${context.watch<LocalizationProvider>().translate('person')}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: context.watch<LocalizationProvider>().translate(
                        'search',
                      ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppTheme.textMuted,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: context
                              .watch<LocalizationProvider>()
                              .translate('close'),
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppTheme.textMuted,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            Provider.of<WorkerProvider>(
                              context,
                              listen: false,
                            ).searchWorkers('');
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                  Provider.of<WorkerProvider>(
                    context,
                    listen: false,
                  ).searchWorkers(value);
                },
              ),
            ],
          ),
        ),

        // İşçi Listesi
        Expanded(
          child: Consumer2<WorkerProvider, RecordProvider>(
            builder: (context, workerProv, recordProv, child) {
              if (workerProv.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final workers = workerProv.workers;

              if (workers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isNotEmpty
                            ? context.watch<LocalizationProvider>().translate(
                                  'no_workers_found',
                                )
                            : context.watch<LocalizationProvider>().translate(
                                  'no_workers',
                                ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await workerProv.loadWorkers();
                  await recordProv.loadRecordsByDate(_todayDateStr);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    final todaysRecord = recordProv.dailyRecords[worker.id];

                    return WorkerCard(
                      worker: worker,
                      todaysRecord: todaysRecord,
                      onTap: () => _showWorkerDetailDialog(worker),
                      onQuickWage: () async {
                        await recordProv.updateRecordStatus(
                          worker,
                          WorkStatus.completed,
                          date: _todayDateStr,
                        );
                        await recordProv.loadRecordsByDate(_todayDateStr);
                        workerProv.loadWorkers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context
                                  .read<LocalizationProvider>()
                                  .translate('wage_added_success')
                                  .replaceAll('{name}', worker.name),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      onEdit: () => _navigateToEditWorker(worker),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _dateLocale(BuildContext context) {
    switch (context.watch<LocalizationProvider>().currentLanguage) {
      case 'en':
        return 'en_US';
      case 'ar':
        return 'ar';
      default:
        return 'tr_TR';
    }
  }

  void _navigateToAddWorker() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddWorkerScreen()),
    ).then((_) {
      Provider.of<WorkerProvider>(context, listen: false).loadWorkers();
    });
  }

  void _navigateToEditWorker(Worker worker) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddWorkerScreen(worker: worker)),
    ).then((_) {
      Provider.of<WorkerProvider>(context, listen: false).loadWorkers();
    });
  }

  // ================= DIALOGS =================

  void _showWorkerDetailDialog(Worker worker) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(worker.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (worker.phone != null && worker.phone!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.phone, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(worker.phone!),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  const Icon(Icons.payments, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    context
                        .watch<LocalizationProvider>()
                        .translate('daily_wage_detail')
                        .replaceAll(
                          '{wage}',
                          worker.dailyWage.toInt().toString(),
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    worker.isActive
                        ? context.watch<LocalizationProvider>().translate(
                              'active_worker',
                            )
                        : context.watch<LocalizationProvider>().translate(
                              'passive_worker',
                            ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.watch<LocalizationProvider>().translate('close'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToEditWorker(worker);
              },
              child: Text(
                context.watch<LocalizationProvider>().translate('edit'),
              ),
            ),
          ],
        );
      },
    );
  }
}
