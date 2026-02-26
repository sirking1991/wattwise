import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/consumption_snapshot.dart';

class HistoryService {
  static const String _snapshotsKey = 'consumption_snapshots';

  Future<List<ConsumptionSnapshot>> getSnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_snapshotsKey) ?? [];
    return jsonList
        .map((s) => ConsumptionSnapshot.fromJson(jsonDecode(s)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<ConsumptionSnapshot>> getRecentSnapshots(int days) async {
    final all = await getSnapshots();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return all.where((s) => s.date.isAfter(cutoff)).toList();
  }

  Future<void> recordSnapshot(ConsumptionSnapshot snapshot) async {
    final snapshots = await getSnapshots();

    final todayKey = _dateKey(snapshot.date);
    snapshots.removeWhere((s) => _dateKey(s.date) == todayKey);
    snapshots.add(snapshot);

    // Keep at most 365 days of history
    if (snapshots.length > 365) {
      snapshots.sort((a, b) => a.date.compareTo(b.date));
      snapshots.removeRange(0, snapshots.length - 365);
    }

    await _saveSnapshots(snapshots);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snapshotsKey);
  }

  Future<void> _saveSnapshots(List<ConsumptionSnapshot> snapshots) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = snapshots.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_snapshotsKey, jsonList);
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
