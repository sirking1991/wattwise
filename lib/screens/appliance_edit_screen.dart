import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/appliance.dart';
import '../models/appliance_template.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';

class ApplianceEditScreen extends StatefulWidget {
  final Appliance? appliance;
  final ApplianceTemplate? template;

  const ApplianceEditScreen({super.key, this.appliance, this.template});

  @override
  State<ApplianceEditScreen> createState() => _ApplianceEditScreenState();
}

class _ApplianceEditScreenState extends State<ApplianceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = StorageService();
  final _settingsService = SettingsService();
  final _nameController = TextEditingController();
  final _powerRatingController = TextEditingController();
  final _hoursPerDayController = TextEditingController();
  final _brandController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isWatts = true;
  Set<String> _locationSuggestions = {};
  double _costPerKwh = 0.12;
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    _costPerKwh = await _settingsService.getCostPerKwh();
    _currencySymbol = await _settingsService.getCurrencySymbol();

    if (widget.appliance != null) {
      _nameController.text = widget.appliance!.name;
      _powerRatingController.text = widget.appliance!.powerRating.toString();
      _hoursPerDayController.text = widget.appliance!.hoursPerDay.toString();
      _brandController.text = widget.appliance!.brand ?? '';
      _locationController.text = widget.appliance?.location ?? '';
      _isWatts = widget.appliance!.isWatts;
    } else if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _powerRatingController.text = widget.template!.typicalWattage.toString();
      _hoursPerDayController.text = widget.template!.typicalHoursPerDay.toString();
      _isWatts = true;
      _locationController.text = widget.template!.category;
    }

    final appliances = await _storageService.loadAppliances();
    setState(() {
      _locationSuggestions = appliances
          .where((a) => a.location != null)
          .map((a) => a.location!)
          .toSet();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _powerRatingController.dispose();
    _hoursPerDayController.dispose();
    _brandController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveAppliance() async {
    if (!_formKey.currentState!.validate()) return;

    final appliances = await _storageService.loadAppliances();
    final newAppliance = Appliance(
      id: widget.appliance?.id ?? DateTime.now().toIso8601String(),
      name: _nameController.text,
      powerRating: double.parse(_powerRatingController.text),
      isWatts: _isWatts,
      hoursPerDay: double.parse(_hoursPerDayController.text),
      brand: _brandController.text.isEmpty ? null : _brandController.text,
      location: _locationController.text.isEmpty ? null : _locationController.text,
    );

    if (widget.appliance != null) {
      final index = appliances.indexWhere((a) => a.id == widget.appliance!.id);
      appliances[index] = newAppliance;
    } else {
      appliances.add(newAppliance);
    }

    await _storageService.saveAppliances(appliances);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteAppliance() async {
    if (widget.appliance == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appliance'),
        content: const Text('Are you sure you want to delete this appliance?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final appliances = await _storageService.loadAppliances();
    appliances.removeWhere((a) => a.id == widget.appliance!.id);
    await _storageService.saveAppliances(appliances);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  double _calculateDailyConsumption() {
    final powerRating = double.tryParse(_powerRatingController.text) ?? 0;
    final hoursPerDay = double.tryParse(_hoursPerDayController.text) ?? 0;
    final watts = _isWatts ? powerRating : powerRating * 230;
    return (watts * hoursPerDay) / 1000;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.appliance != null;
    final isFromTemplate = widget.template != null;
    String title = 'Add Appliance';
    if (isEditing) {
      title = 'Edit Appliance';
    } else if (isFromTemplate) {
      title = 'Add ${widget.template!.name}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteAppliance,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Appliance Name',
                hintText: 'e.g., Refrigerator',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an appliance name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _powerRatingController,
                    decoration: const InputDecoration(
                      labelText: 'Power Rating',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter power rating';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Watts'),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Amps'),
                      ),
                    ],
                    selected: {_isWatts},
                    onSelectionChanged: (Set<bool> selected) {
                      setState(() {
                        _isWatts = selected.first;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return Theme.of(context).colorScheme.secondaryContainer;
                          }
                          return Colors.transparent;
                        },
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return Theme.of(context).colorScheme.onSecondaryContainer;
                          }
                          return Theme.of(context).colorScheme.onSurface;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isWatts
                  ? 'Power in watts (W)'
                  : 'Power in amps (A) - Will be converted to watts using 230V',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _hoursPerDayController,
              decoration: const InputDecoration(
                labelText: 'Hours Used Per Day',
                hintText: 'e.g., 8',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter hours per day';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                final hours = double.parse(value);
                if (hours > 24) {
                  return 'Hours per day cannot exceed 24';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Brand (optional)',
                hintText: 'e.g., Samsung',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _locationSuggestions.where((location) {
                  return location.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  );
                });
              },
              onSelected: (String selection) {
                _locationController.text = selection;
                setState(() {});
              },
              fieldViewBuilder: (
                BuildContext context,
                TextEditingController controller,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted,
              ) {
                return TextFormField(
                  controller: _locationController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    hintText: 'e.g., Kitchen',
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (String value) {
                    onFieldSubmitted();
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            if (_powerRatingController.text.isNotEmpty &&
                _hoursPerDayController.text.isNotEmpty &&
                double.tryParse(_powerRatingController.text) != null &&
                double.tryParse(_hoursPerDayController.text) != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Daily Consumption Estimate',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_calculateDailyConsumption().toStringAsFixed(2)} kWh',
                        style: TextStyle(
                          fontSize: 24,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_costPerKwh > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$_currencySymbol${(_calculateDailyConsumption() * _costPerKwh).toStringAsFixed(2)}/day  ·  $_currencySymbol${(_calculateDailyConsumption() * _costPerKwh * 30).toStringAsFixed(2)}/month',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _saveAppliance,
                child: const Text('SAVE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
