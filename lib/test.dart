// import 'dart:async';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';

// // Global notification plugin
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // 1. Initialize Timezone
//   tz.initializeTimeZones();
//   final String timeZoneName =
//       (await FlutterTimezone.getLocalTimezone()).identifier;
//   tz.setLocalLocation(tz.getLocation(timeZoneName));

//   // 2. Initialize Local Notifications for UI
//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
//   const DarwinInitializationSettings initializationSettingsIOS =
//       DarwinInitializationSettings(
//         requestAlertPermission: true,
//         requestBadgePermission: true,
//         requestSoundPermission: true,
//       );
//   await flutterLocalNotificationsPlugin.initialize(
//     settings: const InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     ),
//   );

//   // 3. Initialize Background Service
//   await initializeService();

//   runApp(const MaterialApp(home: HomePage()));
// }

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'my_foreground',
//     'Service Channel',
//     importance: Importance.low,
//   );

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: false,
//       isForegroundMode: true,
//       notificationChannelId: 'my_foreground',
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: false,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//   );
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   return true;
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // Logic for Android or iOS (Minimized)
//   Timer(const Duration(seconds: 15), () async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('noti_triggered', true);
//     print("BACKGROUND_LOG: 15 seconds reached. Flag set to TRUE.");
//     service.invoke('update_ui');
//     service.stopSelf();
//   });
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
//   bool isTriggered = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     loadFlag();

//     // Listen for background updates if app is open
//     FlutterBackgroundService().on('update_ui').listen((event) {
//       loadFlag();
//     });
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // When you re-open the app from a closed state, refresh the UI
//     if (state == AppLifecycleState.resumed) {
//       loadFlag();
//     }
//   }

//   Future<void> loadFlag() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     // Check 1: Did the background service set it?
//     bool backgroundValue = prefs.getBool('noti_triggered') ?? false;

//     // Check 2: Calculate based on Time (For iOS Closed State)
//     int? startTimeMillis = prefs.getInt('start_timestamp');
//     bool timePassed = false;
//     if (startTimeMillis != null) {
//       DateTime startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
//       if (DateTime.now().difference(startTime).inSeconds >= 15) {
//         timePassed = true;
//       }
//     }

//     setState(() {
//       isTriggered = backgroundValue || timePassed;
//     });
//   }

//   Future<void> start15sTask() async {
//     // 1. Reset everything
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('noti_triggered', false);
//     await prefs.setInt(
//       'start_timestamp',
//       DateTime.now().millisecondsSinceEpoch,
//     );
//     setState(() {
//       isTriggered = false;
//     });

//     // 2. Schedule Notification (This works on iOS even if app is closed)
//     final scheduledTime = tz.TZDateTime.now(
//       tz.local,
//     ).add(const Duration(seconds: 15));
//     await flutterLocalNotificationsPlugin.zonedSchedule(
//       id: 888,
//       title: 'Notification Success!',
//       body: '15 seconds passed. Flag is now TRUE.',
//       scheduledDate: scheduledTime,
//       notificationDetails: const NotificationDetails(
//         android: AndroidNotificationDetails('my_foreground', 'Service'),
//         iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//     );

//     // 3. Start Service (For Android and Logs)
//     FlutterBackgroundService().startService();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text("Scheduled for 15s. You can close the app now!"),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("iOS Terminated Flag Fix")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               "Notification Triggered?",
//               style: TextStyle(fontSize: 18),
//             ),
//             Text(
//               isTriggered ? "TRUE" : "FALSE",
//               style: TextStyle(
//                 fontSize: 60,
//                 fontWeight: FontWeight.bold,
//                 color: isTriggered ? Colors.green : Colors.red,
//               ),
//             ),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               onPressed: start15sTask,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 40,
//                   vertical: 15,
//                 ),
//               ),
//               child: const Text("START 15s TIMER"),
//             ),
//             TextButton(
//               onPressed: () async {
//                 SharedPreferences prefs = await SharedPreferences.getInstance();
//                 await prefs.clear();
//                 loadFlag();
//               },
//               child: const Text("Clear/Reset Everything"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

/// main filee
///
/// // import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'location_service.dart';
// import 'notification_service.dart';
// import 'background_service.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Location Service
//   final locationService = LocationService();

//   // Request Location Permission first
//   final hasPermission = await locationService.handleLocationPermission();

//   // Initialize Hive
//   await locationService.init();

//   if (hasPermission) {
//     locationService.startTracking();
//   } else {
//     print('Tracking not started: Location permission denied.');
//   }

//   // Initialize Notifications
//   final notificationService = NotificationService();
//   await notificationService.init();
//   await notificationService.scheduleDailyTenAM();

//   // Initialize Background Service (auto-starts if enabled)
//   await initializeBackgroundService();

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Location Checker',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
//         useMaterial3: true,
//       ),
//       home: const MyHomePage(title: 'Location & Hive Tracker'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   bool _isServiceRunning = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkServiceStatus();
//   }

//   Future<void> _checkServiceStatus() async {
//     final running = await FlutterBackgroundService().isRunning();
//     setState(() {
//       _isServiceRunning = running;
//     });
//   }

//   Future<void> _toggleService() async {
//     final service = FlutterBackgroundService();
//     final running = await service.isRunning();

//     if (running) {
//       service.invoke("stopService");
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Stopping background logger...'),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//     } else {
//       await service.startService();
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Starting 5-second background logger...'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }

//     // Give it a brief moment to update status
//     await Future.delayed(const Duration(milliseconds: 500));
//     _checkServiceStatus();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _checkServiceStatus,
//             tooltip: 'Refresh Service Status',
//           )
//         ],
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: <Widget>[
//               const Icon(Icons.location_on, size: 80, color: Colors.teal),
//               const SizedBox(height: 10),
//               const Text(
//                 'Tracking Dummy Location...',
//                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//               ),
//               const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
//                 child: Text(
//                   'Data is stored in Hive every 10 seconds (Foreground) or every 5 seconds (Background Service).\n'
//                   'Daily notification scheduled for 10:00 AM.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Service Status Card
//               Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 40),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: _isServiceRunning
//                       ? Colors.green.withOpacity(0.1)
//                       : Colors.grey.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: _isServiceRunning ? Colors.green : Colors.grey,
//                     width: 1.5,
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       width: 12,
//                       height: 12,
//                       decoration: BoxDecoration(
//                         color: _isServiceRunning ? Colors.green : Colors.grey,
//                         shape: BoxShape.circle,
//                         boxShadow: _isServiceRunning
//                             ? [
//                                 BoxShadow(
//                                   color: Colors.green.withOpacity(0.5),
//                                   spreadRadius: 3,
//                                   blurRadius: 5,
//                                 )
//                               ]
//                             : [],
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Text(
//                       _isServiceRunning
//                           ? '5s Background Logger: ACTIVE'
//                           : '5s Background Logger: INACTIVE',
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.bold,
//                         color: _isServiceRunning ? Colors.green[800] : Colors.grey[800],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 30),

//               // Control Buttons
//               SizedBox(
//                 width: 280,
//                 child: ElevatedButton.icon(
//                   onPressed: () async {
//                     await LocationService().printAllStoredData();
//                     if (!context.mounted) return;
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Check console for Hive data')),
//                     );
//                   },
//                   icon: const Icon(Icons.print),
//                   label: const Text('Print Today\'s Data Now'),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 12),

//               // Toggle Service Button
//               SizedBox(
//                 width: 280,
//                 child: ElevatedButton.icon(
//                   onPressed: _toggleService,
//                   icon: Icon(
//                     _isServiceRunning ? Icons.stop : Icons.play_arrow,
//                   ),
//                   label: Text(
//                     _isServiceRunning
//                         ? 'Stop 5s Background Service'
//                         : 'Start 5s Background Service',
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: Colors.white,
//                     backgroundColor: _isServiceRunning ? Colors.red : Colors.green,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 12),

//               // Legacy Test Notification Button
//               SizedBox(
//                 width: 280,
//                 child: ElevatedButton.icon(
//                   onPressed: () async {
//                     await NotificationService().testNotification();
//                     if (!context.mounted) return;
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Legacy notification scheduled in 5s')),
//                     );
//                   },
//                   icon: const Icon(Icons.notification_important),
//                   label: const Text('Legacy Notification (5s)'),
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: Colors.orange,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     side: const BorderSide(color: Colors.orange, width: 1),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// import 'dart:async';
// import 'dart:developer';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const MaterialApp(home: HomePage()));
// }

// // Global Plugin for Notifications
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   // Android Notification Channel Setup
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'my_service_channel',
//     'Service Channel',
//     importance: Importance.low,
//   );

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart, // This starts the background logic
//       autoStart: false, // We start it manually via the button
//       isForegroundMode: true,
//       notificationChannelId: 'my_service_channel',
//       initialNotificationTitle: 'Service Active',
//       initialNotificationContent: 'Preparing to log...',
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: false,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//   );
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   return true;
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // Initialize notifications inside the background process
//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
//   const DarwinInitializationSettings initializationSettingsIOS =
//       DarwinInitializationSettings();

//   await flutterLocalNotificationsPlugin.initialize(
//     settings: const InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     ),
//   );

//   // 5 SECOND TIMER
//   Timer.periodic(const Duration(seconds: 5), (timer) async {
//     // 1. Show Notification
//     await flutterLocalNotificationsPlugin.show(
//       id: 1,
//       title: 'Notification Triggered',
//       body: 'Check logs for hi msg',
//       notificationDetails: NotificationDetails(
//         android: AndroidNotificationDetails(
//           'my_service_channel',
//           'Service Channel',
//           importance: Importance.high,
//           priority: Priority.high,
//         ),
//         iOS: DarwinNotificationDetails(),
//       ),
//     );

//     // 2. PRINT LOG
//     // On iOS/Android, logs from background isolates appear in the "Logcat" or "Console"
//     log("hi msg"); // This prints in the background
//     print("hi msg");
//   });
// }

// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("5s Log Trigger")),
//       body: Center(
//         child: ElevatedButton(
//           child: const Text("Start 5s Notification & Log"),
//           onPressed: () async {
//             // Initialize and Start Service
//             await initializeService();
//             FlutterBackgroundService().startService();
//           },
//         ),
//       ),
//     );
//   }
// }

// last code
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   tz.initializeTimeZones();
//   // Fixed line below:
//   final String timeZoneName =
//       (await FlutterTimezone.getLocalTimezone()).identifier;

//   tz.setLocalLocation(tz.getLocation(timeZoneName));

//   runApp(const MaterialApp(home: HomePage()));
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   @override
//   void initState() {
//     super.initState();
//     _initNotifications();
//   }

//   void _initNotifications() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const DarwinInitializationSettings initializationSettingsIOS =
//         DarwinInitializationSettings(
//           requestAlertPermission: true,
//           requestBadgePermission: true,
//           requestSoundPermission: true,
//         );

//     const InitializationSettings initializationSettings =
//         InitializationSettings(
//           android: initializationSettingsAndroid,
//           iOS: initializationSettingsIOS,
//         );

//     await flutterLocalNotificationsPlugin.initialize(
//       settings: initializationSettings,
//     );
//   }

//   // THE MAGIC FUNCTION
//   Future<void> scheduleNotification() async {
//     // Schedule for 15 seconds from "Now"
//     final scheduledTime = tz.TZDateTime.now(
//       tz.local,
//     ).add(const Duration(seconds: 15));

//     await flutterLocalNotificationsPlugin.zonedSchedule(
//       id: 0,
//       title: 'Scheduled Notification',
//       body: 'This came 15 seconds after you closed the app!',
//       scheduledDate: scheduledTime,
//       notificationDetails: NotificationDetails(
//         android: AndroidNotificationDetails(
//           'main_channel',
//           'Main Channel',
//           importance: Importance.max,
//           priority: Priority.high,
//         ),
//         iOS: DarwinNotificationDetails(
//           presentAlert: true,
//           presentBadge: true,
//           presentSound: true,
//         ),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       // androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//     );

//     print("Notification scheduled to appear at: $scheduledTime");
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("iOS 15s Timer Test")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: () async {
//                 await scheduleNotification();
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text("Scheduled! Close the app now."),
//                   ),
//                 );
//               },
//               child: const Text("Start 15s Timer & Close App"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// flag code

// import 'dart:async';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';

// // Global notification plugin
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // 1. Initialize Timezone
//   tz.initializeTimeZones();
//   final String timeZoneName =
//       (await FlutterTimezone.getLocalTimezone()).identifier;
//   tz.setLocalLocation(tz.getLocation(timeZoneName));

//   // 2. Initialize Local Notifications for UI
//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
//   const DarwinInitializationSettings initializationSettingsIOS =
//       DarwinInitializationSettings(
//         requestAlertPermission: true,
//         requestBadgePermission: true,
//         requestSoundPermission: true,
//       );
//   await flutterLocalNotificationsPlugin.initialize(
//     settings: const InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     ),
//   );

//   // 3. Initialize Background Service
//   await initializeService();

//   runApp(const MaterialApp(home: HomePage()));
// }

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'my_foreground',
//     'Service Channel',
//     importance: Importance.low,
//   );

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: false,
//       isForegroundMode: true,
//       notificationChannelId: 'my_foreground',
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: false,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//   );
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   return true;
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // Logic for Android or iOS (Minimized)
//   Timer(const Duration(seconds: 15), () async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('noti_triggered', true);
//     print("BACKGROUND_LOG: 15 seconds reached. Flag set to TRUE.");
//     service.invoke('update_ui');
//     service.stopSelf();
//   });
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
//   bool isTriggered = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     loadFlag();

//     // Listen for background updates if app is open
//     FlutterBackgroundService().on('update_ui').listen((event) {
//       loadFlag();
//     });
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // When you re-open the app from a closed state, refresh the UI
//     if (state == AppLifecycleState.resumed) {
//       loadFlag();
//     }
//   }

//   Future<void> loadFlag() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     // Check 1: Did the background service set it?
//     bool backgroundValue = prefs.getBool('noti_triggered') ?? false;

//     // Check 2: Calculate based on Time (For iOS Closed State)
//     int? startTimeMillis = prefs.getInt('start_timestamp');
//     bool timePassed = false;
//     if (startTimeMillis != null) {
//       DateTime startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
//       if (DateTime.now().difference(startTime).inSeconds >= 15) {
//         timePassed = true;
//       }
//     }

//     setState(() {
//       isTriggered = backgroundValue || timePassed;
//     });
//   }

//   Future<void> start15sTask() async {
//     // 1. Reset everything
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('noti_triggered', false);
//     await prefs.setInt(
//       'start_timestamp',
//       DateTime.now().millisecondsSinceEpoch,
//     );
//     setState(() {
//       isTriggered = false;
//     });

//     // 2. Schedule Notification (This works on iOS even if app is closed)
//     final scheduledTime = tz.TZDateTime.now(
//       tz.local,
//     ).add(const Duration(seconds: 15));
//     await flutterLocalNotificationsPlugin.zonedSchedule(
//       id: 888,
//       title: 'Notification Success!',
//       body: '15 seconds passed. Flag is now TRUE.',
//       scheduledDate: scheduledTime,
//       notificationDetails: const NotificationDetails(
//         android: AndroidNotificationDetails('my_foreground', 'Service'),
//         iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//     );

//     // 3. Start Service (For Android and Logs)
//     FlutterBackgroundService().startService();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text("Scheduled for 15s. You can close the app now!"),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("iOS Terminated Flag Fix")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               "Notification Triggered?",
//               style: TextStyle(fontSize: 18),
//             ),
//             Text(
//               isTriggered ? "TRUE" : "FALSE",
//               style: TextStyle(
//                 fontSize: 60,
//                 fontWeight: FontWeight.bold,
//                 color: isTriggered ? Colors.green : Colors.red,
//               ),
//             ),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               onPressed: start15sTask,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 40,
//                   vertical: 15,
//                 ),
//               ),
//               child: const Text("START 15s TIMER"),
//             ),
//             TextButton(
//               onPressed: () async {
//                 SharedPreferences prefs = await SharedPreferences.getInstance();
//                 await prefs.clear();
//                 loadFlag();
//               },
//               child: const Text("Clear/Reset Everything"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// correct with background service package

// import 'dart:async';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';

// // Global notification plugin
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // 1. Initialize Timezone
//   tz.initializeTimeZones();
//   final String timeZoneName =
//       (await FlutterTimezone.getLocalTimezone()).identifier;
//   tz.setLocalLocation(tz.getLocation(timeZoneName));

//   // 2. Initialize Local Notifications for UI
//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
//   const DarwinInitializationSettings initializationSettingsIOS =
//       DarwinInitializationSettings(
//         requestAlertPermission: true,
//         requestBadgePermission: true,
//         requestSoundPermission: true,
//       );
//   await flutterLocalNotificationsPlugin.initialize(
//     settings: const InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     ),
//   );

//   // Request Android runtime notification permission (Android 13+)
//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.requestNotificationsPermission();

//   // 3. Initialize Background Service
//   await initializeService();

//   runApp(const MaterialApp(home: HomePage()));
// }

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   // Low importance channel for quiet persistent foreground service tray
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'my_foreground',
//     'Service Channel',
//     importance: Importance.max,
//   );

//   // High importance channel for heads-up alerts and sounds
//   const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
//     'alerts_channel_v2', // Alignment to alerts_channel_v2
//     'Alert Notifications',
//     importance: Importance.max,
//     showBadge: true,
//     playSound: true,
//     enableVibration: true,
//   );

//   final androidNotificationPlugin = flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >();

//   await androidNotificationPlugin?.createNotificationChannel(channel);
//   await androidNotificationPlugin?.createNotificationChannel(alertChannel);

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: false,
//       isForegroundMode: true,
//       notificationChannelId: 'my_foreground',
//       initialNotificationTitle: 'Notification Success!',
//       initialNotificationContent: '15 seconds passed. Flag is now TRUE.',
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: false,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//   );
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   return true;
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // Logic for Android or iOS (Minimized)
//   Timer(const Duration(seconds: 15), () async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('noti_triggered', true);
//     print("BACKGROUND_LOG: 15 seconds reached. Flag set to TRUE.");
//     service.invoke('update_ui');
//     service.stopSelf();
//   });
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
//   bool isTriggered = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     loadFlag();

//     // Listen for background updates if app is open
//     FlutterBackgroundService().on('update_ui').listen((event) {
//       loadFlag();
//     });
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // When you re-open the app from a closed state, refresh the UI
//     if (state == AppLifecycleState.resumed) {
//       loadFlag();
//     }
//   }

//   Future<void> loadFlag() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     // Check 1: Did the background service set it?
//     bool backgroundValue = prefs.getBool('noti_triggered') ?? false;

//     // Check 2: Calculate based on Time (For iOS Closed State)
//     int? startTimeMillis = prefs.getInt('start_timestamp');
//     bool timePassed = false;
//     if (startTimeMillis != null) {
//       DateTime startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
//       if (DateTime.now().difference(startTime).inSeconds >= 15) {
//         timePassed = true;
//       }
//     }

//     setState(() {
//       isTriggered = backgroundValue || timePassed;
//     });
//   }

//   Future<void> start15sTask() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('noti_triggered', false);
//     await prefs.setInt(
//       'start_timestamp',
//       DateTime.now().millisecondsSinceEpoch,
//     );
//     setState(() {
//       isTriggered = false;
//     });

//     // 2. Schedule Notification (This works on iOS even if app is closed)
//     final scheduledTime = tz.TZDateTime.now(
//       tz.local,
//     ).add(const Duration(seconds: 15));
//     await flutterLocalNotificationsPlugin.zonedSchedule(
//       id: DateTime.now().millisecondsSinceEpoch + 100,
//       title: 'Notification Success!',
//       body: '15 seconds passed. Flag is now TRUE.',
//       scheduledDate: scheduledTime,
//       notificationDetails: const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'alerts_channel_v2', // Changed ID to bypass Android cache
//           'Alert Notifications',
//           importance: Importance.max,
//           priority: Priority.high,
//           playSound: true,
//         ),
//         iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//     );

//     // 3. Start Service (For Android and Logs)
//     FlutterBackgroundService().startService();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text("Scheduled for 15s. You can close the app now!"),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("iOS Terminated Flag Fix")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               "Notification Triggered?",
//               style: TextStyle(fontSize: 18),
//             ),
//             Text(
//               isTriggered ? "TRUE" : "FALSE",
//               style: TextStyle(
//                 fontSize: 60,
//                 fontWeight: FontWeight.bold,
//                 color: isTriggered ? Colors.green : Colors.red,
//               ),
//             ),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               onPressed: start15sTask,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 40,
//                   vertical: 15,
//                 ),
//               ),
//               child: const Text("START 15s TIMER"),
//             ),
//             TextButton(
//               onPressed: () async {
//                 SharedPreferences prefs = await SharedPreferences.getInstance();
//                 await prefs.clear();
//                 loadFlag();
//               },
//               child: const Text("Clear/Reset Everything"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// workmanager with api

// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:workmanager/workmanager.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';

// // Unique Task Name
// const String taskName = "com.example.apiTask";

// // 1. TOP LEVEL CALLBACK DISPATCHER (Wakes up when app is closed)
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     print("Native: Workmanager Task Started: $task");

//     try {
//       // A. CALL YOUR API
//       final response = await http.post(
//         Uri.parse('https://jsonplaceholder.typicode.com/posts'),
//         body: {
//           'status': 'Background Triggered',
//           'time': DateTime.now().toString(),
//         },
//       );
//       log("API Response Code: ${response.statusCode}");

//       // B. SET FLAG IN SHARED PREFERENCES
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setBool('noti_triggered', true);

//       print("BACKGROUND LOG: Flag set to TRUE and API Called Successfully");
//     } catch (e) {
//       print("BACKGROUND ERROR: $e");
//     }

//     return Future.value(true);
//   });
// }

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // 2. Initialize Timezone
//   tz.initializeTimeZones();
//   final String timeZoneName =
//       (await FlutterTimezone.getLocalTimezone()).identifier;
//   tz.setLocalLocation(tz.getLocation(timeZoneName));

//   // 3. Initialize Notifications
//   const AndroidInitializationSettings androidSettings =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
//   const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
//     requestAlertPermission: true,
//     requestBadgePermission: true,
//     requestSoundPermission: true,
//     defaultPresentAlert: true,
//     defaultPresentSound: true,
//   );
//   await flutterLocalNotificationsPlugin.initialize(
//     settings: const InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     ),
//   );

//   // 4. Initialize Workmanager
//   await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

//   runApp(const MaterialApp(home: HomePage()));
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
//   bool isTriggered = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     loadFlag();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       loadFlag();
//     }
//   }

//   Future<void> loadFlag() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     // Check 1: Did Workmanager set it?
//     bool backgroundValue = prefs.getBool('noti_triggered') ?? false;

//     // Check 2: Timestamp Fallback (For iOS exact timing)
//     int? startTimeMillis = prefs.getInt('start_timestamp');
//     bool timePassed = false;
//     if (startTimeMillis != null) {
//       DateTime startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
//       if (DateTime.now().difference(startTime).inSeconds >= 15) {
//         timePassed = true;
//       }
//     }

//     setState(() {
//       isTriggered = backgroundValue || timePassed;
//     });
//   }

//   Future<void> start15sTask() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('noti_triggered', false);
//     await prefs.setInt(
//       'start_timestamp',
//       DateTime.now().millisecondsSinceEpoch,
//     );
//     setState(() {
//       isTriggered = false;
//     });

//     // A. SCHEDULE LOCAL NOTIFICATION (Reliable for 15s on all platforms)
//     final scheduledTime = tz.TZDateTime.now(
//       tz.local,
//     ).add(const Duration(seconds: 15));
//     await flutterLocalNotificationsPlugin.zonedSchedule(
//       id: 888,
//       title: 'API Task Triggered',
//       body: 'The API call is happening in the background!',
//       scheduledDate: scheduledTime,
//       notificationDetails: const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'alert_ch',
//           'Alerts',
//           importance: Importance.max,
//           priority: Priority.high,
//         ),
//         iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       //uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
//     );

//     // B. SCHEDULE WORKMANAGER TASK (For API call and Flag)
//     // Note: On Android, this will be roughly 15s. On iOS, it depends on the OS.
//     await Workmanager().registerOneOffTask(
//       "1",
//       taskName,
//       initialDelay: const Duration(seconds: 15),
//       constraints: Constraints(
//         networkType: NetworkType.connected,
//       ), // Ensure internet is available
//     );

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Task & Notification Scheduled!")),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Workmanager + API")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text("Notification/API Triggered?", style: TextStyle(fontSize: 18)),
//             Text(
//               isTriggered ? "TRUE" : "FALSE",
//               style: TextStyle(
//                 fontSize: 60,
//                 fontWeight: FontWeight.bold,
//                 color: isTriggered ? Colors.green : Colors.red,
//               ),
//             ),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               onPressed: start15sTask,
//               child: const Text("START 15s API TASK"),
//             ),
//             TextButton(
//               onPressed: () async {
//                 SharedPreferences prefs = await SharedPreferences.getInstance();
//                 await prefs.clear();
//                 loadFlag();
//               },
//               child: const Text("Reset Everything"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:workmanager/workmanager.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';

// const String taskUniqueName = "com.example.apiTaskHive";

// // 1. Background Task Logic
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     // Initialize Hive inside the background isolate
//     await Hive.initFlutter();
//     var box = await Hive.openBox('settings_box');

//     try {
//       // A. Call your API and capture the response
//       final response = await http.post(
//         Uri.parse('https://jsonplaceholder.typicode.com/posts'),
//         body: {'status': 'Triggered', 'time': DateTime.now().toString()},
//       );

//       // Print status code and response body in the background logs
//       print("BACKGROUND API SUCCESS: Status Code ${response.statusCode}");
//       print("BACKGROUND API RESPONSE DATA: ${response.body}");

//       // B. Save flag to Hive (Directly from background)
//       // This is the ONLY place we set it to true
//       await box.put('isTriggered', true);
//     } catch (e) {
//       print("BACKGROUND API ERROR: $e");
//     }

//     return Future.value(true);
//   });
// }

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Hive for the UI
//   await Hive.initFlutter();
//   await Hive.openBox('settings_box');

//   // Initialize Timezones
//   tz.initializeTimeZones();
//   final String timeZoneName =
//       (await FlutterTimezone.getLocalTimezone()).identifier;
//   tz.setLocalLocation(tz.getLocation(timeZoneName));

//   // Initialize Notifications
//   const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//   const iosSettings = DarwinInitializationSettings(
//     requestAlertPermission: true,
//     requestBadgePermission: true,
//     requestSoundPermission: true,
//   );
//   await flutterLocalNotificationsPlugin.initialize(
//     settings: const InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     ),
//   );

//   // 1. Request Android runtime notification permission (Android 13+)
// final androidPlugin = flutterLocalNotificationsPlugin
//     .resolvePlatformSpecificImplementation<
//       AndroidFlutterLocalNotificationsPlugin
//     >();
// await androidPlugin?.requestNotificationsPermission();

//   // 2. Register the high-importance notification channel
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'ch_id',
//     'ch_name',
//     importance: Importance.max,
//     playSound: true,
//     enableVibration: true,
//   );
//   await androidPlugin?.createNotificationChannel(channel);

//   // Initialize Workmanager
//   await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

//   runApp(const MaterialApp(home: HomePage()));
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       // Re-build UI when app comes back from background to show Hive value
//       setState(() {});
//     }
//   }

//   Future<void> startTask() async {
//     print("DEBUG: startTask button tapped!");
//     var box = Hive.box('settings_box');

//     try {
//       // Reset flag in Hive before starting
//       print("DEBUG: Resetting Hive flag 'isTriggered' to false...");
//       await box.put('isTriggered', false);
//       setState(() {});

//       // 1. Calculate 9:00 PM (21:00) in local timezone
//       final now = tz.TZDateTime.now(tz.local);
//       var scheduledTime = tz.TZDateTime(
//         tz.local,
//         now.year,
//         now.month,
//         now.day,
//         21, // 21 = 9:00 PM (24-hour format). TIP: Change this to test right now!
//         0, // 0 minutes
//         0, // 0 seconds
//       );

//       // If 9:00 PM has already passed today, schedule it for 9:00 PM tomorrow
//       if (scheduledTime.isBefore(now)) {
//         scheduledTime = scheduledTime.add(const Duration(days: 1));
//         print(
//           "DEBUG: 9:00 PM already passed today. Scheduled for tomorrow: $scheduledTime",
//         );
//       } else {
//         print("DEBUG: Scheduled for today at: $scheduledTime");
//       }

//       print("DEBUG: Scheduling daily periodic local notification...");

//       await flutterLocalNotificationsPlugin.zonedSchedule(
//         id: 101,
//         title: 'Daily Task Alert',
//         body: 'It is 9:00 PM! Your daily task is running.',
//         scheduledDate: scheduledTime,
//         notificationDetails: const NotificationDetails(
//           android: AndroidNotificationDetails(
//             'ch_id',
//             'ch_name',
//             importance: Importance.max,
//             priority: Priority.high,
//           ),
//           iOS: DarwinNotificationDetails(
//             presentAlert: true,
//             presentSound: true,
//           ),
//         ),
//         androidScheduleMode: AndroidScheduleMode
//             .exactAllowWhileIdle, // Bypasses Android 14 exact alarm block!
//         matchDateTimeComponents:
//             DateTimeComponents.time, // ⚡ REPEATS DAILY AT 9:00 PM!
//       );
//       print("DEBUG: Daily notification scheduled successfully!");

//       // 2. Schedule Workmanager (For Background API Call & Hive update)
//       // Note: On Android, we schedule a daily periodic task.
//       print("DEBUG: Scheduling Workmanager periodic background task...");
//       await Workmanager().registerPeriodicTask(
//         "periodic-1",
//         taskUniqueName,
//         frequency: const Duration(hours: 24), // Triggers once every 24 hours
//         constraints: Constraints(
//           networkType:
//               NetworkType.connected, // Only run when connected to internet
//         ),
//       );
//       print("DEBUG: Workmanager periodic task registered successfully!");

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             "Daily 9:00 PM task scheduled! Next run: $scheduledTime",
//           ),
//         ),
//       );
//     } catch (e, stacktrace) {
//       print("DEBUG ERROR Storing/Scheduling: $e");
//       print("DEBUG STACKTRACE: $stacktrace");
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error: $e")));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // We use ValueListenableBuilder so UI updates automatically when Hive changes
//     return Scaffold(
//       appBar: AppBar(title: const Text("Workmanager + Hive Flag")),
//       body: Center(
//         child: ValueListenableBuilder(
//           valueListenable: Hive.box('settings_box').listenable(),
//           builder: (context, box, widget) {
//             // Read ONLY from Hive
//             bool isTriggered = box.get('isTriggered', defaultValue: false);

//             return Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text("Status from Hive Storage:"),
//                 Text(
//                   isTriggered ? "TRUE" : "FALSE",
//                   style: TextStyle(
//                     fontSize: 80,
//                     fontWeight: FontWeight.bold,
//                     color: isTriggered ? Colors.green : Colors.red,
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//                 ElevatedButton(
//                   onPressed: startTask,
//                   child: const Text("START 15s TASK"),
//                 ),
//                 TextButton(
//                   onPressed: () => box.put('isTriggered', false),
//                   child: const Text("Reset Flag Manually"),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// lst

// import 'dart:async';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';
// import 'package:http/http.dart' as http;

// // Global notification plugin
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   tz.initializeTimeZones();
//   final String timeZoneName =
//       (await FlutterTimezone.getLocalTimezone()).identifier;
//   tz.setLocalLocation(tz.getLocation(timeZoneName));

//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
//   const DarwinInitializationSettings initializationSettingsIOS =
//       DarwinInitializationSettings(
//         requestAlertPermission: true,
//         requestBadgePermission: true,
//         requestSoundPermission: true,
//       );
//   await flutterLocalNotificationsPlugin.initialize(
//     settings: const InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     ),
//   );

// final androidPlugin = flutterLocalNotificationsPlugin
//     .resolvePlatformSpecificImplementation<
//       AndroidFlutterLocalNotificationsPlugin
//     >();
// await androidPlugin?.requestNotificationsPermission();

//   await initializeService();

//   runApp(const MaterialApp(home: HomePage()));
// }

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'my_foreground',
//     'Service Channel',
//     importance: Importance.low,
//   );

//   const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
//     'alerts_channel_v2',
//     'Alert Notifications',
//     importance: Importance.max,
//     showBadge: true,
//     playSound: true,
//     enableVibration: true,
//   );

// final androidNotificationPlugin = flutterLocalNotificationsPlugin
//     .resolvePlatformSpecificImplementation<
//       AndroidFlutterLocalNotificationsPlugin
//     >();
// await androidNotificationPlugin?.requestNotificationsPermission();

//   if (androidNotificationPlugin != null) {
//     await androidNotificationPlugin.createNotificationChannel(channel);
//     await androidNotificationPlugin.createNotificationChannel(alertChannel);
//   }
//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: false,
//       isForegroundMode: true,
//       notificationChannelId: 'my_foreground',
//       initialNotificationTitle: 'Task Started',
//       initialNotificationContent: 'Waiting 15 seconds...',
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: false,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//   );
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   return true;
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // ✅ FIX: Listen for stopService so Clear Everything can kill this service
//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });

//   Timer(const Duration(seconds: 15), () async {
//     // 1. CALL YOUR API HERE
//     try {
//       print("BACKGROUND_LOG: Calling API...");
//       final response = await http.post(
//         Uri.parse('https://jsonplaceholder.typicode.com/posts'),
//         body: {'title': 'Notification Triggered', 'body': 'App was closed'},
//       );
//       print("BACKGROUND_LOG: API Response Status: ${response.statusCode}");
//       print("BACKGROUND_LOG: API Data: ${response.body}");
//     } catch (e) {
//       print("BACKGROUND_LOG: API Error: $e");
//     }

//     // 2. SET THE FLAG
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('noti_triggered', true);

//     print("BACKGROUND_LOG: 15 seconds reached. Flag set to TRUE.");

//     // 3. Update UI
//     service.invoke('update_ui');

//     // Stop the service as the task is finished
//     service.stopSelf();
//   });
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
//   bool isTriggered = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     loadFlag();

//     FlutterBackgroundService().on('update_ui').listen((event) {
//       loadFlag();
//     });
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       loadFlag();
//     }
//   }

//   Future<void> loadFlag() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     bool backgroundValue = prefs.getBool('noti_triggered') ?? false;

//     int? startTimeMillis = prefs.getInt('start_timestamp');
//     bool timePassed = false;
//     if (startTimeMillis != null) {
//       DateTime startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
//       if (DateTime.now().difference(startTime).inSeconds >= 15) {
//         timePassed = true;
//       }
//     }

//     setState(() {
//       isTriggered = backgroundValue || timePassed;
//     });
//   }

//   Future<void> start15sTask() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     // ✅ FIX 1: Cancel the previously scheduled notification using stored ID
//     int? oldId = prefs.getInt('notification_id');
//     if (oldId != null) {
//       await flutterLocalNotificationsPlugin.cancel(id: oldId);
//     }

//     // ✅ FIX 2: Stop any previously running background service
//     FlutterBackgroundService().invoke('stopService');
//     await Future.delayed(const Duration(milliseconds: 300));

//     // ✅ FIX 3: Generate new ID and STORE it so we can cancel later
//     final int newId = DateTime.now().millisecondsSinceEpoch % 100000;

//     await prefs.setBool('noti_triggered', false);
//     await prefs.setInt(
//       'start_timestamp',
//       DateTime.now().millisecondsSinceEpoch,
//     );
//     await prefs.setInt('notification_id', newId); // STORE THE ID

//     setState(() => isTriggered = false);

//     final scheduledTime = tz.TZDateTime.now(
//       tz.local,
//     ).add(const Duration(seconds: 15));

//     await flutterLocalNotificationsPlugin.zonedSchedule(
//       id: newId, // USE THE STORED ID
//       title: 'API Task Triggered!',
//       body: 'The API was called in the background.',
//       scheduledDate: scheduledTime,
//       notificationDetails: const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'alerts_channel_v2',
//           'Alert Notifications',
//           importance: Importance.max,
//           priority: Priority.high,
//           playSound: true,
//         ),
//         iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//     );

//     // START THE BACKGROUND SERVICE TIMER
//     FlutterBackgroundService().startService();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Scheduled! API will be called in 15s.")),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("API Background Trigger")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text("API & Notification Status:"),
//             Text(
//               isTriggered ? "TRUE (API CALLED)" : "FALSE",
//               style: TextStyle(
//                 fontSize: 40,
//                 fontWeight: FontWeight.bold,
//                 color: isTriggered ? Colors.green : Colors.red,
//               ),
//             ),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               onPressed: start15sTask,
//               child: const Text("START 15s API TASK"),
//             ),
//             TextButton(
//               onPressed: () async {
//                 SharedPreferences prefs = await SharedPreferences.getInstance();

//                 // ✅ FIX 4: Cancel the stored notification before clearing prefs
//                 int? oldId = prefs.getInt('notification_id');
//                 if (oldId != null) {
//                   await flutterLocalNotificationsPlugin.cancel(id: oldId);
//                 }

//                 // ✅ FIX 5: Stop background service before clearing
//                 FlutterBackgroundService().invoke('stopService');

//                 await prefs.clear();
//                 loadFlag();
//               },
//               child: const Text("Clear Everything"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  final String timeZoneName =
      (await FlutterTimezone.getLocalTimezone()).identifier;
  tz.setLocalLocation(tz.getLocation(timeZoneName));

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    ),
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await androidPlugin?.requestNotificationsPermission();

  await initializeService();

  runApp(const MaterialApp(home: HomePage()));
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_silent_foreground', // ✅ CHANGED ID TO BYPASS ANDROID CACHE
    'Service Channel',
    importance: Importance.low, // ✅ LOW so it doesn't pop up instantly
  );

  const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
    'alerts_channel_v2',
    'Alert Notifications',
    importance: Importance.max,
    showBadge: true,
    playSound: true,
    enableVibration: true,
  );

  // ✅ Safe null check
  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await androidPlugin?.requestNotificationsPermission();

  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(channel);
    await androidPlugin.createNotificationChannel(alertChannel);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'my_silent_foreground', // ✅ USE NEW SILENT CHANNEL
      initialNotificationTitle: 'Background Service', // Just a quiet tray label
      initialNotificationContent: 'Monitoring...',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // ✅ Allow UI to stop this service (used by Clear button and re-start)
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Calculate time until 6:00 PM
  final now = DateTime.now();
  var targetTime = DateTime(now.year, now.month, now.day, 18, 0, 0); // 6:00 PM
  if (targetTime.isBefore(now)) {
    targetTime = targetTime.add(const Duration(days: 1)); // Next day 6:00 PM
  }
  final delay = targetTime.difference(now);

  print(
    "BACKGROUND_LOG: Scheduled API for 6:00 PM (delay: ${delay.inMinutes} minutes)",
  );

  Timer(delay, () async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('noti_triggered', true);
    print("BACKGROUND_LOG: 6:00 PM reached. Flag set to TRUE.");
    service.invoke('update_ui');
    service.stopSelf();
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool isTriggered = false;

  // ✅ Fixed notification ID — small int, not a timestamp
  static const int _notificationId = 888;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadFlag();

    FlutterBackgroundService().on('update_ui').listen((event) {
      loadFlag();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadFlag();
    }
  }

  Future<void> loadFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool backgroundValue = prefs.getBool('noti_triggered') ?? false;

    int? startTimeMillis = prefs.getInt('start_timestamp');
    bool timePassed = false;
    if (startTimeMillis != null) {
      DateTime startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
      if (DateTime.now().difference(startTime).inSeconds >= 15) {
        timePassed = true;
      }
    }

    setState(() {
      isTriggered = backgroundValue || timePassed;
    });
  }

  Future<void> scheduleDaily6PMTask() async {
    // ✅ STEP 1: Cancel any previously scheduled notification first
    await flutterLocalNotificationsPlugin.cancel(id: _notificationId);

    // ✅ STEP 2: Stop any running background service first
    FlutterBackgroundService().invoke('stopService');
    await Future.delayed(const Duration(milliseconds: 300));

    // ✅ STEP 3: Reset prefs
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('noti_triggered', false);
    await prefs.setInt(
      'start_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );

    setState(() => isTriggered = false);

    // ✅ STEP 4: Schedule notification with fixed small int ID at 6:00 PM
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      17, // 6:00 PM
      10,
    );
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1)); // Next day
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: _notificationId, // ✅ Always same small int ID
      title: 'Daily Task Success!',
      body: 'It is 6:00 PM! Data updated.',
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'alerts_channel_v2',
          'Alert Notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time, // ✅ REPEATS EVERY DAY AT 6 PM
    );

    // ✅ STEP 5: Start background service
    FlutterBackgroundService().startService();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Scheduled for 6:00 PM daily. You can close the app!"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("iOS Terminated Flag Fix")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Notification Triggered?",
              style: TextStyle(fontSize: 18),
            ),
            Text(
              isTriggered ? "TRUE" : "FALSE",
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: isTriggered ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: scheduleDaily6PMTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: const Text("SCHEDULE 6:00 PM TASK"),
            ),
            TextButton(
              onPressed: () async {
                // ✅ Cancel notification + stop service before clearing
                await flutterLocalNotificationsPlugin.cancel(
                  id: _notificationId,
                );
                FlutterBackgroundService().invoke('stopService');

                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                loadFlag();
              },
              child: const Text("Clear/Reset Everything"),
            ),
          ],
        ),
      ),
    );
  }
}




// 19 may


// import 'dart:async';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize timezones
//   tz.initializeTimeZones();
//   final String timeZoneName =
//       (await FlutterTimezone.getLocalTimezone()).identifier;
//   tz.setLocalLocation(tz.getLocation(timeZoneName));

//   // Initialize notifications
//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
//   const DarwinInitializationSettings initializationSettingsIOS =
//       DarwinInitializationSettings(
//         requestAlertPermission: true,
//         requestBadgePermission: true,
//         requestSoundPermission: true,
//       );
//   await flutterLocalNotificationsPlugin.initialize(
//     settings: const InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     ),
//   );

//   // Initialize Background Service
//   await initializeService();

//   runApp(const MaterialApp(home: HomePage()));
// }

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'my_silent_foreground',
//     'Service Channel',
//     importance: Importance.low,
//   );

//   const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
//     'alerts_channel_v2',
//     'Alert Notifications',
//     importance: Importance.max,
//     showBadge: true,
//     playSound: true,
//     enableVibration: true,
//   );

//   final androidPlugin = flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >();
//   await androidPlugin?.requestNotificationsPermission();

//   if (androidPlugin != null) {
//     await androidPlugin.createNotificationChannel(channel);
//     await androidPlugin.createNotificationChannel(alertChannel);
//   }

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: false,
//       isForegroundMode: true,
//       notificationChannelId: 'my_silent_foreground',
//       initialNotificationTitle: '10:24 Notification',
//       initialNotificationContent: 'Notification at 10:24',
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: false,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//   );
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   return true;
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });

//   // Calculate target time (10:00 AM)
//   final now = DateTime.now();
//   var targetTime = DateTime(now.year, now.month, now.day, 10, 42, 0);
//   if (targetTime.isBefore(now)) {
//     targetTime = targetTime.add(const Duration(days: 1));
//   }
//   final delay = targetTime.difference(now);

//   Timer(delay, () async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('noti_triggered', true);
//     service.invoke('update_ui');
//     service.stopSelf();
//   });
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
//   bool isTriggered = false;
//   static const int _notificationId = 888;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     loadFlag();

//     FlutterBackgroundService().on('update_ui').listen((event) {
//       loadFlag();
//     });
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       loadFlag();
//     }
//   }

//   Future<void> loadFlag() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       isTriggered = prefs.getBool('noti_triggered') ?? false;
//     });
//   }

//   Future<void> scheduleDaily1000AMTask() async {
//     // On Android 12+ (API 31+), SCHEDULE_EXACT_ALARM requires the user to
//     // grant "Alarms & Reminders" in Settings. Without it Android silently
//     // downgrades to an inexact alarm and fires at the wrong time.
//     final androidPlugin = flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >();
//     if (androidPlugin != null) {
//       final bool canScheduleExact =
//           await androidPlugin.canScheduleExactNotifications() ?? true;
//       if (!canScheduleExact) {
//         // Opens Settings > Apps > Special app access > Alarms & reminders
//         await androidPlugin.requestExactAlarmsPermission();
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text(
//                 'Grant "Alarms & Reminders" permission, then tap Schedule again.',
//               ),
//               duration: Duration(seconds: 5),
//             ),
//           );
//         }
//         return;
//       }
//     }

//     // 1. Reset notification & background service
//     await flutterLocalNotificationsPlugin.cancel(id: _notificationId);
//     FlutterBackgroundService().invoke('stopService');
//     await Future.delayed(const Duration(milliseconds: 300));

//     // 2. Reset flag
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('noti_triggered', false);
//     setState(() => isTriggered = false);

//     // 3. Calculate 10:00 AM for scheduling
//     final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
//     var scheduledTime = tz.TZDateTime(
//       tz.local,
//       now.year,
//       now.month,
//       now.day,
//       10, // 10:24 AM
//       42,
//     );
//     if (scheduledTime.isBefore(now)) {
//       scheduledTime = scheduledTime.add(const Duration(days: 1));
//     }

//     // 4. Schedule local notification
//     await flutterLocalNotificationsPlugin.zonedSchedule(
//       id: _notificationId,
//       title: 'title test',
//       body: 'body test',
//       scheduledDate: scheduledTime,
//       notificationDetails: NotificationDetails(
//         android: AndroidNotificationDetails(
//           'alerts_channel_v2',
//           'Alert Notifications',
//           importance: Importance.max,
//           priority: Priority.high,
//           playSound: true,
//         ),
//         iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );

//     // 5. Start background service for state sync
//     FlutterBackgroundService().startService();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text("Scheduled for 10:24 AM daily. You can close the app!"),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("iOS Terminated Flag Fix")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               "Notification Triggered?",
//               style: TextStyle(fontSize: 18),
//             ),
//             Text(
//               isTriggered ? "TRUE" : "FALSE",
//               style: TextStyle(
//                 fontSize: 60,
//                 fontWeight: FontWeight.bold,
//                 color: isTriggered ? Colors.green : Colors.red,
//               ),
//             ),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               onPressed: scheduleDaily1000AMTask,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 40,
//                   vertical: 15,
//                 ),
//               ),
//               child: const Text("SCHEDULE 10:24 AM TASK"),
//             ),
//             TextButton(
//               onPressed: () async {
//                 await flutterLocalNotificationsPlugin.cancel(
//                   id: _notificationId,
//                 );
//                 FlutterBackgroundService().invoke('stopService');

//                 final prefs = await SharedPreferences.getInstance();
//                 await prefs.clear();
//                 loadFlag();
//               },
//               child: const Text("Clear/Reset Everything"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// import 'dart:async';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // 1. Initialize Notifications
//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
//   const DarwinInitializationSettings initializationSettingsIOS =
//       DarwinInitializationSettings();
//   await flutterLocalNotificationsPlugin.initialize(
//     settings: const InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     ),
//   );

//   // 2. Initialize Background Service
//   await initializeService();

//   runApp(const MaterialApp(home: HomePage()));
// }

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   // Create the notification channel required for the foreground service
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'service_channel', // Must match notificationChannelId
//     'Service Channel',
//     importance:
//         Importance.low, // low importance so it does not pop up with sound
//   );

//   final androidPlugin = flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >();

//   if (androidPlugin != null) {
//     await androidPlugin.createNotificationChannel(channel);
//   }

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'service_channel',
//       initialNotificationTitle: 'Task Monitor',
//       initialNotificationContent: 'Monitoring for 11:00 AM',
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: true,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//   );
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async => true;

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });

//   // Calculate delay until target time (11:00 AM)
//   final now = DateTime.now();
//   var targetTime = DateTime(
//     now.year,
//     now.month,
//     now.day,
//     11,
//     02,
//     0,
//   ); // 11:00 AM
//   if (targetTime.isBefore(now)) {
//     targetTime = targetTime.add(const Duration(days: 1)); // Next day 11:00 AM
//   }
//   final delay = targetTime.difference(now);

//   // One-shot timer: fires EXACTLY at 11:00 AM
//   Timer(delay, () async {
//     final prefs = await SharedPreferences.getInstance();

//     // 1. Set variable to true
//     await prefs.setBool('noti_triggered', true);

//     // 2. Show the Notification
//     flutterLocalNotificationsPlugin.show(
//       id: 888,
//       title: '11:02 AM Alert',
//       body: 'The task variable is now TRUE.',
//       notificationDetails: const NotificationDetails(
//         android: AndroidNotificationDetails('service_channel', 'Service'),
//       ),
//     );

//     // 3. Tell the UI to update if the app is open
//     service.invoke('update_ui', {"status": true});

//     // 4. Stop the service since the job is complete
//     service.stopSelf();
//   });
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
//   bool isTriggered = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     loadFlag();

//     // Listen for updates from the background service
//     FlutterBackgroundService().on('update_ui').listen((event) {
//       if (mounted) {
//         setState(() {
//           isTriggered = event?['status'] ?? false;
//         });
//       }
//     });
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       loadFlag(); // Check logic when user returns
//     }
//   }

//   Future<void> loadFlag() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       isTriggered = prefs.getBool('noti_triggered') ?? false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Background Service 11:02 AM")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text("Is variable TRUE?"),
//             Text(
//               isTriggered ? "TRUE" : "FALSE",
//               style: TextStyle(
//                 fontSize: 60,
//                 fontWeight: FontWeight.bold,
//                 color: isTriggered ? Colors.green : Colors.red,
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text("The service is waiting for 11:02 AM."),
//           ],
//         ),
//       ),
//     );
//   }
// }


// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:workmanager/workmanager.dart';

// const String taskName = "notificationTask";

// // Top-level callback dispatcher for Workmanager background isolate.
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((name, inputData) async {
//     // 1. Persist the state in SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('is_triggered', true);

//     // 2. Trigger notification
//     final localNotifications = FlutterLocalNotificationsPlugin();
//     await localNotifications.initialize(
//       const InitializationSettings(
//         android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//         iOS: DarwinInitializationSettings(),
//       ),
//     );

//     await localNotifications.show(
//       1,
//       "🚀 Background Task Done",
//       "Notification triggered! Variable is now set to TRUE.",
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'work_channel',
//           'Workmanager Channel',
//           importance: Importance.max,
//           priority: Priority.high,
//         ),
//         iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
//       ),
//     );

//     return true;
//   });
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // Initialize Workmanager
//   await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  
//   runApp(const MaterialApp(home: HomePage(), debugShowCheckedModeBanner: false));
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   bool _isTriggered = false;
//   Timer? _timer;

//   @override
//   void initState() {
//     super.initState();
//     _checkState();
//     // Poll SharedPreferences every 1 second to catch background updates
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) => _checkState());
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   Future<void> _checkState() async {
//     final prefs = await SharedPreferences.getInstance();
    
//     // CRITICAL FIX: Reload shared preferences from disk.
//     // Background isolate edits are not cached by the main UI isolate unless we force a reload.
//     await prefs.reload(); 
    
//     final currentVal = prefs.getBool('is_triggered') ?? false;
//     if (_isTriggered != currentVal) {
//       setState(() => _isTriggered = currentVal);
//     }
//   }

//   Future<void> _triggerTask() async {
    // final notifications = FlutterLocalNotificationsPlugin();
    // await notifications
    //     .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    //     ?.requestNotificationsPermission();

//     // Reset local variable state before scheduling
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('is_triggered', false);
//     setState(() => _isTriggered = false);

//     // Register immediate one-off task (delayed by 5 seconds for simulation)
//     await Workmanager().registerOneOffTask(
//       "uniqueTaskID",
//       taskName,
//       initialDelay: const Duration(seconds: 5),
//     );
//   }

//   Future<void> _resetState() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('is_triggered', false);
//     await Workmanager().cancelAll();
//     setState(() => _isTriggered = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0F172A),
//       appBar: AppBar(
//         title: const Text("Simple Workmanager Notification"),
//         backgroundColor: const Color(0xFF1E293B),
//         centerTitle: true,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 "Triggered State:",
//                 style: TextStyle(color: Colors.slate.shade400, fontSize: 18),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 _isTriggered ? "TRUE" : "FALSE",
//                 style: TextStyle(
//                   color: _isTriggered ? Colors.tealAccent : Colors.redAccent,
//                   fontSize: 72,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 40),
//               ElevatedButton.icon(
//                 onPressed: _triggerTask,
//                 icon: const Icon(Icons.play_arrow),
//                 label: const Text("Trigger Task (5s Delay)"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.indigoAccent,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextButton.icon(
//                 onPressed: _resetState,
//                 icon: const Icon(Icons.refresh, color: Colors.redAccent),
//                 label: const Text("Reset to FALSE", style: TextStyle(color: Colors.redAccent)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
