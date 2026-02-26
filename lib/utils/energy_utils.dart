class EnergyUtils {
  static const double voltageAssumption = 230.0;

  static double wattsToKwh(double watts, double hours) {
    return (watts * hours) / 1000;
  }

  static double ampsToWatts(double amps) {
    return amps * voltageAssumption;
  }

  static double calculateMonthlyConsumption(double dailyConsumption) {
    return dailyConsumption * 30;
  }

  static double kwhToCost(double kwh, double costPerKwh) {
    return kwh * costPerKwh;
  }

  static double dailyCostToMonthly(double dailyCost) {
    return dailyCost * 30;
  }

  static String formatCost(double cost, String currencySymbol) {
    return '$currencySymbol${cost.toStringAsFixed(2)}';
  }

  static String formatKwh(double kwh) {
    return '${kwh.toStringAsFixed(2)} kWh';
  }
}
