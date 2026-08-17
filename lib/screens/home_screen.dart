import 'package:flutter/material.dart';
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
import 'package:yevmiye_takip/providers/settings_provider.dart';
import 'package:yevmiye_takip/screens/alarm_screen.dart';
import 'package:yevmiye_takip/providers/localization_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerProvider>(context, listen: false).loadWorkers();
      Provider.of<RecordProvider>(context, listen: false).loadRecordsByDate(_todayDateStr);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) {
                Provider.of<WorkerProvider>(context, listen: false).loadWorkers();
              });
            },
            tooltip: context.watch<LocalizationProvider>().translate('settings'),
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
            label: context.watch<LocalizationProvider>().translate('daily_tracking'),
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
              label: Text(context.watch<LocalizationProvider>().translate('add_worker')),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
    );
  }

  // ================= WORKERS TAB =================

  Widget _buildWorkersTab() {
    return Column(
      children: [
        // Arama Çubuğu
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: context.watch<LocalizationProvider>().translate('search'),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        Provider.of<WorkerProvider>(context, listen: false).searchWorkers('');
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              Provider.of<WorkerProvider>(context, listen: false).searchWorkers(value);
            },
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
                      const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isNotEmpty
                            ? context.watch<LocalizationProvider>().translate('no_workers_found')
                            : context.watch<LocalizationProvider>().translate('no_workers'),
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      if (_searchController.text.isEmpty) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToAddWorker(),
                          icon: const Icon(Icons.add),
                          label: Text(context.watch<LocalizationProvider>().translate('add_first_worker')),
                        ),
                      ]
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    final todaysRecord = recordProv.dailyRecords[worker.id];

                    return WorkerCard(
                      worker: worker,
                      todaysRecord: todaysRecord,
                      onTap: () => _showWorkerDetailDialog(worker),
                      onQuickWage: () async {
                        await recordProv.updateRecordStatus(worker, WorkStatus.completed);
                        workerProv.loadWorkers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.read<LocalizationProvider>().translate('wage_added_success').replaceAll('{name}', worker.name)),
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
                  Text(context.watch<LocalizationProvider>().translate('daily_wage_detail').replaceAll('{wage}', worker.dailyWage.toInt().toString())),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(worker.isActive ? context.watch<LocalizationProvider>().translate('active_worker') : context.watch<LocalizationProvider>().translate('passive_worker')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.watch<LocalizationProvider>().translate('close')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToEditWorker(worker);
              },
              child: Text(context.watch<LocalizationProvider>().translate('edit')),
            ),
          ],
        );
      },
    );
  }
}

