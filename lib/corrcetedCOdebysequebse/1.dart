import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

const String kStatusPrefix = 'task_status_';
const String kTargetPrefix = 'task_target_';
final notifications = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('add_task').listen((event) async {
    final int id = event!['id'];
    final int seconds = event['delay'];

    // Wait for the exact time
    await Future.delayed(Duration(seconds: seconds));

    // Update variable on disk
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$kStatusPrefix$id', true);

    // Notify UI if app is open
    service.invoke('on_triggered', {'id': id});

    // EXACT SYNCHRONIZATION FOR ANDROID
    // Android OS delays exact alarms. So if the app is open (background service alive),
    // we manually fire the notification here instantly to avoid jitter!
    if (Platform.isAndroid) {
      final localNotifications = FlutterLocalNotificationsPlugin();
      await localNotifications.cancel(id: id); // Cancel the slow OS alarm
      await localNotifications.show(
        id: id,
        title: "🚀 Task $id Done",
        body: "Variable is now TRUE.",
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'ch_id',
            'Alerts',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = FlutterLocalNotificationsPlugin();
  await notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  // 1. Setup Timezones & Notifications
  tz.initializeTimeZones();
  final String timeZoneName =
      (await FlutterTimezone.getLocalTimezone()).identifier;
  tz.setLocalLocation(tz.getLocation(timeZoneName));
  await notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestSoundPermission: true,
      ),
    ),
  );

  // Create the notification channel to prevent Android 14 Foreground Service crash
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'Foreground Service', // title
    description: 'This channel is used for background tasks.',
    importance: Importance
        .low, // low is enough to not make a sound, but required for foreground services
  );

  await notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // 2. Setup Background Service
  await FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: false, // MUST BE TRUE to run reliably in background!
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Task running',
      initialNotificationContent: 'Waiting...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: (_) => true,
    ),
  );

  runApp(
    const MaterialApp(home: HomePage(), debugShowCheckedModeBanner: false),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Map<int, bool> _tasks = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncAllTasks();
    FlutterBackgroundService()
        .on('on_triggered')
        .listen((_) => _syncAllTasks());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncAllTasks();
  }

  // Synchronize state for all tasks (Handles Terminated/Killed state)
  Future<void> _syncAllTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    Map<int, bool> updatedTasks = {};

    for (String key in prefs.getKeys()) {
      if (key.startsWith(kTargetPrefix)) {
        int id = int.parse(key.split('_').last);
        final targetStr = prefs.getString(key);

        if (targetStr != null) {
          final targetTime = DateTime.parse(targetStr);
          // Fallback: If the target time has passed, the task is completed
          if (DateTime.now().isAfter(targetTime)) {
            await prefs.setBool('$kStatusPrefix$id', true);
          }
        }

        updatedTasks[id] = prefs.getBool('$kStatusPrefix$id') ?? false;
      }
    }
    setState(() => _tasks = updatedTasks);
  }

  Future<void> _addNewTask() async {
    final prefs = await SharedPreferences.getInstance();
    final int id = DateTime.now().millisecondsSinceEpoch % 10000;
    final target = DateTime.now().add(const Duration(seconds: 15));

    // 1. Save locally
    await prefs.setString('$kTargetPrefix$id', target.toIso8601String());
    await prefs.setBool('$kStatusPrefix$id', false);

    // 2. Schedule system notification (Works even if app is killed)
    await notifications.zonedSchedule(
      id: id,
      title: "🚀 Task $id Done",
      body: "Variable is now TRUE.",
      scheduledDate: tz.TZDateTime.from(target, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'ch_id',
          'Alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // 3. Start Service and send task
    final service = FlutterBackgroundService();
    if (!(await service.isRunning())) await service.startService();
    service.invoke('add_task', {'id': id, 'delay': 15});

    _syncAllTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Task Sync"),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ..._tasks.entries.map(
            (e) => ListTile(
              title: Text(
                "Task ID: ${e.key}",
                style: const TextStyle(color: Colors.white),
              ),
              trailing: Text(
                e.value ? "TRUE" : "FALSE",
                style: TextStyle(
                  color: e.value ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _addNewTask,
            child: const Text("Start 15s Task"),
          ),
          TextButton(
            onPressed: () async {
              final p = await SharedPreferences.getInstance();
              await p.clear();
              _syncAllTasks();
            },
            child: const Text(
              "Clear All",
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';
// import 'package:http/http.dart' as http; // New import

// const String kStatusPrefix = 'task_status_';
// const String kTargetPrefix = 'task_target_';
// const String kDataPrefix = 'task_api_data_'; // For storing API result
// final notifications = FlutterLocalNotificationsPlugin();

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   service.on('add_task').listen((event) async {
//     final int id = event!['id'];
//     final int seconds = event['delay'];

//     // 1. Wait for 15 seconds
//     await Future.delayed(Duration(seconds: seconds));

//     // 2. CALL API (When notification time arrives)
//     String apiResult = "No Data Found";
//     try {
//       final response = await http.get(
//         Uri.parse(
//           'https://jsonplaceholder.typicode.com/posts/${(id % 100) + 1}',
//         ),
//       );
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         apiResult = data['title']; // Get a random title from API
//         print("hi from 1");
//         log("hi from 2");
//       }
//     } catch (e) {
//       apiResult = "API Error: $e";
//     }

//     // 3. Save status and API data to disk
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('$kStatusPrefix$id', true);
//     await prefs.setString('$kDataPrefix$id', apiResult);

//     // 4. Notify UI instantly
//     service.invoke('on_triggered', {'id': id, 'api_data': apiResult});

//     // 5. Show Notification
//     if (Platform.isAndroid) {
//       final localNotifications = FlutterLocalNotificationsPlugin();
//       await localNotifications.cancel(id: id);
//       await localNotifications.show(
//         id: id,
//         title: "🚀 Task $id Completed!",
//         body: "Data: $apiResult",
//         notificationDetails: const NotificationDetails(
//           android: AndroidNotificationDetails(
//             'ch_id',
//             'Alerts',
//             importance: Importance.max,
//             priority: Priority.high,
//           ),
//         ),
//       );
//     }
//   });
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   tz.initializeTimeZones();
//   final notifications = FlutterLocalNotificationsPlugin();
//   await notifications
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.requestNotificationsPermission();

//   // 1. Setup Timezones & Notifications
//   tz.initializeTimeZones();
//   final String timeZoneName =
//       (await FlutterTimezone.getLocalTimezone()).identifier;
//   tz.setLocalLocation(tz.getLocation(timeZoneName));

//   await notifications.initialize(
//     settings: InitializationSettings(
//       android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//       iOS: DarwinInitializationSettings(
//         requestAlertPermission: true,
//         requestSoundPermission: true,
//       ),
//     ),
//   );

//   // Create the notification channel to prevent Android Foreground Service crash
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'my_foreground', // id
//     'Foreground Service', // title
//     description: 'This channel is used for background tasks.',
//     importance: Importance.low, // low is enough to not make a sound, but required for foreground services
//   );

//   await notifications
//       .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin
//       >()
//       ?.createNotificationChannel(channel);

//   await FlutterBackgroundService().configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: false,
//       isForegroundMode: true,
//       notificationChannelId: 'my_foreground',
//       initialNotificationTitle: 'Task running',
//       initialNotificationContent: 'Waiting...',
//       foregroundServiceNotificationId: 888,
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: false,
//       onForeground: onStart,
//       onBackground: (_) => true,
//     ),
//   );

//   runApp(
//     const MaterialApp(home: HomePage(), debugShowCheckedModeBanner: false),
//   );
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
//   Map<int, Map<String, dynamic>> _tasks = {};

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _syncAllTasks();
//     FlutterBackgroundService()
//         .on('on_triggered')
//         .listen((_) => _syncAllTasks());
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) _syncAllTasks();
//   }

//   Future<void> _syncAllTasks() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.reload();
//     Map<int, Map<String, dynamic>> updatedTasks = {};

//     for (String key in prefs.getKeys()) {
//       if (key.startsWith(kTargetPrefix)) {
//         int id = int.parse(key.split('_').last);
//         DateTime target = DateTime.parse(prefs.getString(key)!);

//         if (DateTime.now().isAfter(target)) {
//           await prefs.setBool('$kStatusPrefix$id', true);

//           // If the task completed (notification came) but API data is missing, fetch it now!
//           final currentData = prefs.getString('$kDataPrefix$id');
//           if (currentData == null) {
//             _fetchApiDataOnReopen(id);
//           }
//         }

//         updatedTasks[id] = {
//           'status': prefs.getBool('$kStatusPrefix$id') ?? false,
//           'api_data': prefs.getString('$kDataPrefix$id') ?? "Fetching...",
//         };
//       }
//     }
//     setState(() => _tasks = updatedTasks);
//   }

//   // Asynchronously fetch API data if it was missed while the app was closed
//   Future<void> _fetchApiDataOnReopen(int id) async {
//     final prefs = await SharedPreferences.getInstance();
//     String apiResult = "No Data Found";
//     try {
//       final response = await http.get(
//         Uri.parse(
//           'https://jsonplaceholder.typicode.com/posts/${(id % 100) + 1}',
//         ),
//       );
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         apiResult = data['title'];
//       }
//     } catch (e) {
//       apiResult = "API Error: $e";
//     }

//     // Save API data to local storage
//     await prefs.setString('$kDataPrefix$id', apiResult);

//     // Refresh UI to show the fetched data
//     _syncAllTasks();
//   }

//   Future<void> _addNewTask() async {
//     final prefs = await SharedPreferences.getInstance();
//     final int id = DateTime.now().millisecondsSinceEpoch % 10000;
//     final target = DateTime.now().add(const Duration(seconds: 15));

//     await prefs.setString('$kTargetPrefix$id', target.toIso8601String());
//     await prefs.setBool('$kStatusPrefix$id', false);

//     await notifications.zonedSchedule(
//       id: id,
//       title: "🚀 Task $id Done",
//       body: "Variable is now TRUE.",
//       scheduledDate: tz.TZDateTime.from(target, tz.local),
//       notificationDetails: const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'ch_id',
//           'Alerts',
//           importance: Importance.max,
//           priority: Priority.high,
//         ),
//         iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
//       ),
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//     );

//     final service = FlutterBackgroundService();
//     if (!(await service.isRunning())) await service.startService();
//     service.invoke('add_task', {'id': id, 'delay': 15});
//     _syncAllTasks();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0F172A),
//       appBar: AppBar(
//         title: const Text("Task API Sync"),
//         backgroundColor: Colors.transparent,
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(20),
//         children: [
//           ..._tasks.entries.map(
//             (e) => Card(
//               color: Colors.white10,
//               child: ListTile(
//                 title: Text(
//                   "Task ID: ${e.key}",
//                   style: const TextStyle(color: Colors.white),
//                 ),
//                 subtitle: Text(
//                   "Data: ${e.value['api_data']}",
//                   style: const TextStyle(color: Colors.white70),
//                 ),
//                 trailing: Text(
//                   e.value['status'] ? "TRUE" : "FALSE",
//                   style: TextStyle(
//                     color: e.value['status'] ? Colors.green : Colors.red,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: _addNewTask,
//             child: const Text("Start 15s Task & Fetch API"),
//           ),
//           TextButton(
//             onPressed: () async {
//               final p = await SharedPreferences.getInstance();
//               await p.clear();
//               _syncAllTasks();
//             },
//             child: const Text(
//               "Clear All",
//               style: TextStyle(color: Colors.white54),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
