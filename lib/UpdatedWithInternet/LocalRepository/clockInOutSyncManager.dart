// without isolate

// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:location_checker/Widget/internetConnectivity.dart';

// class ClockInOutSyncManager {
//   static final ClockInOutSyncManager _instance =
//       ClockInOutSyncManager._internal();
//   factory ClockInOutSyncManager() => _instance;
//   ClockInOutSyncManager._internal();

//   StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
//   bool _isSyncing = false;

//   // Mock API flags
//   static bool mockClockInSuccess = true;
//   static bool mockLocationSyncSuccess = true;
//   static bool mockClockOutSuccess = true;

//   void startMonitoring() {
//     if (_connectivitySubscription != null) return;
//     print("Starting continuous internet connectivity monitoring...");
//     _initialSyncCheck();

//     _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
//       results,
//     ) async {
//       final hasInternet = results.any(
//         (result) =>
//             result == ConnectivityResult.mobile ||
//             result == ConnectivityResult.wifi ||
//             result == ConnectivityResult.ethernet,
//       );
//       if (hasInternet) {
//         print("Internet detected! Triggering sync...");
//         await triggerSync();
//       }
//     });
//   }

//   Future<void> _initialSyncCheck() async {
//     if (await _hasInternet()) {
//       await triggerSync();
//     }
//   }

//   void stopMonitoring() {
//     _connectivitySubscription?.cancel();
//     _connectivitySubscription = null;
//   }

//   Future<void> triggerSync() async {
//     if (_isSyncing) return;
//     _isSyncing = true;

//     try {
//       if (!await _hasInternet()) {
//         _isSyncing = false;
//         return;
//       }

//       final clockBox = await Hive.openBox('clokINOutData');
//       final locBox = await Hive.openBox('locationdata');

//       // specific date data get for date wise
//       final dates = List<String>.from(clockBox.keys.map((k) => k.toString()));

//       for (final date in dates) {
//         if (!await _hasInternet()) break;

//         final List<dynamic> entries = List<dynamic>.from(
//           clockBox.get(date) ?? [],
//         );
//         if (entries.isEmpty) continue;

//         bool shouldStop = false;
//         final List<dynamic> remainingEntries = [];

//         for (final entry in entries) {
//           if (shouldStop) {
//             remainingEntries.add(entry);
//             continue;
//           }

//           if (!await _hasInternet()) {
//             shouldStop = true;
//             remainingEntries.add(entry);
//             continue;
//           }

//           final map = Map<String, dynamic>.from(entry);
//           final type = map['type'];
//           final int? clockEventTime = _parseTimeToTimestamp(map['time']);

//           if (type == 'in') {
//             final success = await _clockInApi(map);
//             if (!success) {
//               shouldStop = true;
//               remainingEntries.add(entry);
//             }
//           } else if (type == 'out') {
//             // 1. Gather location coordinates up to clock out time
//             final locBoxData = locBox.get(date);
//             List<dynamic> coordinatesToSync = [];
//             List<dynamic> coordinatesToKeep = [];

//             if (locBoxData is Map && locBoxData['location'] != null) {
//               final locations = List<dynamic>.from(locBoxData['location']);

//               for (var loc in locations) {
//                 if (loc is Map) {
//                   final int? locTime = _parseTimeToTimestamp(loc['time']);

//                   // Since both are now integers, comparison is simple and fast
//                   if (clockEventTime != null && locTime != null) {
//                     if (locTime <= clockEventTime) {
//                       coordinatesToSync.add(loc);
//                     } else {
//                       coordinatesToKeep.add(loc);
//                     }
//                   } else {
//                     coordinatesToSync.add(loc);
//                   }
//                 }
//               }
//             }

//             // 2. Upload locations in batches
//             bool chunkSyncSuccess = true;
//             const int chunkSize = 500;
//             final List<dynamic> failedCoordinates = [];

//             for (int i = 0; i < coordinatesToSync.length; i += chunkSize) {
//               if (!chunkSyncSuccess || !await _hasInternet()) {
//                 chunkSyncSuccess = false;
//                 failedCoordinates.addAll(coordinatesToSync.sublist(i));
//                 continue;
//               }

//               int end = (i + chunkSize < coordinatesToSync.length)
//                   ? i + chunkSize
//                   : coordinatesToSync.length;

//               final chunk = coordinatesToSync.sublist(i, end);
//               final success = await _syncLocationChunkApi(chunk);
//               if (!success) chunkSyncSuccess = false;
//             }

//             // Update Hive with remaining/failed locations
//             final updatedLocations = [
//               ...failedCoordinates,
//               ...coordinatesToKeep,
//             ];
//             if (updatedLocations.isEmpty) {
//               await locBox.delete(date);
//             } else {
//               await locBox.put(date, {'location': updatedLocations});
//             }

//             // 3. Clock Out API
//             if (chunkSyncSuccess) {
//               final success = await _clockOutApi(map);
//               if (!success) {
//                 shouldStop = true;
//                 remainingEntries.add(entry);
//               }
//             } else {
//               shouldStop = true;
//               remainingEntries.add(entry);
//             }
//           }
//         }

//         if (remainingEntries.isEmpty) {
//           await clockBox.delete(date);
//         } else {
//           await clockBox.put(date, remainingEntries);
//         }

//         if (shouldStop) break;
//       }
//     } catch (e) {
//       print("Error during sync: $e");
//     } finally {
//       _isSyncing = false;
//     }
//   }

//   /// Optimized to handle milliseconds (int) directly
//   int? _parseTimeToTimestamp(dynamic timeVal) {
//     if (timeVal is int) return timeVal;

//     if (timeVal is String) {
//       // Handle case where string is just an integer
//       final parsedInt = int.tryParse(timeVal);
//       if (parsedInt != null) return parsedInt;

//       // Fallback for legacy string formats if they still exist
//       try {
//         return DateTime.parse(timeVal).millisecondsSinceEpoch;
//       } catch (_) {
//         return null;
//       }
//     }
//     return null;
//   }

//   Future<bool> _hasInternet() async {
//     return await InternetConnectivity.checkInternet();
//   }

//   // --- Mock API Implementations ---
//   Future<bool> _clockInApi(Map<String, dynamic> entry) async {
//     try {
//       print("Syncing Clock In: ${entry['time']}");
//       await Future.delayed(const Duration(milliseconds: 500));
//       mockClockInSuccess = true;
//       return mockClockInSuccess;
//     } catch (e) {
//       mockClockInSuccess = false;
//       return mockClockInSuccess;
//     }
//   }

//   Future<bool> _syncLocationChunkApi(List<dynamic> chunk) async {
//     try {
//       print("Syncing Location Batch: ${chunk.length} items");
//       await Future.delayed(const Duration(milliseconds: 500));
//       mockLocationSyncSuccess = true;
//       return mockLocationSyncSuccess;
//     } catch (e) {
//       mockLocationSyncSuccess = false;
//       return mockLocationSyncSuccess;
//     }
//   }

//   Future<bool> _clockOutApi(Map<String, dynamic> entry) async {
//     try {
//       print("Syncing Clock Out: ${entry['time']}");
//       await Future.delayed(const Duration(milliseconds: 500));
//       mockClockOutSuccess = true;
//       return mockClockOutSuccess;
//     } catch (e) {
//       mockClockOutSuccess = false;
//       return mockClockOutSuccess;
//     }
//   }
// }

// with isolate

import 'dart:async';
import 'dart:isolate'; // Required for Isolate
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location_checker/Widget/internetConnectivity.dart';
import 'package:location_checker/UpdatedWithInternet/LocalRepository/location_repository.dart';

class ClockInOutSyncManager {
  static final ClockInOutSyncManager _instance =
      ClockInOutSyncManager._internal();
  factory ClockInOutSyncManager() => _instance;
  ClockInOutSyncManager._internal();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  static bool mockClockInSuccess = true;
  static bool mockClockOutSuccess = true;

  Future<void> startMonitoring() async {
    if (_connectivitySubscription != null) return;
    await _initialSyncCheck();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final hasInternet = results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );
      if (hasInternet) await triggerSync();
    });
  }

  Future<void> _initialSyncCheck() async {
    if (await _hasInternet()) await triggerSync();
  }

  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      if (!await _hasInternet()) {
        _isSyncing = false;
        return;
      }

      final clockBox = await Hive.openBox('clokINOutData');
      final dates = List<String>.from(clockBox.keys.map((k) => k.toString()));

      // Sort dates chronologically (oldest first)
      final dateFormat = DateFormat("dd-MM-yyyy");
      dates.sort((a, b) {
        try {
          final dateA = dateFormat.parse(a);
          final dateB = dateFormat.parse(b);
          return dateA.compareTo(dateB);
        } catch (_) {
          return a.compareTo(b); // fallback to alphabetical sorting
        }
      });

      for (final date in dates) {
        if (!await _hasInternet()) break;

        final List<dynamic> entries = List<dynamic>.from(
          clockBox.get(date) ?? [],
        );
        if (entries.isEmpty) continue;

        bool shouldStop = false;
        final List<dynamic> remainingEntries = [];

        for (final entry in entries) {
          if (shouldStop || !await _hasInternet()) {
            remainingEntries.add(entry);
            shouldStop = true;
            continue;
          }

          final map = Map<String, dynamic>.from(entry);
          final int? clockEventTime = _parseTimeToTimestamp(map['time']);

          if (map['type'] == 'in') {
            if (!await _clockInApi(map)) {
              shouldStop = true;
              remainingEntries.add(entry);
            }
          } else if (map['type'] == 'out') {
            // Automatically loads, background-filters, chunk-syncs, and updates Hive box internally
            final syncResult = await LocationRepository().syncLocationsToServer(
              date: date,
              upToTimestamp: clockEventTime,
            );

            final bool chunkSyncSuccess = syncResult['success'] ?? false;

            if (chunkSyncSuccess) {
              if (!await _clockOutApi(map)) {
                shouldStop = true;
                remainingEntries.add(entry);
              }
            } else {
              shouldStop = true;
              remainingEntries.add(entry);
            }
          }
        }

        if (remainingEntries.isEmpty) {
          await clockBox.delete(date);
        } else {
          await clockBox.put(date, remainingEntries);
        }
        if (shouldStop) break;
      }
    } catch (e) {
      print("Sync Error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  static int? _parseTimeToTimestamp(dynamic timeVal) {
    if (timeVal is int) return timeVal;
    if (timeVal is String) {
      final parsedInt = int.tryParse(timeVal);
      if (parsedInt != null) return parsedInt;
      try {
        return DateTime.parse(timeVal).millisecondsSinceEpoch;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<bool> _hasInternet() async =>
      await InternetConnectivity.checkInternet();

  // --- Mock APIs ---
  Future<bool> _clockInApi(Map<String, dynamic> e) async {
    print("APICALL _clockInApi Sending Clock In Data to Server: $e");
    //await Future.delayed(const Duration(milliseconds: 500));
    if (mockClockInSuccess) {
      //print("✅ Clock In Sync SUCCESS! Sent Payload: $e");
    } else {
      //  print("❌ Clock In Sync FAILED! Payload: $e");
    }
    return mockClockInSuccess;
  }

  Future<bool> _clockOutApi(Map<String, dynamic> e) async {
    print("APICALL _clockOutApi Sending Clock Out Data to Server: $e");
    //   await Future.delayed(const Duration(milliseconds: 500));
    if (mockClockOutSuccess) {
      // print("✅ Clock Out Sync SUCCESS! Sent Payload: $e");
    } else {
      //   print("❌ Clock Out Sync FAILED! Payload: $e");
    }
    return mockClockOutSuccess;
  }
}
