{
  "20-05-2025": {
    "isClockIn": {
      "action": "clock_in",
      "lat": 25.25,
      "long": 58.23,
      "date": "20-05-2025",
      "time": "09:10 AM"
    },
    "isClockOut": {
      "action": "clock_out",
      "lat": 25.30,
      "long": 58.28,
      "date": "20-05-2025",
      "time": "06:45 PM"
    },
    "location": [
      {
        "date": "20-05-2025",
        "time": "10:00 AM",
        "lat": 12.23,
        "long": 34.44
      },
      {
        "date": "20-05-2025",
        "time": "01:30 PM",
        "lat": 12.50,
        "long": 34.80
      },
      {
        "date": "20-05-2025",
        "time": "04:15 PM",
        "lat": 12.90,
        "long": 35.10
      }
    ]
  }
}

# Future<bool> syncAllDataToServer() async {
#     try {
#       final Map<dynamic, dynamic> allClockInOutData =
#           await _clockInOutLocalStorage.getAllClockInOutData();
#       final Map<dynamic, dynamic> allLocationData =
#           await _clockInOutLocalStorage.getAllLocationData();
#       bool isSyncSuccess = true;

#       if (allClockInOutData.isNotEmpty || allLocationData.isNotEmpty) {
#         // Safe-check: only inspect entries if clock data actually exists
#         if (allClockInOutData.isNotEmpty) {
#           // Sort the date keys chronologically so older days sync first
#           final sortedDateKeys = List<String>.from(allClockInOutData.keys);
#           sortedDateKeys.sort((a, b) {
#             try {
#               final dateA = DateFormat('dd-MM-yyyy').parse(a);
#               final dateB = DateFormat('dd-MM-yyyy').parse(b);
#               return dateA.compareTo(dateB);
#             } catch (_) {
#               return a.compareTo(b);
#             }
#           });

#           for (var dateKey in sortedDateKeys) {
#             final List<dynamic> entries = List<dynamic>.from(
#               allClockInOutData[dateKey] ?? [],
#             );

#             // Keep a copy that we will progressively update and save to Hive
#             final List<dynamic> remainingEntries = List<dynamic>.from(entries);

#             for (var entry in entries) {
#               final valEntry = Map<String, dynamic>.from(entry);

#               if (valEntry["type"] == "in") {
#                 try {
#                   if (isSyncSuccess) {
#                     // --- MOCK IN SYNC ---
#                     log("Syncing clock-in entry: $valEntry");

#                     remainingEntries.removeAt(0);
#                     final box = await Hive.openBox('clokINOutData');
#                     if (remainingEntries.isEmpty) {
#                       await box.delete(dateKey);
#                     } else {
#                       await box.put(dateKey, remainingEntries);
#                     }
#                     await box.close();
#                   }
#                 } catch (e) {
#                   rethrow;
#                 }
#               } else {
#                 // --- OUT SYNC TRIGGERED ---
#                 final timeData = valEntry["time"]; // Check-out epoch timestamp

#                 if (timeData is int) {
#                   final DateTime checkOutTime =
#                       DateTime.fromMillisecondsSinceEpoch(timeData);

#                   // Open 'locationdata' box to fetch and filter coordinates
#                   final locBox = await Hive.openBox('locationdata');
#                   final Map<dynamic, dynamic> allLocs = locBox.toMap();

#                   // Loop through every date key inside locationdata box
#                   for (var locDateKey in allLocs.keys) {
#                     final Map<dynamic, dynamic> dateMap =
#                         Map<dynamic, dynamic>.from(allLocs[locDateKey] ?? {});
#                     final List<dynamic> locList = List<dynamic>.from(
#                       dateMap['location'] ?? [],
#                     );

#                     final List<dynamic> remainingLocations = [];
#                     final List<dynamic> syncedLocations = [];

#                     for (var locEntry in locList) {
#                       final map = Map<String, dynamic>.from(locEntry);

#                       try {
#                         DateTime locDateTime;
#                         final rawLocTime = map['time'];

#                         // High-precision double compatibility check
#                         if (rawLocTime is int) {
#                           locDateTime = DateTime.fromMillisecondsSinceEpoch(
#                             rawLocTime,
#                           );
#                         } else {
#                           final String dateStr = map['date'] ?? '';
#                           final String timeStr = rawLocTime?.toString() ?? '';
#                           locDateTime = DateFormat(
#                             "dd-MM-yyyy hh:mm:ss.SSS a",
#                           ).parse("$dateStr $timeStr");
#                         }

#                         // Check if coordinate was logged before or exactly at check-out
#                         if (locDateTime.isBefore(checkOutTime) ||
#                             locDateTime.isAtSameMomentAs(checkOutTime)) {
#                           syncedLocations.add(map);
#                         } else {
#                           remainingLocations.add(map);
#                         }
#                       } catch (e) {
#                         // Fallback: If parsing fails, keep it in database
#                         remainingLocations.add(map);
#                       }
#                     }

#                     // If any locations were synced before check-out, log/send and update Hive
#                     if (syncedLocations.isNotEmpty) {
#                       log(
#                         "Syncing locations logged before check-out ($checkOutTime): $syncedLocations",
#                       );

#                       if (remainingLocations.isEmpty) {
#                         await locBox.delete(locDateKey);
#                         print(
#                           "Deleted date key '$locDateKey' from locationdata (all synced).",
#                         );
#                       } else {
#                         dateMap['location'] = remainingLocations;
#                         await locBox.put(locDateKey, dateMap);
#                         print(
#                           "Updated locationdata for key '$locDateKey' with remaining entries.",
#                         );
#                       }
#                     }
#                   }
#                   await locBox.close();
#                 }

#                 // Finally, remove the Clock-Out entry itself from clokINOutData
#                 try {
#                   if (isSyncSuccess) {
#                     log("Syncing clock-out entry: $valEntry");

#                     remainingEntries.removeAt(0);
#                     final box = await Hive.openBox('clokINOutData');
#                     if (remainingEntries.isEmpty) {
#                       await box.delete(dateKey);
#                     } else {
#                       await box.put(dateKey, remainingEntries);
#                     }
#                     await box.close();
#                   }
#                 } catch (e) {
#                   rethrow;
#                 }
#               }
#             }
#           }
#         }

#         return true;
#       } else {
#         return false;
#       }
#     } catch (e) {
#       rethrow;
#     }
#   }