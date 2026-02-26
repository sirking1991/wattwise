import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watt_wise/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onExportTap;

  const SettingsScreen({super.key, this.onExportTap});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();

  final _costController = TextEditingController();
  final _currencyController = TextEditingController();
  final _voltageController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cost = await _settingsService.getCostPerKwh();
    final currency = await _settingsService.getCurrencySymbol();
    final voltage = await _settingsService.getVoltage();

    _costController.text = cost.toString();
    _currencyController.text = currency;
    _voltageController.text = voltage.toString();

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _costController.dispose();
    _currencyController.dispose();
    _voltageController.dispose();
    super.dispose();
  }

  Future<void> _saveCost(String value) async {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed >= 0) {
      await _settingsService.setCostPerKwh(parsed);
    }
  }

  Future<void> _saveCurrency(String value) async {
    if (value.isNotEmpty) {
      await _settingsService.setCurrencySymbol(value);
    }
  }

  Future<void> _saveVoltage(String value) async {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed > 0) {
      await _settingsService.setVoltage(parsed);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildHelperText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildSectionHeader('Electricity Rate'),

                TextFormField(
                  controller: _costController,
                  decoration: const InputDecoration(
                    labelText: 'Cost per kWh',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*')),
                  ],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Cost cannot be empty';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null) {
                      return 'Enter a valid number';
                    }
                    if (parsed < 0) {
                      return 'Cost cannot be negative';
                    }
                    return null;
                  },
                  onChanged: _saveCost,
                ),
                _buildHelperText(
                  'The price you pay per kilowatt-hour. Check your electricity bill for this value.',
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _currencyController,
                  decoration: const InputDecoration(
                    labelText: 'Currency Symbol',
                    prefixIcon: Icon(Icons.currency_exchange),
                    border: OutlineInputBorder(),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Currency symbol cannot be empty';
                    }
                    return null;
                  },
                  onChanged: _saveCurrency,
                ),
                _buildHelperText(
                  'Symbol used when displaying costs (e.g. \$, €, £).',
                ),

                _buildSectionHeader('Conversion'),

                TextFormField(
                  controller: _voltageController,
                  decoration: const InputDecoration(
                    labelText: 'Voltage (V)',
                    prefixIcon: Icon(Icons.electrical_services),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*')),
                  ],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Voltage cannot be empty';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null) {
                      return 'Enter a valid number';
                    }
                    if (parsed <= 0) {
                      return 'Voltage must be greater than zero';
                    }
                    return null;
                  },
                  onChanged: _saveVoltage,
                ),
                _buildHelperText(
                  'Assumed mains voltage for converting amps to watts. Typically 230V (EU/Asia) or 120V (US).',
                ),

                if (widget.onExportTap != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.download, color: colorScheme.primary),
                    title: const Text('Export Data'),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onTap: widget.onExportTap,
                  ),
                ],

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.electric_bolt,
                        size: 32,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'WattWise',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
