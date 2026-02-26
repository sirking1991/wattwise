import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _costPerKwhKey = 'cost_per_kwh';
  static const String _currencySymbolKey = 'currency_symbol';
  static const String _monthlyBudgetKey = 'monthly_budget';
  static const String _budgetTypeKey = 'budget_type';
  static const String _voltageKey = 'voltage';

  Future<double> getCostPerKwh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_costPerKwhKey) ?? 0.12;
  }

  Future<void> setCostPerKwh(double cost) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_costPerKwhKey, cost);
  }

  Future<String> getCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencySymbolKey) ?? '\$';
  }

  Future<void> setCurrencySymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencySymbolKey, symbol);
  }

  Future<double?> getMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_monthlyBudgetKey);
  }

  Future<void> setMonthlyBudget(double? budget) async {
    final prefs = await SharedPreferences.getInstance();
    if (budget == null) {
      await prefs.remove(_monthlyBudgetKey);
    } else {
      await prefs.setDouble(_monthlyBudgetKey, budget);
    }
  }

  /// 'cost' or 'kwh'
  Future<String> getBudgetType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_budgetTypeKey) ?? 'cost';
  }

  Future<void> setBudgetType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_budgetTypeKey, type);
  }

  Future<double> getVoltage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_voltageKey) ?? 230.0;
  }

  Future<void> setVoltage(double voltage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_voltageKey, voltage);
  }
}
