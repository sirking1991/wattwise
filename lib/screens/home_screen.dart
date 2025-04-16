import 'package:flutter/material.dart';
import '../models/appliance.dart';
import '../services/storage_service.dart';
import '../widgets/appliance_card.dart';
import 'appliance_edit_screen.dart';
import '../widgets/consumption_summary.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storageService = StorageService();
  List<Appliance> appliances = [];
  bool _isLoading = true;
  bool _groupByLocation = false;
  
  // Cache for grouped appliances
  final Map<String, List<Appliance>> _groupedAppliancesCache = {};
  List<String> _sortedLocationsCache = [];
  double _totalConsumptionCache = 0;

  @override
  void initState() {
    super.initState();
    _loadAppliances();
  }

  Future<void> _loadAppliances() async {
    setState(() => _isLoading = true);
    appliances = await _storageService.loadAppliances();
    _sortAppliances();
    setState(() => _isLoading = false);
  }

  void _sortAppliances() {
    appliances.sort((a, b) => b.dailyConsumption.compareTo(a.dailyConsumption));
    _updateCaches();
  }

  void _updateCaches() {
    // Update total consumption cache
    _totalConsumptionCache = appliances.fold(
      0,
      (total, appliance) => total + appliance.dailyConsumption,
    );

    // Update grouped appliances cache
    _groupedAppliancesCache.clear();
    for (final appliance in appliances) {
      final location = 'Location: ${appliance.location ?? 'Other'}';
      _groupedAppliancesCache.putIfAbsent(location, () => []).add(appliance);
    }

    // Update sorted locations cache
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

  Future<void> _navigateToEditScreen(BuildContext context, [Appliance? appliance]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ApplianceEditScreen(appliance: appliance),
      ),
    );

    if (result == true) {
      _loadAppliances();
    }
  }

  Future<void> _deleteAppliance(String id) async {
    setState(() {
      appliances.removeWhere((appliance) => appliance.id == id);
      _updateCaches(); // Update caches after modifying appliances
    });
    await _saveAppliances();
  }

  Future<void> _saveAppliances() async {
    setState(() => _isLoading = true);
    await _storageService.saveAppliances(appliances);
    setState(() => _isLoading = false);
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
          onEdit: () => _navigateToEditScreen(context, appliances[index]),
          onDelete: () => _deleteAppliance(appliances[index].id),
        );
      },
    );
  }

  Widget _buildLocationGroupedList() {
    // Use cached values instead of recalculating
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
        onPressed: () => _navigateToEditScreen(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
