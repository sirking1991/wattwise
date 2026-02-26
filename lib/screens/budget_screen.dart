import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _settingsService = SettingsService();
  final _budgetController = TextEditingController();

  String _budgetType = 'cost';
  String _currencySymbol = '\$';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final budget = await _settingsService.getMonthlyBudget();
    final budgetType = await _settingsService.getBudgetType();
    final currencySymbol = await _settingsService.getCurrencySymbol();

    setState(() {
      _budgetType = budgetType;
      _currencySymbol = currencySymbol;
      if (budget != null) {
        _budgetController.text = budget.toStringAsFixed(2);
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  String get _unitSuffix => _budgetType == 'cost' ? _currencySymbol : 'kWh';

  String get _previewText {
    final value = double.tryParse(_budgetController.text);
    if (value == null) return '';
    if (_budgetType == 'cost') {
      return 'Your budget: $_currencySymbol${value.toStringAsFixed(2)}/month';
    }
    return 'Your budget: ${value.toStringAsFixed(2)} kWh/month';
  }

  Future<void> _saveBudget() async {
    final value = double.tryParse(_budgetController.text);
    if (value == null) return;

    await _settingsService.setMonthlyBudget(value);
    await _settingsService.setBudgetType(_budgetType);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _clearBudget() async {
    await _settingsService.setMonthlyBudget(null);
    setState(() {
      _budgetController.clear();
    });

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Monthly Budget')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budget'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Set a monthly limit to track your spending against',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withAlpha(179),
                ),
          ),
          const SizedBox(height: 24),

          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'cost',
                label: Text('Cost'),
                icon: Icon(Icons.attach_money),
              ),
              ButtonSegment<String>(
                value: 'kwh',
                label: Text('Energy (kWh)'),
                icon: Icon(Icons.bolt),
              ),
            ],
            selected: {_budgetType},
            onSelectionChanged: (Set<String> selected) {
              setState(() {
                _budgetType = selected.first;
              });
            },
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _budgetController,
            decoration: InputDecoration(
              labelText: 'Budget Amount',
              hintText: 'Enter your monthly budget',
              border: const OutlineInputBorder(),
              suffixText: _unitSuffix,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          if (_previewText.isNotEmpty)
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _previewText,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: _clearBudget,
              child: Text(
                'Clear Budget',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          ),
        ],
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
                onPressed: double.tryParse(_budgetController.text) != null
                    ? _saveBudget
                    : null,
                child: const Text('SAVE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
