import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appliance.dart';
import 'auth_service.dart';

class StorageService {
  static const String _appliancesKey = 'appliances';
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StorageService({AuthService? authService})
      : _authService = authService ?? AuthService();

  Future<List<Appliance>> loadAppliances() async {
    final user = _authService.currentUser;
    
    if (user != null) {
      return await _loadFromCloud(user.uid);
    } else {
      return await _loadFromLocal();
    }
  }

  Future<void> saveAppliances(List<Appliance> appliances) async {
    final user = _authService.currentUser;
    
    if (user != null) {
      await _saveToCloud(user.uid, appliances);
    }
    
    await _saveToLocal(appliances);
  }

  Future<List<Appliance>> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final appliancesJson = prefs.getStringList(_appliancesKey) ?? [];
    
    return appliancesJson
        .map((json) => Appliance.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> _saveToLocal(List<Appliance> appliances) async {
    final prefs = await SharedPreferences.getInstance();
    final appliancesJson = appliances
        .map((appliance) => jsonEncode(appliance.toJson()))
        .toList();
    await prefs.setStringList(_appliancesKey, appliancesJson);
  }

  Future<List<Appliance>> _loadFromCloud(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('appliances')
          .get();

      return snapshot.docs
          .map((doc) => Appliance.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return await _loadFromLocal();
    }
  }

  Future<void> _saveToCloud(String userId, List<Appliance> appliances) async {
    try {
      final batch = _firestore.batch();
      final appliancesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('appliances');

      final existingDocs = await appliancesRef.get();
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      for (var appliance in appliances) {
        final docRef = appliancesRef.doc(appliance.id);
        batch.set(docRef, appliance.toJson());
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncLocalToCloud() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final localAppliances = await _loadFromLocal();
    await _saveToCloud(user.uid, localAppliances);
  }
}
