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
}
