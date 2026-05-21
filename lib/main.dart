import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:location_checker/UpdatedWithInternet/Screen/ClockInOutScreen.dart';
import 'package:location_checker/UpdatedWithInternet/Utils/hive_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await HiveUtils().openBox();
  runApp(const MyAppNew());
}
