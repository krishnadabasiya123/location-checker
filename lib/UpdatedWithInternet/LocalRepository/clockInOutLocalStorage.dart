import 'package:hive_flutter/hive_flutter.dart';
import 'package:location_checker/Widget/internetConnectivity.dart';

class LocalRepository {
  /// Get ALL session entries (for all dates) from 'clokINOutData'
  Future<Map<dynamic, dynamic>> getAllClockInOutData() async {
    final box = Hive.box('clokINOutData');
    final data = box.toMap();
    print("clock in out : $data");
    return Map<dynamic, dynamic>.from(data);
  }

  /// Get ALL coordinate records (for all dates) from 'locationdata'
  Future<Map<dynamic, dynamic>> getAllLocationData() async {
    final box = Hive.box('locationdata');
    final data = box.toMap();
    return Map<dynamic, dynamic>.from(data);
  }

  Future<bool> getClockInStatus() async {
    final Map<dynamic, dynamic> allClockInOutData =
        await getAllClockInOutData();

    bool isClockedIn = false;

    if (allClockInOutData.isNotEmpty) {
      final firstKeyEntry = allClockInOutData.keys.first;

      final List<dynamic> entries = List<dynamic>.from(
        allClockInOutData[firstKeyEntry] ?? [],
      );

      if (entries.isNotEmpty) {
        final lastEntry = Map<String, dynamic>.from(entries.last);

        isClockedIn = lastEntry["type"] == "in";
      }
    }

    return isClockedIn;
  }

  // Future<void> saveClockInOut({
  //   required String date,
  //   required Map<String, dynamic> entry,
  // }) async {
  //   final box = await Hive.openBox('clokINOutData');

  //   final List<dynamic> todayEntries = List<dynamic>.from(box.get(date) ?? []);

  //   todayEntries.add(entry);

  //   await box.put(date, todayEntries);

  //   await box.close();
  // }
  // Future<void> saveClockInOut({
  //   required String date,
  //   required Map<String, dynamic> entry,
  // }) async {
  //   try {
  //     final bool hasInternet = await InternetConnectivity.checkInternet();
  //     print("hasInternet $hasInternet");

  //     bool apiSuccess = false;

  //     if (hasInternet) {

  //       apiSuccess = true;
  //     }
  //     if (!hasInternet || !apiSuccess) {
  //       final box = await Hive.openBox('clokINOutData');

  // final List<dynamic> todayEntries = List<dynamic>.from(
  //   box.get(date) ?? [],
  // );
  // todayEntries.add(entry);
  // await box.put(date, todayEntries);
  //       await box.close();
  //       print("Stored In Hive Successfully");
  //     }
  //   } catch (e) {
  //     print("Save Error $e");
  //   }
  // }

  Future<void> saveClockInOut({
    required String date,
    required Map<String, dynamic> entry,
  }) async {
    try {
      final bool hasInternet = await InternetConnectivity.checkInternet();
      print("hasInternet $hasInternet");

      bool apiSuccess = false;

      if (entry["type"] == "in") {
        // call clock in API
        try {
          if (hasInternet) {
            // Simulate successful API call when online
            apiSuccess = true;
            print("🟢 Clock In API Successful (Online Mode): $entry");
          } else {
            // Force save to Hive when offline by throwing an exception
            throw Exception("No internet connection");
          }
        } catch (e) {
          apiSuccess = false;
          final box = Hive.box('clokINOutData');
          final List<dynamic> todayEntries = List<dynamic>.from(
            box.get(date) ?? [],
          );
          todayEntries.add(entry);
          await box.put(date, todayEntries);
          print("Saved Clock In offline to Hive: $entry due to: $e");
        }
      } else {
        // call clock out API
        try {
          if (hasInternet) {
            apiSuccess = true;
            print("🟢 Clock Out API Successful (Online Mode): $entry");
          } else {
            // Force save to Hive when offline by throwing an exception
            throw Exception("No internet connection");
          }
          // api call sucess
        } catch (e) {
          apiSuccess = false;
          final box = Hive.box('clokINOutData');
          final List<dynamic> todayEntries = List<dynamic>.from(
            box.get(date) ?? [],
          );
          todayEntries.add(entry);
          await box.put(date, todayEntries);
          print("Saved Clock Out offline to Hive: $entry due to: $e");
        }
      }
    } catch (e) {
      print("Save Error $e");
    }
  }

  // sync to serve data (500 batch data pass 500 data)
}
