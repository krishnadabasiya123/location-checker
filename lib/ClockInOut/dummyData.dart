import 'package:intl/intl.dart';
import 'package:location_checker/UpdatedWithInternet/Model/location_point.dart';

final todayDate = DateTime.now();
final yesterdayDate = DateTime.now().subtract(const Duration(days: 1));

final todayStr = DateFormat('dd-MM-yyyy').format(todayDate);
final yesterdayStr = DateFormat('dd-MM-yyyy').format(yesterdayDate);

final now = DateTime.now();
final timeStr = DateFormat('hh:mm:ss.SSS a').format(now);
final timestamp = now.millisecondsSinceEpoch;

// 09:00:00 AM Clock In times
final DateTime yesterdayClockIn = DateTime(
  yesterdayDate.year,
  yesterdayDate.month,
  yesterdayDate.day,
  9,
  0,
  0,
);
final DateTime todayClockIn = DateTime(
  todayDate.year,
  todayDate.month,
  todayDate.day,
  9,
  0,
  0,
);

// 01:00:00 PM Clock Out times
final DateTime yesterdayClockOut = DateTime(
  yesterdayDate.year,
  yesterdayDate.month,
  yesterdayDate.day,
  13,
  0,
  0,
);
final DateTime todayClockOut = DateTime(
  todayDate.year,
  todayDate.month,
  todayDate.day,
  13,
  0,
  0,
);

/// Default basic location data for backward compatibility
final locationData = {
  "location": [
    {"date": todayStr, "time": timestamp, "lat": 12.9716, "long": 77.5946},
    {"date": todayStr, "time": timestamp, "lat": 12.9810, "long": 77.6100},
    {"date": todayStr, "time": timestamp, "lat": 13.0105, "long": 77.6421},
    {"date": todayStr, "time": timestamp, "lat": 12.9352, "long": 77.6245},
    {"date": todayStr, "time": timestamp, "lat": 12.9120, "long": 77.6101},
  ],
};

/// 1. Session data box mock data matching user format (dd-MM-yyyy date keys)
final Map<String, List<Map<String, dynamic>>> largeSessionData = {
  yesterdayStr: [
    {
      "type": "in",
      "time": yesterdayClockIn.millisecondsSinceEpoch,
      "lat": 25.25,
      "long": 58.23,
    },
    {
      "type": "out",
      "time": yesterdayClockOut.millisecondsSinceEpoch,
      "lat": 25.30,
      "long": 58.28,
    },
  ],
  todayStr: [
    {
      "type": "in",
      "time": todayClockIn.millisecondsSinceEpoch,
      "lat": 25.25,
      "long": 58.23,
    },
    {
      "type": "out",
      "time": todayClockOut.millisecondsSinceEpoch,
      "lat": 25.30,
      "long": 58.28,
    },
  ],
};

/// 2. Generates exactly 2500 coordinates per date (total 5000 coordinates across 2 dates).
/// The coordinates' timestamps are strictly between the clock-in (09:00:00 AM) and clock-out (06:00:00 PM) times.
Map<String, Map<String, dynamic>> getLargeLocationData() {
  final Map<String, Map<String, dynamic>> data = {};
  final dates = [yesterdayStr, todayStr];

  for (final dateStr in dates) {
    final List<Map<String, dynamic>> locations = [];
    final isYesterday = dateStr == yesterdayStr;
    final baseDate = isYesterday ? yesterdayDate : todayDate;

    // Start 2 seconds after clock-in (09:00:02 AM)
    DateTime current = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      9,
      0,
      2,
    );

    // 5000 points * 2 seconds = 10000 seconds = 2.77 hours (ends around 11:46:42 AM)
    for (int i = 0; i < 5001; i++) {
      // Mock coordinates slightly moving around Bengaluru city
      final double lat = 12.9716 + (i * 0.00001);
      final double long = 77.5946 + (i * 0.00001);

      // Instantiating the LocationPoint model to manage/store mock coordinate data
      final point = LocationPoint(
        latitude: double.parse(lat.toStringAsFixed(4)),
        longitude: double.parse(long.toStringAsFixed(4)),
        timestamp: current,
        date: dateStr,
      );

      locations.add({
        "date": point.date,
        "time": point.timestamp.millisecondsSinceEpoch,
        "lat": point.latitude,
        "long": point.longitude,
      });

      current = current.add(const Duration(seconds: 2));
    }

    data[dateStr] = {"location": locations};
  }
  return data;
}
