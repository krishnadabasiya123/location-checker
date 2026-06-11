import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:location_checker/ClockInOut/ClockInOutLocalStorage.dart';
import 'package:location_checker/UpdatedWithInternet/LocalRepository/auth_local_repository.dart';
import 'package:location_checker/UpdatedWithInternet/LocalRepository/clockInOutLocalStorage.dart';
import 'package:location_checker/UpdatedWithInternet/LocalRepository/clockInOutSyncManager.dart';
import 'package:location_checker/UpdatedWithInternet/LocalRepository/location_repository.dart';
import 'package:location_checker/UpdatedWithInternet/LocalRepository/location_service.dart';
import 'package:location_checker/UpdatedWithInternet/LocalRepository/system_local_repository.dart';
import 'package:location_checker/UpdatedWithInternet/Screen/ClockInOutScreen.dart';
import 'package:location_checker/UpdatedWithInternet/Utils/hive_utils.dart';

Future<void> _requestLocationPermission() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print('Location services are disabled.');
    return;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print('Location permissions are denied.');
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    print('Location permissions are permanently denied.');
    return;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await HiveUtils().openBox();
  await SettingLocalRepository.instance.init();

  // Request location permission at startup
  await _requestLocationPermission();

  if (AuthLocalRepository.instance.getClockedInStatus()) {
    await LocationTracker.instance.start();
  }

  // Start continuous offline synchronization monitoring when internt come and goes
  ClockInOutSyncManager().startMonitoring();

  runApp(const MyAppNew());
}
