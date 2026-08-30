import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'transaction_history_screen.dart';
import 'fuel_tracker_screen.dart';
import 'settings_screen.dart';
import 'add_edit_transaction_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(onNavigateToFuelTab: () => _onTabTapped(2)),
      const TransactionHistoryScreen(),
      const FuelTrackerScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditTransactionScreen(),
                  ),
                );
              },
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('İşlem Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        indicatorColor: Colors.teal.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Colors.teal),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Colors.teal),
            label: 'İşlemler',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_gas_station_outlined),
            selectedIcon: Icon(Icons.local_gas_station, color: Colors.teal),
            label: 'Yakıt Takip',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Colors.teal),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
