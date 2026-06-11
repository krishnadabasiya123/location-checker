import 'dart:async';
import 'dart:isolate'; // Required for Isolate filtering
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location_checker/UpdatedWithInternet/Model/location_point.dart';
import 'package:location_checker/Widget/internetConnectivity.dart';

class LocationRepository {
  static final String locationboxName = 'locationdata';
  // Mock API success flag for testing
  static bool mockLocationSyncSuccess = true;

  // Static set to keep track of dates currently undergoing synchronization
  static final Set<String> _syncingDates = {};

  Box get _box => Hive.box(locationboxName);

  Future<void> saveLocal(LocationPoint point) async {
    final stopwatch = Stopwatch()..start();
    if (!Hive.isBoxOpen(locationboxName)) {
      await Hive.openBox(locationboxName);
    }
    final box = _box;
    final Map<dynamic, dynamic> todayData = Map<dynamic, dynamic>.from(
      box.get(point.date) ?? {},
    );

    final List<dynamic> locationList = List<dynamic>.from(
      todayData['location'] ?? [],
    );

    final newLocEntry = {
      "date": point.date,
      "time": point.timestamp.millisecondsSinceEpoch,
      "lat": point.latitude,
      "long": point.longitude,
    };

    locationList.add(newLocEntry);
    todayData['location'] = locationList;

    await box.put(point.date, todayData);
    stopwatch.stop();
    print(
      "⏱️ [LocationRepository] Storing location to Hive took: ${stopwatch.elapsedMilliseconds} ms (${stopwatch.elapsedMicroseconds} μs)",
    );
  }

  int getCount() {
    if (!Hive.isBoxOpen(locationboxName)) return 0;
    final todayStr = DateFormat("dd-MM-yyyy").format(DateTime.now());
    final box = _box;
    final todayData = box.get(todayStr);
    if (todayData is Map && todayData['location'] is List) {
      return (todayData['location'] as List).length;
    }
    return 0;
  }

  /// Syncs location data for a specific [date] from the Hive box 'locationdata' to the server.
  /// If [upToTimestamp] is provided, only coordinates logged before or at that timestamp are synced,
  /// and subsequent coordinates are retained in the local database.
  ///
  /// This method automatically loads the data from Hive, filters it in a background thread,
  /// uploads in chunks of 2 by default (configured for testing), and updates/saves the remaining coordinates back to Hive.
  Future<Map<String, dynamic>> syncLocationsToServer({
    required String date,
    int? upToTimestamp,
    int chunkSize = 500,
  }) async {
    final locBox = await Hive.openBox('locationdata');
    final locBoxData = locBox.get(date);

    if (locBoxData == null ||
        locBoxData is! Map ||
        locBoxData['location'] == null) {
      return {'success': true, 'failed': []};
    }

    final List<dynamic> allLocations = List<dynamic>.from(
      locBoxData['location'],
    );

    // --- BACKGROUND ISOLATE WORK START ---
    // Move the filtering of potentially thousands of locations to a separate thread to keep UI smooth
    final filterResult = await Isolate.run(() {
      return _filterLocations(allLocations, upToTimestamp);
    });

    final List<dynamic> coordinatesToSync = filterResult['toSync']!;
    final List<dynamic> coordinatesToKeep = filterResult['toKeep']!;
    // --- BACKGROUND ISOLATE WORK END ---

    if (coordinatesToSync.isEmpty) {
      print("ℹ️ [Sync] No locations to sync for date: $date");
      return {'success': true, 'failed': []};
    }

    print(
      "☁️ [Sync] Starting location sync for date: $date. Total coordinates to sync: ${coordinatesToSync.length}",
    );

    // Upload in chunks
    bool isSyncSuccess = true;
    final List<dynamic> failedCoordinates = [];

    for (int i = 0; i < coordinatesToSync.length; i += chunkSize) {
      int end = (i + chunkSize < coordinatesToSync.length)
          ? i + chunkSize
          : coordinatesToSync.length;

      final chunk = coordinatesToSync.sublist(i, end);

      final hasInternet = await InternetConnectivity.checkInternet();
      if (!isSyncSuccess || !hasInternet) {
        isSyncSuccess = false;
        failedCoordinates.addAll(coordinatesToSync.sublist(i));
        print(
          "⚠️ [Sync] Internet LOST! Failed chunk that could not be sent: $chunk",
        );
        print(
          "⚠️ [Sync] Remaining coordinates left unsynced: ${failedCoordinates.length}",
        );
        break;
      }

      print(
        "📤 [Sync] Uploading batch ${i ~/ chunkSize + 1} (${chunk.length} items)...",
      );
      final success = await _uploadLocationChunkApi(
        chunk,
        remainingCount: coordinatesToSync.length - i,
      );
      if (!success) {
        isSyncSuccess = false;
        failedCoordinates.addAll(coordinatesToSync.sublist(i));
        print("❌ [Sync] API upload failed for chunk: $chunk");
        print(
          "❌ [Sync] Remaining coordinates left unsynced: ${failedCoordinates.length}",
        );
        break;
      }
    }

    // Update Hive Box with failed and kept coordinates
    final updatedLocs = [...failedCoordinates, ...coordinatesToKeep];
    if (updatedLocs.isEmpty) {
      await locBox.delete(date);
      print(
        "🎉 [Sync] SUCCESS! All coordinates successfully synced to server for date: $date!",
      );
    } else {
      await locBox.put(date, {'location': updatedLocs});
      print(
        "💾 [Sync] Halted! Saved ${updatedLocs.length} coordinates back to Hive for date: $date (${failedCoordinates.length} failed to sync, ${coordinatesToKeep.length} kept for next session).",
      );
    }

    return {'success': isSyncSuccess, 'failed': failedCoordinates};
  }

  /// Background helper for filtering locations running inside Isolate
  static Map<String, List<dynamic>> _filterLocations(
    List<dynamic> locations,
    int? upToTimestamp,
  ) {
    final List<dynamic> sync = [];
    final List<dynamic> keep = [];

    for (var loc in locations) {
      if (loc is Map) {
        final dynamic timeVal = loc['time'];
        int? locTime;

        if (timeVal is int) {
          locTime = timeVal;
        } else if (timeVal is String) {
          locTime =
              int.tryParse(timeVal) ??
              DateTime.tryParse(timeVal)?.millisecondsSinceEpoch;
        }

        if (upToTimestamp != null && locTime != null) {
          if (locTime <= upToTimestamp) {
            sync.add(loc);
          } else {
            keep.add(loc);
          }
        } else {
          sync.add(loc);
        }
      }
    }
    return {'toSync': sync, 'toKeep': keep};
  }

  /// Mock API implementation to sync a chunk of location data to the server
  Future<bool> _uploadLocationChunkApi(
    List<dynamic> chunk, {
    int? remainingCount,
  }) async {
    try {
      print(
        "APICALL _uploadLocationChunkApi Sending Location Chunk to Server (${chunk.length} items): $chunk",
      );

      // Simulate network request time
      await Future.delayed(const Duration(milliseconds: 500));
      if (mockLocationSyncSuccess) {
        print(
          "APICALL Location Batch Sync SUCCESS! Sent Payload size: ${chunk.length}",
        );
      } else {
        print(
          "APICALL Location Batch Sync FAILED! Failed Chunk Payload: $chunk",
        );
        if (remainingCount != null) {
          print("APICALL Remaining coordinates left unsynced: $remainingCount");
        }
      }
      return mockLocationSyncSuccess;
    } catch (e) {
      print("APICALL Error uploading location chunk: $e");
      print("APICALL Failed Chunk Payload: $chunk");
      if (remainingCount != null) {
        print("APICALL Remaining coordinates left unsynced: $remainingCount");
      }
      return false;
    }
  }
}
