// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:location_checker/ClockInOut/ClockInOutServerSyncRepository.dart';
// import 'package:location_checker/ClockInOut/dummyData.dart';

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         brightness: Brightness.dark,
//         colorSchemeSeed: const Color(0xFF0EA5E9), // Premium Sky/Cyan
//       ),
//       home: const AttendanceScreen(),
//     );
//   }
// }

// class AttendanceScreen extends StatefulWidget {
//   const AttendanceScreen({super.key});

//   @override
//   State<AttendanceScreen> createState() => _AttendanceScreenState();
// }

// class _AttendanceScreenState extends State<AttendanceScreen> {
//   // --- High-Performance Value Notifiers ---
//   final ValueNotifier<bool> _isClockedInNotifier = ValueNotifier<bool>(false);
//   final ValueNotifier<String> _timeStringNotifier = ValueNotifier<String>("");
//   final ValueNotifier<String> _dateStringNotifier = ValueNotifier<String>("");
//   final ValueNotifier<String> _todayClockInTimeNotifier = ValueNotifier<String>(
//     "--:--",
//   );
//   final ValueNotifier<String> _todayClockOutTimeNotifier =
//       ValueNotifier<String>("--:--");

//   late Timer _timer;

//   @override
//   void initState() {
//     super.initState();
//     _checkTodayClockStatus();
//     _timeStringNotifier.value = DateFormat('hh:mm:ss a').format(DateTime.now());
//     _dateStringNotifier.value = DateFormat(
//       'EEEE, d MMMM yyyy',
//     ).format(DateTime.now());
//     _timer = Timer.periodic(
//       const Duration(seconds: 1),
//       (Timer t) => _updateTime(),
//     );
//   }

//   void _updateTime() {
//     final now = DateTime.now();
//     _timeStringNotifier.value = DateFormat('hh:mm:ss a').format(now);
//     _dateStringNotifier.value = DateFormat('EEEE, d MMMM yyyy').format(now);
//   }

//   @override
//   void dispose() {
//     _timer.cancel();
//     _isClockedInNotifier.dispose();
//     _timeStringNotifier.dispose();
//     _dateStringNotifier.dispose();
//     _todayClockInTimeNotifier.dispose();
//     _todayClockOutTimeNotifier.dispose();
//     super.dispose();
//   }

//   // --- Reusable SnackBar Helper ---
//   void _showSnackBar(String message, Color bgColor) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             message,
//             style: const TextStyle(
//               fontWeight: FontWeight.w600,
//               color: Colors.white,
//             ),
//           ),
//           backgroundColor: bgColor,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   // --- Update Dashboard Display Cards ---
//   void _updateDisplayStamps(Box box) {
//     if (box.containsKey(todayStr)) {
//       final List<dynamic> todayEntries = List<dynamic>.from(
//         box.get(todayStr) ?? [],
//       );

//       if (todayEntries.isEmpty) {
//         _todayClockInTimeNotifier.value = "--:--";
//         _todayClockOutTimeNotifier.value = "--:--";
//         return;
//       }

//       Map<String, dynamic>? lastInEntry;
//       Map<String, dynamic>? lastOutEntry;

//       for (var entry in todayEntries) {
//         final map = Map<String, dynamic>.from(entry);
//         if (map['type'] == 'in') {
//           lastInEntry = map;
//         } else if (map['type'] == 'out') {
//           lastOutEntry = map;
//         }
//       }

//       String clockInDisplay = "--:--";
//       String clockOutDisplay = "--:--";

//       String formatEntryTime(Map<String, dynamic> map) {
//         final rawTime = map['time'];
//         if (rawTime is int) {
//           final dt = DateTime.fromMillisecondsSinceEpoch(rawTime);
//           return DateFormat('hh:mm a').format(dt);
//         } else if (map.containsKey('timestamp')) {
//           final dt = DateTime.fromMillisecondsSinceEpoch(
//             map['timestamp'] as int,
//           );
//           return DateFormat('hh:mm a').format(dt);
//         } else {
//           final String raw = rawTime?.toString() ?? "--:--";
//           if (raw.contains(':') && raw.length > 5) {
//             try {
//               final dt = DateFormat('hh:mm:ss.SSS a').parse(raw);
//               return DateFormat('hh:mm a').format(dt);
//             } catch (_) {
//               return raw;
//             }
//           }
//           return raw;
//         }
//       }

//       final lastEntry = Map<String, dynamic>.from(todayEntries.last);
//       final currentlyClockedIn = (lastEntry['type'] == 'in');

//       if (currentlyClockedIn) {
//         if (lastInEntry != null) {
//           clockInDisplay = formatEntryTime(lastInEntry);
//         }
//         clockOutDisplay = "--:--";
//       } else {
//         if (lastInEntry != null) {
//           clockInDisplay = formatEntryTime(lastInEntry);
//         }
//         if (lastOutEntry != null) {
//           clockOutDisplay = formatEntryTime(lastOutEntry);
//         }
//       }

//       _todayClockInTimeNotifier.value = clockInDisplay;
//       _todayClockOutTimeNotifier.value = clockOutDisplay;
//     } else {
//       _todayClockInTimeNotifier.value = "--:--";
//       _todayClockOutTimeNotifier.value = "--:--";
//     }
//   }

//   // --- Initialise Clock state on opening ---
//   Future<void> _checkTodayClockStatus() async {
//     try {
//       final box = await Hive.openBox('clokINOutData');
//       if (box.containsKey(todayStr)) {
//         final List<dynamic> todayEntries = List<dynamic>.from(
//           box.get(todayStr) ?? [],
//         );
//         if (todayEntries.isNotEmpty) {
//           final lastEntry = Map<String, dynamic>.from(todayEntries.last);
//           _isClockedInNotifier.value = (lastEntry['type'] == 'in');
//         }
//       }
//       _updateDisplayStamps(box);
//       await box.close();
//     } catch (e) {
//       print("Error checking clock status: $e");
//     }
//   }

//   // --- Clock In & Out Logic ---
//   Future<void> _handleClockInOut() async {
//     try {
//       final box = await Hive.openBox('clokINOutData');
//       final List<dynamic> todayEntries = List<dynamic>.from(
//         box.get(todayStr) ?? [],
//       );
//       final now = DateTime.now();
//       final timeStr = DateFormat('hh:mm:ss.SSS a').format(now);
//       final timestamp = now.millisecondsSinceEpoch;

//       if (!_isClockedInNotifier.value) {
//         // Clock In
//         final newEntry = {
//           "type": "in",
//           "time": timestamp,
//           "lat": 25.25,
//           "long": 58.23,
//         };
//         todayEntries.add(newEntry);
//         await box.put(todayStr, todayEntries);
//         print("Clocked In successfully: $newEntry");

//         _isClockedInNotifier.value = true;
//         _updateDisplayStamps(box);
//         _showSnackBar(
//           "Clocked In successfully at $timeStr!",
//           Colors.green.shade700,
//         );
//       } else {
//         // Clock Out
//         final newEntry = {
//           "type": "out",
//           "time": timestamp,
//           "lat": 25.30,
//           "long": 58.28,
//         };
//         todayEntries.add(newEntry);
//         await box.put(todayStr, todayEntries);
//         print("Clocked Out successfully: $newEntry");

//         _isClockedInNotifier.value = false;
//         _updateDisplayStamps(box);
//         _showSnackBar(
//           "Clocked Out successfully at $timeStr!",
//           Colors.red.shade700,
//         );
//       }
//       await box.close();
//     } catch (e) {
//       print("Error clocking in/out: $e");
//       _showSnackBar("Error: $e", Colors.red.shade700);
//     }
//   }

//   // --- Sync Today's Dummy Location Data ---
//   Future<void> _syncDataToServer() async {
//     _showSnackBar(
//       "Syncing data to local Hive database...",
//       Colors.blue.shade700,
//     );
//     try {
//       final box = await Hive.openBox('locationdata');

//       if (!box.containsKey(todayStr)) {
//         await box.put(todayStr, locationData);

//         print(
//           "Stored location data for key '$todayStr' in Hive box 'locationdata': $locationData",
//         );
//         _showSnackBar(
//           "Successfully synced today's data ($todayStr) to Hive!",
//           Colors.teal.shade700,
//         );
//       } else {
//         print(
//           "Data for key '$todayStr' already exists in Hive box 'locationdata'!",
//         );
//         _showSnackBar(
//           "Data for today ($todayStr) already exists in Hive!",
//           Colors.orange.shade700,
//         );
//       }
//       await box.close();
//     } catch (e) {
//       print("Error syncing to Hive: $e");
//       _showSnackBar("Failed to sync: $e", Colors.red.shade700);
//     }
//   }

//   // --- Add a Random Location Coordinate ---
//   Future<void> _addRandomLocation() async {
//     try {
//       final box = await Hive.openBox('locationdata');

//       // Get existing location map for today, or create a new structure
//       final Map<dynamic, dynamic> todayData = Map<dynamic, dynamic>.from(
//         box.get(todayStr) ?? {},
//       );

//       final List<dynamic> locationList = List<dynamic>.from(
//         todayData['location'] ?? [],
//       );

//       // Generate a random Lat/Long coordinate
//       final random = Random();
//       final double randomLat =
//           12.0 + (random.nextDouble() * 5.0); // 12.0 to 17.0
//       final double randomLong =
//           77.0 + (random.nextDouble() * 5.0); // 77.0 to 82.0
//       final timeStr = DateFormat('hh:mm:ss.SSS a').format(DateTime.now());

//       final newLocEntry = {
//         "date": todayStr,
//         "time": timeStr,
//         "lat": double.parse(randomLat.toStringAsFixed(4)),
//         "long": double.parse(randomLong.toStringAsFixed(4)),
//       };

//       locationList.add(newLocEntry);
//       todayData['location'] = locationList;

//       await box.put(todayStr, todayData);
//       print("Stored new random location for key '$todayStr': $newLocEntry");

//       _showSnackBar(
//         "Added Location: ${newLocEntry['lat']}, ${newLocEntry['long']}",
//         Colors.teal.shade700,
//       );

//       await box.close();
//     } catch (e) {
//       print("Error adding random location: $e");
//       _showSnackBar("Failed to add location: $e", Colors.red.shade700);
//     }
//   }

//   // --- View Pretty-Printed JSON data ---
//   Future<void> _viewHiveData() async {
//     try {
//       final dateBox = await Hive.openBox('clokINOutData');
//       final locBox = await Hive.openBox('locationdata');

//       final clokINOutData = dateBox.toMap();
//       final locData = locBox.toMap();

//       final combinedData = {
//         "clokINOutData": clokINOutData,
//         "locationdata": locData,
//       };

//       final encoder = const JsonEncoder.withIndent('  ');
//       final jsonStr = encoder.convert(combinedData);
//       print("--- HIVE ALL BOX DATA ---");
//       print(jsonStr);

//       if (mounted) {
//         showModalBottomSheet(
//           context: context,
//           backgroundColor: const Color(0xFF0F172A),
//           isScrollControlled: true, // Allow it to expand nicely
//           shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//           ),
//           builder: (context) {
//             String selectedBox = "clokINOutData"; // Default selected tab

//             return StatefulBuilder(
//               builder: (context, setSheetState) {
//                 final Map<dynamic, dynamic> currentData =
//                     selectedBox == "clokINOutData" ? clokINOutData : locData;
//                 final String boxJsonStr = encoder.convert(currentData);

//                 return FractionallySizedBox(
//                   heightFactor: 0.75, // Lock it to a beautiful, clean height
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20.0,
//                       vertical: 20.0,
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // --- Drag Handle ---
//                         Center(
//                           child: Container(
//                             width: 42,
//                             height: 4.5,
//                             margin: const EdgeInsets.only(bottom: 16),
//                             decoration: BoxDecoration(
//                               color: Colors.white24,
//                               borderRadius: BorderRadius.circular(2.5),
//                             ),
//                           ),
//                         ),

//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             const Text(
//                               "Database Inspector",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(
//                                 Icons.close,
//                                 color: Colors.white,
//                               ),
//                               onPressed: () => Navigator.pop(context),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),

//                         // --- Interactive Tab Selectors ---
//                         Row(
//                           children: [
//                             _buildTabButton(
//                               label: "clokINOutData (Sessions)",
//                               isSelected: selectedBox == "clokINOutData",
//                               onTap: () {
//                                 setSheetState(() {
//                                   selectedBox = "clokINOutData";
//                                 });
//                               },
//                             ),
//                             const SizedBox(width: 10),
//                             _buildTabButton(
//                               label: "locationdata (Locations)",
//                               isSelected: selectedBox == "locationdata",
//                               onTap: () {
//                                 setSheetState(() {
//                                   selectedBox = "locationdata";
//                                 });
//                               },
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 16),

//                         // --- Display Container ---
//                         Expanded(
//                           child: Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF1E293B),
//                               borderRadius: BorderRadius.circular(16),
//                               border: Border.all(color: Colors.white10),
//                             ),
//                             child: SingleChildScrollView(
//                               child: SelectableText(
//                                 currentData.isEmpty
//                                     ? "{} (No records found)"
//                                     : boxJsonStr,
//                                 style: const TextStyle(
//                                   color: Color(0xFF38BDF8),
//                                   fontFamily: 'monospace',
//                                   fontSize: 13.0,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       }
//       await dateBox.close();
//       await locBox.close();
//     } catch (e) {
//       print("Error reading Hive: $e");
//     }
//   }

//   // --- Clear Hive Database ---
//   Future<void> _clearHiveData() async {
//     try {
//       final dateBox = await Hive.openBox('clokINOutData');
//       await dateBox.clear();
//       await dateBox.close();

//       final locBox = await Hive.openBox('locationdata');
//       await locBox.clear();
//       await locBox.close();

//       _isClockedInNotifier.value = false;
//       _todayClockInTimeNotifier.value = "--:--";
//       _todayClockOutTimeNotifier.value = "--:--";

//       _showSnackBar("All Hive data successfully cleared!", Colors.red.shade700);
//     } catch (e) {
//       print("Error clearing Hive: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0F172A), // Slate 900 Background
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               // --- Header / Title ---
//               const SizedBox(height: 10),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.workspace_premium_rounded,
//                     color: Colors.blue.shade400,
//                     size: 28,
//                   ),
//                   const SizedBox(width: 8),
//                   const Text(
//                     "Work Tracker Pro",
//                     style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.w800,
//                       color: Colors.white,
//                       letterSpacing: 0.8,
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 30),

//               // --- Dynamic Clock Card ---
//               // ValueListenableBuilder<String>(
//               //   valueListenable: _dateStringNotifier,
//               //   builder: (context, dateString, child) {
//               //     return ValueListenableBuilder<String>(
//               //       valueListenable: _timeStringNotifier,
//               //       builder: (context, timeString, child) {
//               //         return Container(
//               //           width: double.infinity,
//               //           padding: const EdgeInsets.symmetric(
//               //             vertical: 15,
//               //             horizontal: 24,
//               //           ),
//               //           decoration: BoxDecoration(
//               //             color: const Color(0xFF1E293B),
//               //             borderRadius: BorderRadius.circular(20),
//               //             border: Border.all(
//               //               color: Colors.white.withOpacity(0.05),
//               //             ),
//               //             boxShadow: [
//               //               BoxShadow(
//               //                 color: Colors.black.withOpacity(0.2),
//               //                 blurRadius: 15,
//               //                 offset: const Offset(0, 8),
//               //               ),
//               //             ],
//               //           ),
//               //           child: Column(
//               //             children: [
//               //               Text(
//               //                 dateString,
//               //                 style: TextStyle(
//               //                   fontSize: 15,
//               //                   color: Colors.white.withOpacity(0.5),
//               //                   fontWeight: FontWeight.w500,
//               //                 ),
//               //               ),
//               //               const SizedBox(height: 8),
//               //               Text(
//               //                 timeString,
//               //                 style: const TextStyle(
//               //                   fontSize: 32,
//               //                   fontFamily: 'monospace',
//               //                   fontWeight: FontWeight.w700,
//               //                   color: Colors.white,
//               //                   letterSpacing: 1.0,
//               //                 ),
//               //               ),
//               //             ],
//               //           ),
//               //         );
//               //       },
//               //     );
//               //   },
//               // ),
//               SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton.icon(
//                   onPressed: _addRandomLocation,
//                   icon: const Icon(Icons.add_location_alt_rounded, size: 20),
//                   label: const Text(
//                     "GENERATE RANDOM LOCATION",
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 13,
//                       letterSpacing: 0.5,
//                     ),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal.shade600,
//                     foregroundColor: Colors.white,
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 5),
//               SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton.icon(
//                   onPressed: () async {
//                     try {
//                       ClockInOutServerSyncRepository syncRepository =
//                           ClockInOutServerSyncRepository();

//                       var sy = await syncRepository.syncAllDataToServer();
//                       if (sy) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text("Data Synced Successfully"),
//                             backgroundColor: Colors.green,
//                           ),
//                         );
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text("No Offline Data to Sync"),
//                             backgroundColor: Colors.orange,
//                           ),
//                         );
//                       }
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text("Sync Error: $e"),
//                           backgroundColor: Colors.red.shade700,
//                         ),
//                       );
//                     }
//                   },
//                   icon: const Icon(Icons.add_location_alt_rounded, size: 20),
//                   label: const Text(
//                     "Api Call And Delete From Hive",
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 13,
//                       letterSpacing: 0.5,
//                     ),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal.shade600,
//                     foregroundColor: Colors.white,
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 5),
//               // --- Glowing Pulse Clock Button ---
//               ValueListenableBuilder<bool>(
//                 valueListenable: _isClockedInNotifier,
//                 builder: (context, isClockedIn, child) {
//                   final statusColor = isClockedIn
//                       ? const Color(0xFFF43F5E)
//                       : const Color(0xFF10B981);
//                   final shadowColor = statusColor.withOpacity(0.3);

//                   return GestureDetector(
//                     onTap: _handleClockInOut,
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       width: 200,
//                       height: 200,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: const Color(0xFF1E293B),
//                         border: Border.all(
//                           color: statusColor.withOpacity(0.8),
//                           width: 6,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: shadowColor,
//                             blurRadius: 30,
//                             spreadRadius: 8,
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.fingerprint_rounded,
//                             size: 64,
//                             color: statusColor,
//                           ),
//                           const SizedBox(height: 12),
//                           Text(
//                             isClockedIn ? "CLOCK OUT" : "CLOCK IN",
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w800,
//                               color: statusColor,
//                               letterSpacing: 1.5,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),

//               const SizedBox(height: 30),

//               // --- Daily Metrics Card ---
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF1E293B),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: Colors.white.withOpacity(0.05)),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     ValueListenableBuilder<String>(
//                       valueListenable: _todayClockInTimeNotifier,
//                       builder: (context, clockInTime, child) {
//                         return _buildMetricColumn(
//                           "CLOCK IN",
//                           clockInTime,
//                           Icons.login_rounded,
//                           Colors.teal,
//                         );
//                       },
//                     ),
//                     Container(
//                       width: 1,
//                       height: 40,
//                       color: Colors.black.withOpacity(0.2),
//                     ),
//                     ValueListenableBuilder<String>(
//                       valueListenable: _todayClockOutTimeNotifier,
//                       builder: (context, clockOutTime, child) {
//                         return _buildMetricColumn(
//                           "CLOCK OUT",
//                           clockOutTime,
//                           Icons.logout_rounded,
//                           Colors.red,
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),

//               const Spacer(),

//               // --- Action Buttons ---
//               Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: SizedBox(
//                         height: 54,
//                         child: ElevatedButton.icon(
//                           onPressed: _syncDataToServer,
//                           icon: const Icon(Icons.cloud_sync_rounded, size: 20),
//                           label: const Text(
//                             "SYNC TODAY",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 13,
//                             ),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue.shade600,
//                             foregroundColor: Colors.white,
//                             elevation: 2,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: SizedBox(
//                         height: 54,
//                         child: OutlinedButton.icon(
//                           onPressed: _viewHiveData,
//                           icon: const Icon(Icons.list, size: 20),
//                           label: const Text(
//                             "VIEW LOGS",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 14,
//                             ),
//                           ),
//                           style: OutlinedButton.styleFrom(
//                             foregroundColor: Colors.blue.shade400,
//                             side: BorderSide(
//                               color: Colors.blue.shade600.withOpacity(0.5),
//                               width: 1.5,
//                             ),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 12),

//               // --- Clear Button ---
//               SizedBox(
//                 width: double.infinity,
//                 child: TextButton.icon(
//                   onPressed: _clearHiveData,
//                   icon: const Icon(
//                     Icons.delete_forever_rounded,
//                     color: Colors.red,
//                     size: 18,
//                   ),
//                   label: const Text(
//                     "RESET ALL LOCAL SESSIONS",
//                     style: TextStyle(
//                       color: Colors.red,
//                       fontSize: 13,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: 0.8,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 5),
//               SizedBox(
//                 width: double.infinity,
//                 child: TextButton.icon(
//                   onPressed: () {
//                     ClockInOutServerSyncRepository syncRepository =
//                         ClockInOutServerSyncRepository();

//                     syncRepository.syncAllDataToServer();
//                   },
//                   icon: const Icon(
//                     Icons.delete_forever_rounded,
//                     color: Colors.red,
//                     size: 18,
//                   ),
//                   label: const Text(
//                     "Test",
//                     style: TextStyle(
//                       color: Colors.red,
//                       fontSize: 13,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: 0.8,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMetricColumn(
//     String label,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Icon(icon, size: 16, color: color),
//             const SizedBox(width: 6),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 0.8,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 6),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w700,
//             color: Colors.white,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTabButton({
//     required String label,
//     required bool isSelected,
//     required VoidCallback onTap,
//   }) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             color: isSelected ? Colors.blue.shade600 : const Color(0xFF1E293B),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: isSelected ? Colors.blue.shade400 : Colors.white10,
//               width: 1,
//             ),
//           ),
//           child: Text(
//             label,
//             style: TextStyle(
//               color: isSelected ? Colors.white : Colors.white70,
//               fontWeight: FontWeight.bold,
//               fontSize: 12.0,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
