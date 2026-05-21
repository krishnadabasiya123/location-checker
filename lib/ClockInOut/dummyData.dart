import 'package:intl/intl.dart';

final todayStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
final now = DateTime.now();
final timeStr = DateFormat('hh:mm:ss.SSS a').format(now);
final timestamp = now.millisecondsSinceEpoch;
final locationData = {
  "location": [
    {"date": todayStr, "time": timestamp, "lat": 12.9716, "long": 77.5946},
    {"date": todayStr, "time": timestamp, "lat": 12.9810, "long": 77.6100},
    {"date": todayStr, "time": timestamp, "lat": 13.0105, "long": 77.6421},
    {"date": todayStr, "time": timestamp, "lat": 12.9352, "long": 77.6245},
    {"date": todayStr, "time": timestamp, "lat": 12.9120, "long": 77.6101},
  ],
};



//json 1 

// session data

// {
//   "20-05-2026": [
//     {
//       "type": "in",
//       "time": "08:00:00 AM",
//       "lat": 25.25,
//       "long": 58.23
//     },
//     {
//       "type": "out",
//       "time": "12:00:00 PM",
//       "lat": 25.30,
//       "long": 58.28
//     },
//     {
//       "type": "in",
//       "time": "01:30:00 PM",
//       "lat": 25.35,
//       "long": 58.33
//     },
//     {
//       "type": "out",
//       "time": "05:30:00 PM",
//       "lat": 25.40,
//       "long": 58.38
//     }
//   ]
// }


// location data box


// {
//   "20-05-2026": {
//     "location": [
//       {
//         "time": "09:00:00 AM",
//         "lat": 12.1,
//         "long": 77.1,
//            "date":"20-05-2026"
//       },
//       {
//         "time": "11:00:00 AM",
//         "lat": 12.2,
//         "long": 77.2,
//            "date":"20-05-2026"
//       },
//       {
//         "time": "02:00:00 PM",
//         "lat": 12.3,
//         "long": 77.3,
//             "date":"20-05-2026"
//       },
//       {
//         "time": "04:30:00 PM",
//         "lat": 12.4,
//         "long": 77.4,
//             "date":"20-05-2026"
//       }
//     ]
//   }
// }
