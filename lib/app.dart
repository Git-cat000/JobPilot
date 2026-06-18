import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/applications/application_detail_page.dart';
import 'features/applications/application_edit_page.dart';
import 'features/applications/applications_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/import_export/import_page.dart';
import 'features/statistics/statistics_page.dart';
import 'features/settings/settings_page.dart';
import 'shared/state/app_controller.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController()..init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        title: 'JobPilot',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const JobPilotShell(),
        routes: {
          ApplicationDetailPage.routeName: (_) => const ApplicationDetailPage(),
          ApplicationEditPage.routeName: (_) => const ApplicationEditPage(),
        },
      ),
    );
  }
}

class JobPilotShell extends StatefulWidget {
  const JobPilotShell({super.key});

  @override
  State<JobPilotShell> createState() => _JobPilotShellState();
}

class _JobPilotShellState extends State<JobPilotShell> {
  int _currentIndex = 0;

  static const _pages = [
    DashboardPage(),
    ApplicationsPage(),
    ImportPage(),
    StatisticsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: '投递',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file),
            label: '导入',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
