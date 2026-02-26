import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watt_wise/models/appliance_template.dart';

class TemplatePickerScreen extends StatefulWidget {
  const TemplatePickerScreen({super.key});

  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends State<TemplatePickerScreen> {
  List<ApplianceTemplate> _templates = [];
  String _searchQuery = '';
  bool _isLoading = true;

  static const Map<String, IconData> _iconMap = {
    'kitchen': Icons.kitchen,
    'tv': Icons.tv,
    'ac_unit': Icons.ac_unit,
    'thermostat': Icons.thermostat,
    'computer': Icons.computer,
    'laptop': Icons.laptop,
    'monitor': Icons.monitor,
    'lightbulb': Icons.lightbulb,
    'bed': Icons.bed,
    'shower': Icons.shower,
    'water_drop': Icons.water_drop,
    'air': Icons.air,
    'router': Icons.router,
    'print': Icons.print,
    'phone_android': Icons.phone_android,
    'alarm': Icons.alarm,
    'security': Icons.security,
    'iron': Icons.iron,
    'local_laundry_service': Icons.local_laundry_service,
    'coffee': Icons.coffee,
    'blender': Icons.blender,
    'speaker': Icons.speaker,
    'gamepad': Icons.gamepad,
    'pool': Icons.pool,
    'garage': Icons.garage,
    'microwave': Icons.microwave,
  };

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final jsonString =
        await rootBundle.loadString('assets/appliance_templates.json');
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    setState(() {
      _templates = jsonList
          .map((e) => ApplianceTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
      _isLoading = false;
    });
  }

  List<ApplianceTemplate> get _filteredTemplates {
    if (_searchQuery.isEmpty) return _templates;
    final query = _searchQuery.toLowerCase();
    return _templates
        .where((t) => t.name.toLowerCase().contains(query))
        .toList();
  }

  Map<String, List<ApplianceTemplate>> get _groupedTemplates {
    final map = <String, List<ApplianceTemplate>>{};
    for (final template in _filteredTemplates) {
      map.putIfAbsent(template.category, () => []).add(template);
    }
    return map;
  }

  IconData _iconForTemplate(ApplianceTemplate template) {
    return _iconMap[template.icon] ?? Icons.electrical_services;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Appliance')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search appliances...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                Expanded(
                  child: _buildGroupedList(colorScheme),
                ),
              ],
            ),
    );
  }

  Widget _buildGroupedList(ColorScheme colorScheme) {
    final grouped = _groupedTemplates;
    if (grouped.isEmpty) {
      return const Center(child: Text('No appliances found.'));
    }

    final categories = grouped.keys.toList()..sort();

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final templates = grouped[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                category,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ),
            ...templates.map((template) => ListTile(
                  leading: Icon(
                    _iconForTemplate(template),
                    color: colorScheme.primary,
                  ),
                  title: Text(template.name),
                  subtitle: Text(
                    '${template.typicalWattage.toStringAsFixed(0)}W · '
                    '${template.typicalHoursPerDay % 1 == 0 ? template.typicalHoursPerDay.toStringAsFixed(0) : template.typicalHoursPerDay.toString()} hrs/day typical',
                  ),
                  onTap: () => Navigator.pop(context, template),
                )),
          ],
        );
      },
    );
  }
}
