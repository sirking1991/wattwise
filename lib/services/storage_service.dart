import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appliance.dart';

class StorageService {
  static const String _appliancesKey = 'appliances';

  Future<List<Appliance>> loadAppliances() async {
    final prefs = await SharedPreferences.getInstance();
    final appliancesJson = prefs.getStringList(_appliancesKey) ?? [];
    
    return appliancesJson
        .map((json) => Appliance.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveAppliances(List<Appliance> appliances) async {
    final prefs = await SharedPreferences.getInstance();
    final appliancesJson = appliances
        .map((appliance) => jsonEncode(appliance.toJson()))
        .toList();
    await prefs.setStringList(_appliancesKey, appliancesJson);
  }
}
