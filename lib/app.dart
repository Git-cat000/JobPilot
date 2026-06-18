import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'core/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/applications/application_detail_page.dart';
import 'features/applications/application_edit_page.dart';
import 'features/applications/applications_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/import_export/import_page.dart';
import 'features/statistics/statistics_page.dart';
import 'features/settings/settings_page.dart';
import 'shared/state/app_controller.dart';
import 'shared/widgets/adaptive.dart';

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
    final controller = AppScope.watch(context);
    final strings = AppStrings(controller.language);
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: isIos
          ? CupertinoTabBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              activeColor: AppTheme.primary,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.space_dashboard_outlined),
                  activeIcon: const Icon(Icons.space_dashboard),
                  label: strings.home,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.work_outline),
                  activeIcon: const Icon(Icons.work),
                  label: strings.applications,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.upload_file_outlined),
                  activeIcon: const Icon(Icons.upload_file),
                  label: strings.import,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.query_stats_outlined),
                  activeIcon: const Icon(Icons.query_stats),
                  label: strings.statistics,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings_outlined),
                  activeIcon: const Icon(Icons.settings),
                  label: strings.settings,
                ),
              ],
            )
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.space_dashboard_outlined),
                  selectedIcon: const Icon(Icons.space_dashboard),
                  label: strings.home,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.work_outline),
                  selectedIcon: const Icon(Icons.work),
                  label: strings.applications,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.upload_file_outlined),
                  selectedIcon: const Icon(Icons.upload_file),
                  label: strings.import,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.query_stats_outlined),
                  selectedIcon: const Icon(Icons.query_stats),
                  label: strings.statistics,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: strings.settings,
                ),
              ],
            ),
    );
  }
}
