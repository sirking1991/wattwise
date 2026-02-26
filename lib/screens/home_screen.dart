import 'package:flutter/material.dart';
import '../models/appliance.dart';
import '../models/appliance_template.dart';
import '../models/consumption_snapshot.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../services/history_service.dart';
import '../widgets/appliance_card.dart';
import '../widgets/budget_progress.dart';
import '../widgets/consumption_summary.dart';
import 'appliance_edit_screen.dart';
import 'budget_screen.dart';
import 'template_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storageService = StorageService();
  final _settingsService = SettingsService();
  final _historyService = HistoryService();

  List<Appliance> appliances = [];
  bool _isLoading = true;
  bool _groupByLocation = false;

  double _costPerKwh = 0.12;
  String _currencySymbol = '\$';
  double? _monthlyBudget;
  String _budgetType = 'cost';

  final Map<String, List<Appliance>> _groupedAppliancesCache = {};
  List<String> _sortedLocationsCache = [];
  double _totalConsumptionCache = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _storageService.loadAppliances(),
      _settingsService.getCostPerKwh(),
      _settingsService.getCurrencySymbol(),
      _settingsService.getMonthlyBudget(),
      _settingsService.getBudgetType(),
    ]);

    appliances = results[0] as List<Appliance>;
    _costPerKwh = results[1] as double;
    _currencySymbol = results[2] as String;
    _monthlyBudget = results[3] as double?;
    _budgetType = results[4] as String;

    _sortAppliances();
    _recordSnapshot();
    setState(() => _isLoading = false);
  }

  void _sortAppliances() {
    appliances.sort((a, b) => b.dailyConsumption.compareTo(a.dailyConsumption));
    _updateCaches();
  }

  void _updateCaches() {
    _totalConsumptionCache = appliances.fold(
      0,
      (total, appliance) => total + appliance.dailyConsumption,
    );

    _groupedAppliancesCache.clear();
    for (final appliance in appliances) {
      final location = 'Location: ${appliance.location ?? 'Other'}';
      _groupedAppliancesCache.putIfAbsent(location, () => []).add(appliance);
    }

    _sortedLocationsCache = _groupedAppliancesCache.keys.toList()
      ..sort((a, b) {
        final aConsumption = _groupedAppliancesCache[a]!
            .fold(0.0, (sum, item) => sum + item.dailyConsumption);
        final bConsumption = _groupedAppliancesCache[b]!
            .fold(0.0, (sum, item) => sum + item.dailyConsumption);
        return bConsumption.compareTo(aConsumption);
      });
  }

  double get totalDailyConsumption => _totalConsumptionCache;

  Future<void> _recordSnapshot() async {
    if (appliances.isEmpty) return;
    final snapshot = ConsumptionSnapshot(
      date: DateTime.now(),
      totalDailyKwh: totalDailyConsumption,
      totalDailyCost: totalDailyConsumption * _costPerKwh,
      applianceCount: appliances.length,
    );
    await _historyService.recordSnapshot(snapshot);
  }

  Future<void> _navigateToEditScreen(BuildContext context, [Appliance? appliance]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ApplianceEditScreen(appliance: appliance),
      ),
    );

    if (result == true) {
      _loadAll();
    }
  }

  Future<void> _navigateToEditWithTemplate(BuildContext context, ApplianceTemplate template) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ApplianceEditScreen(template: template),
      ),
    );

    if (result == true) {
      _loadAll();
    }
  }

  Future<void> _navigateToBudgetScreen(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const BudgetScreen(),
      ),
    );

    if (result == true) {
      _loadAll();
    }
  }

  Future<void> _deleteAppliance(String id) async {
    setState(() {
      appliances.removeWhere((appliance) => appliance.id == id);
      _updateCaches();
    });
    await _saveAppliances();
    _recordSnapshot();
  }

  Future<void> _saveAppliances() async {
    setState(() => _isLoading = true);
    await _storageService.saveAppliances(appliances);
    setState(() => _isLoading = false);
  }

  void _showAddOptions(BuildContext outerContext) {
    showModalBottomSheet(
      context: outerContext,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add Appliance',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: Icon(Icons.list_alt, color: Theme.of(sheetContext).colorScheme.primary),
              title: const Text('Choose from Templates'),
              subtitle: const Text('Pick from common household appliances'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickTemplateAndAdd();
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Theme.of(sheetContext).colorScheme.secondary),
              title: const Text('Add Custom Appliance'),
              subtitle: const Text('Enter appliance details manually'),
              onTap: () {
                Navigator.pop(sheetContext);
                _navigateToEditScreen(outerContext);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTemplateAndAdd() async {
    final template = await Navigator.push<ApplianceTemplate>(
      context,
      MaterialPageRoute(
        builder: (context) => const TemplatePickerScreen(),
      ),
    );
    if (template != null && mounted) {
      _navigateToEditWithTemplate(context, template);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.electrical_services_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No appliances added yet',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to add your first appliance',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildApplianceList() {
    return ListView.builder(
      itemCount: appliances.length,
      itemBuilder: (context, index) {
        return ApplianceCard(
          appliance: appliances[index],
          costPerKwh: _costPerKwh,
          currencySymbol: _currencySymbol,
          onEdit: () => _navigateToEditScreen(context, appliances[index]),
          onDelete: () => _deleteAppliance(appliances[index].id),
        );
      },
    );
  }

  Widget _buildLocationGroupedList() {
    final groupedAppliances = _groupedAppliancesCache;
    final sortedLocations = _sortedLocationsCache;

    return ListView.builder(
      itemCount: sortedLocations.length,
      itemBuilder: (context, index) {
        final location = sortedLocations[index];
        final locationAppliances = groupedAppliances[location]!;
        final locationConsumption = locationAppliances
            .fold(0.0, (sum, item) => sum + item.dailyConsumption);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${locationConsumption.toStringAsFixed(2)} kWh/day',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...locationAppliances.map((appliance) => ApplianceCard(
                  appliance: appliance,
                  costPerKwh: _costPerKwh,
                  currencySymbol: _currencySymbol,
                  onEdit: () => _navigateToEditScreen(context, appliance),
                  onDelete: () => _deleteAppliance(appliance.id),
                  showLocation: false,
                )),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.electric_bolt, size: 28),
        title: const Text('WattWise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.savings_outlined),
            onPressed: () => _navigateToBudgetScreen(context),
            tooltip: 'Budget',
          ),
          IconButton(
            icon: Icon(_groupByLocation ? Icons.view_list : Icons.view_module),
            onPressed: () {
              setState(() {
                _groupByLocation = !_groupByLocation;
              });
            },
            tooltip: _groupByLocation ? 'List View' : 'Group by Location',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (appliances.isNotEmpty) ...[
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Card(
                            elevation: 4,
                            color: Theme.of(context).colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bolt,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Total Consumption',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ConsumptionSummary(
                                    dailyConsumption: totalDailyConsumption,
                                    applianceCount: appliances.length,
                                    costPerKwh: _costPerKwh,
                                    currencySymbol: _currencySymbol,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${appliances.length} Appliances',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  BudgetProgress(
                    currentMonthlyConsumption: totalDailyConsumption * 30,
                    costPerKwh: _costPerKwh,
                    currencySymbol: _currencySymbol,
                    monthlyBudget: _monthlyBudget,
                    budgetType: _budgetType,
                  ),
                ],
                Expanded(
                  child: appliances.isEmpty
                      ? _buildEmptyState()
                      : _groupByLocation
                          ? _buildLocationGroupedList()
                          : _buildApplianceList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
