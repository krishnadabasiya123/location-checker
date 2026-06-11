import 'package:hive_flutter/adapters.dart';
import 'package:location_checker/ClockInOut/dummyData.dart';
import 'package:location_checker/UpdatedWithInternet/LocalRepository/system_local_repository.dart';

class HiveUtils {
  Future<void> openBox() async {
    await Hive.openBox("clokINOutData");
    await Hive.openBox("locationdata");
    await Hive.openBox<dynamic>("authStatus");

    // Automatically seeding is disabled so mock data is not added on startup
    /*
    if (clockBox.isEmpty && locBox.isEmpty) {
      print("Seeding large mock datasets automatically on app startup...");
      
      // 1. Seed largeSessionData
      for (final dateKey in largeSessionData.keys) {
        await clockBox.put(dateKey, largeSessionData[dateKey]);
      }

      // 2. Seed getLargeLocationData()
      final largeLocData = getLargeLocationData();
      for (final dateKey in largeLocData.keys) {
        await locBox.put(dateKey, largeLocData[dateKey]);
      }
      
      print("Successfully seeded large datasets on startup.");
    }
    */
  }
}
