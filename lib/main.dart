import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/export_service.dart';
import 'services/settings_service.dart';
import 'services/history_service.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const WattWiseApp());
}

class WattWiseApp extends StatelessWidget {
  const WattWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WattWise',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF2ECC71),
          secondary: Color(0xFF3498DB),
          tertiary: Color(0xFFF1C40F),
          surface: Colors.white,
          surfaceContainer: Color(0xFFF5F6FA),
          error: Color(0xFFE74C3C),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF2C3E50),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF2ECC71),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF2ECC71),
          secondary: Color(0xFF3498DB),
          tertiary: Color(0xFFF1C40F),
          surface: Color(0xFF1E272E),
          surfaceContainer: Color(0xFF0F1419),
          error: Color(0xFFE74C3C),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _onExportTap() async {
    final settingsService = SettingsService();
    final storageService = StorageService();
    final historyService = HistoryService();
    final exportService = ExportService();

    final costPerKwh = await settingsService.getCostPerKwh();
    final currency = await settingsService.getCurrencySymbol();
    final appliances = await storageService.loadAppliances();
    final history = await historyService.getSnapshots();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              subtitle: const Text('Spreadsheet-compatible format'),
              onTap: () {
                Navigator.pop(context);
                exportService.shareCsv(
                  appliances: appliances,
                  costPerKwh: costPerKwh,
                  currency: currency,
                  history: history,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              subtitle: const Text('Formatted report with tables'),
              onTap: () {
                Navigator.pop(context);
                exportService.sharePdf(
                  appliances: appliances,
                  costPerKwh: costPerKwh,
                  currency: currency,
                  history: history,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const HomeScreen(),
      const HistoryScreen(),
      SettingsScreen(onExportTap: _onExportTap),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
