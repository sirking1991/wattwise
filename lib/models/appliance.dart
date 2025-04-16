
class Appliance {
  final String id;
  String name;
  double powerRating;
  bool isWatts; // true for watts, false for amps
  double hoursPerDay;
  String? brand;
  String? location;

  Appliance({
    required this.id,
    required this.name,
    required this.powerRating,
    required this.isWatts,
    required this.hoursPerDay,
    this.brand,
    this.location,
  });

  // Calculate daily energy consumption in kWh
  double get dailyConsumption {
    // Convert amps to watts if needed (assuming 230V)
    final watts = isWatts ? powerRating : powerRating * 230;
    // Calculate kWh
    return (watts * hoursPerDay) / 1000;
  }

  // Convert to and from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'powerRating': powerRating,
      'isWatts': isWatts,
      'hoursPerDay': hoursPerDay,
      'brand': brand,
      'location': location,
    };
  }

  factory Appliance.fromJson(Map<String, dynamic> json) {
    return Appliance(
      id: json['id'],
      name: json['name'],
      powerRating: json['powerRating'],
      isWatts: json['isWatts'],
      hoursPerDay: json['hoursPerDay'],
      brand: json['brand'],
      location: json['location'],
    );
  }
}
