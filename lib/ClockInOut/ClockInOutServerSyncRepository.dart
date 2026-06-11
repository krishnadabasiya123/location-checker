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
                }
              } catch (e) {
                rethrow;
              }
            } else {
              // --- OUT SYNC TRIGGERED ---
              final timeData =
                  firstValueEntry["time"]; // Check-out epoch timestamp

              final DateTime? checkOutTime = _parseTimeToDateTime(
                firstKeyEntry.toString(),
                timeData,
              );

              if (checkOutTime != null) {
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
                      final rawLocTime = map['time'];
                      final String dateStr = map['date'] ?? dateKey.toString();
                      final DateTime? locDateTime = _parseTimeToDateTime(
                        dateStr,
                        rawLocTime,
                      );

                      // Check if coordinate was logged before or exactly at check-out
                      if (locDateTime != null &&
                          (locDateTime.isBefore(checkOutTime) ||
                              locDateTime.isAtSameMomentAs(checkOutTime))) {
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

  /// Helper to robustly convert time string formats or integer timestamps to DateTime.
  DateTime? _parseTimeToDateTime(String dateStr, dynamic timeVal) {
    if (timeVal is int) {
      return DateTime.fromMillisecondsSinceEpoch(timeVal);
    }
    if (timeVal is String) {
      final parsedInt = int.tryParse(timeVal);
      if (parsedInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsedInt);
      }

      try {
        final formattedTime = timeVal.trim();
        DateTime? parsedDate;
        final formats = [
          'dd-MM-yyyy hh:mm:ss.SSS a',
          'dd-MM-yyyy hh:mm:ss a',
          'dd-MM-yyyy hh:mm a',
          'hh:mm:ss.SSS a',
          'hh:mm:ss a',
          'hh:mm a',
        ];
        for (var fmt in formats) {
          try {
            if (fmt.contains('dd-MM-yyyy')) {
              parsedDate = DateFormat(fmt).parse("$dateStr $formattedTime");
            } else {
              parsedDate = DateFormat(fmt).parse(formattedTime);
              if (parsedDate != null) {
                final dateParts = dateStr.split('-');
                if (dateParts.length == 3) {
                  final day = int.parse(dateParts[0]);
                  final month = int.parse(dateParts[1]);
                  final year = int.parse(dateParts[2]);
                  parsedDate = DateTime(
                    year,
                    month,
                    day,
                    parsedDate.hour,
                    parsedDate.minute,
                    parsedDate.second,
                    parsedDate.millisecond,
                  );
                }
              }
            }
            break;
          } catch (_) {}
        }
        return parsedDate;
      } catch (e) {
        log("Error parsing time string '$timeVal': $e");
      }
    }
    return null;
  }
}
