import 'dart:developer';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:location_checker/ClockInOut/ClockInOutLocalStorage.dart';

class ClockInOutServerSyncRepository {
  final ClockInOutLocalStorage _clockInOutLocalStorage =
      ClockInOutLocalStorage();

  Future<bool> syncAllDataToServer() async {
    try {
      final Map<dynamic, dynamic> allClockInOutData =
          await _clockInOutLocalStorage.getAllClockInOutData();
      final Map<dynamic, dynamic> allLocationData =
          await _clockInOutLocalStorage.getAllLocationData();
      bool isSyncSuccess = true;

      if (allClockInOutData.isNotEmpty || allLocationData.isNotEmpty) {
        // Safe-check: only inspect entries if clock data actually exists
        if (allClockInOutData.isNotEmpty) {
          // date entry
          final firstKeyEntry = allClockInOutData.keys.first;
          // date entry first data
          final List<dynamic> entries = List<dynamic>.from(
            allClockInOutData[firstKeyEntry] ?? [],
          );

          if (entries.isNotEmpty) {
            final firstValueEntry = Map<String, dynamic>.from(entries.first);

            if (firstValueEntry["type"] == "in") {
              try {
                if (isSyncSuccess) {
                  // --- MOCK IN SYNC ---
                  log("Syncing clock-in entry: $firstValueEntry");

                  entries.removeAt(0);
                  final box = await Hive.openBox('clokINOutData');
                  if (entries.isEmpty) {
                    await box.delete(firstKeyEntry);
                  } else {
                    await box.put(firstKeyEntry, entries);
                  }
                  await box.close();
                }
              } catch (e) {
                rethrow;
              }
            } else {
              // --- OUT SYNC TRIGGERED ---
              final timeData =
                  firstValueEntry["time"]; // Check-out epoch timestamp

              if (timeData is int) {
                final DateTime checkOutTime =
                    DateTime.fromMillisecondsSinceEpoch(timeData);

                // Open 'locationdata' box to fetch and filter coordinates
                final locBox = await Hive.openBox('locationdata');
                final Map<dynamic, dynamic> allLocs = locBox.toMap();

                // Loop through every date key inside locationdata box
                for (var dateKey in allLocs.keys) {
                  final Map<dynamic, dynamic> dateMap =
                      Map<dynamic, dynamic>.from(allLocs[dateKey] ?? {});
                  final List<dynamic> locList = List<dynamic>.from(
                    dateMap['location'] ?? [],
                  );

                  final List<dynamic> remainingLocations = [];
                  final List<dynamic> syncedLocations = [];

                  for (var locEntry in locList) {
                    final map = Map<String, dynamic>.from(locEntry);

                    try {
                      DateTime locDateTime;
                      final rawLocTime = map['time'];

                      // High-precision double compatibility check
                      if (rawLocTime is int) {
                        locDateTime = DateTime.fromMillisecondsSinceEpoch(
                          rawLocTime,
                        );
                      } else {
                        final String dateStr = map['date'] ?? '';
                        final String timeStr = rawLocTime?.toString() ?? '';
                        locDateTime = DateFormat(
                          "dd-MM-yyyy hh:mm:ss.SSS a",
                        ).parse("$dateStr $timeStr");
                      }

                      // Check if coordinate was logged before or exactly at check-out
                      if (locDateTime.isBefore(checkOutTime) ||
                          locDateTime.isAtSameMomentAs(checkOutTime)) {
                        syncedLocations.add(map);
                      } else {
                        remainingLocations.add(map);
                      }
                    } catch (e) {
                      // Fallback: If parsing fails, keep it in database
                      remainingLocations.add(map);
                    }
                  }

                  // If any locations were synced before check-out, log/send and update Hive
                  if (syncedLocations.isNotEmpty) {
                    log(
                      "Syncing locations logged before check-out ($checkOutTime): $syncedLocations",
                    );

                    if (remainingLocations.isEmpty) {
                      await locBox.delete(dateKey);
                      print(
                        "Deleted date key '$dateKey' from locationdata (all synced).",
                      );
                    } else {
                      dateMap['location'] = remainingLocations;
                      await locBox.put(dateKey, dateMap);
                      print(
                        "Updated locationdata for key '$dateKey' with remaining entries.",
                      );
                    }
                  }
                }
                await locBox.close();
              }

              // Finally, remove the Clock-Out entry itself from clokINOutData
              try {
                if (isSyncSuccess) {
                  log("Syncing clock-out entry: $firstValueEntry");

                  entries.removeAt(0);
                  final box = await Hive.openBox('clokINOutData');
                  if (entries.isEmpty) {
                    await box.delete(firstKeyEntry);
                  } else {
                    await box.put(firstKeyEntry, entries);
                  }
                  await box.close();
                }
              } catch (e) {
                rethrow;
              }
            }
          }
        }

        return true;
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }
}
