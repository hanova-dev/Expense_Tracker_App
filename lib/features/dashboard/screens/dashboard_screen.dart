import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../auth/auth_service.dart';
import 'home_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final _authService = AuthService();

  // Keep screens alive with IndexedStack so state is not lost on tab switch
  final List<Widget> _views = const [
    HomeView(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      // StreamBuilder in main.dart detects the null user and shows LoginScreen
    } catch (_) {
      // Sign-out rarely fails; silently ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartWallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: _signOut,
          ),
        ],
      ),
      // IndexedStack preserves scroll position and animation state across tabs
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/add-expense'),
              tooltip: 'Add transaction',
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }
}
