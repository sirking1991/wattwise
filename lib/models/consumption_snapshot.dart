class ConsumptionSnapshot {
  final DateTime date;
  final double totalDailyKwh;
  final double totalDailyCost;
  final int applianceCount;

  const ConsumptionSnapshot({
    required this.date,
    required this.totalDailyKwh,
    required this.totalDailyCost,
    required this.applianceCount,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'totalDailyKwh': totalDailyKwh,
        'totalDailyCost': totalDailyCost,
        'applianceCount': applianceCount,
      };

  factory ConsumptionSnapshot.fromJson(Map<String, dynamic> json) {
    return ConsumptionSnapshot(
      date: DateTime.parse(json['date'] as String),
      totalDailyKwh: (json['totalDailyKwh'] as num).toDouble(),
      totalDailyCost: (json['totalDailyCost'] as num).toDouble(),
      applianceCount: (json['applianceCount'] as num).toInt(),
    );
  }
}
