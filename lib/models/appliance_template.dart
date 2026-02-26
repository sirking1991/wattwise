class ApplianceTemplate {
  final String name;
  final double typicalWattage;
  final String category;
  final String icon;
  final double typicalHoursPerDay;

  const ApplianceTemplate({
    required this.name,
    required this.typicalWattage,
    required this.category,
    required this.icon,
    required this.typicalHoursPerDay,
  });

  factory ApplianceTemplate.fromJson(Map<String, dynamic> json) {
    return ApplianceTemplate(
      name: json['name'] as String,
      typicalWattage: (json['typicalWattage'] as num).toDouble(),
      category: json['category'] as String,
      icon: json['icon'] as String,
      typicalHoursPerDay: (json['typicalHoursPerDay'] as num).toDouble(),
    );
  }
}
