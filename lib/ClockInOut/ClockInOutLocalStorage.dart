import 'package:hive_flutter/hive_flutter.dart';

class ClockInOutLocalStorage {
  /// Get ALL session entries (for all dates) from 'clokINOutData'
  Future<Map<dynamic, dynamic>> getAllClockInOutData() async {
    final box = await Hive.openBox('clokINOutData');
    final data = box.toMap();
    return Map<dynamic, dynamic>.from(data);
  }

  /// Get ALL coordinate records (for all dates) from 'locationdata'
  Future<Map<dynamic, dynamic>> getAllLocationData() async {
    final box = await Hive.openBox('locationdata');
    final data = box.toMap();
    return Map<dynamic, dynamic>.from(data);
  }
}
