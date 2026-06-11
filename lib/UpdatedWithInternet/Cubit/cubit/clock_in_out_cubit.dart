import 'dart:developer';
import 'dart:math' hide log;

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:location_checker/UpdatedWithInternet/LocalRepository/clockInOutLocalStorage.dart';
import 'package:location_checker/UpdatedWithInternet/LocalRepository/location_repository.dart';
import 'package:location_checker/UpdatedWithInternet/LocalRepository/location_service.dart';
import 'package:location_checker/UpdatedWithInternet/Model/location_point.dart';
import 'package:meta/meta.dart';

@immutable
sealed class ClockInOutState {}

final class ClockInOutInitial extends ClockInOutState {}

final class ClockInOutLoading extends ClockInOutState {}

// final class ClockInOutSuccess extends ClockInOutState {
//   final bool isClockedIn;

//   ClockInOutSuccess({required this.isClockedIn});
// }
class ClockInOutSuccess extends ClockInOutState {
  final bool isClockedIn;
  final bool isUserAction; // <--- Add this

  ClockInOutSuccess({
    required this.isClockedIn,
    this.isUserAction = false, // Default to false
  });

  @override
  List<Object> get props => [isClockedIn, isUserAction];
}

final class ClockInOutFailure extends ClockInOutState {
  final String error;

  ClockInOutFailure({required this.error});
}

class ClockInOutCubit extends Cubit<ClockInOutState> {
  final LocalRepository _localRepository;

  ClockInOutCubit(this._localRepository) : super(ClockInOutInitial());

  final String todayStr = DateFormat("dd-MM-yyyy").format(DateTime.now());

  Future<void> getClockInStatus() async {
    try {
      emit(ClockInOutLoading());

      final Map<dynamic, dynamic> allClockInOutData = await _localRepository
          .getAllClockInOutData();

      bool isClockedIn = false;

      if (allClockInOutData.isNotEmpty) {
        final firstKeyEntry = allClockInOutData.keys.first;

        final List<dynamic> entries = List<dynamic>.from(
          allClockInOutData[firstKeyEntry] ?? [],
        );

        if (entries.isNotEmpty) {
          final lastEntry = Map<String, dynamic>.from(entries.last);

          isClockedIn = lastEntry["type"] == "in";
        }
      }

      emit(ClockInOutSuccess(isClockedIn: isClockedIn));
    } catch (e) {
      emit(ClockInOutFailure(error: e.toString()));
    }
  }

  Future<Map<String, String>?> _getCurrentLocation() async {
    try {
      if (kDebugMode) {
        log('📍 Getting current location (with 10s timeout)...');
      }

      // WRAP IN STRICT TIMEOUT because Geolocator can hang on Simulator
      return await Future<Map<String, String>?>.delayed(
        Duration.zero,
        () async {
          try {
            // Check permission
            final permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied ||
                permission == LocationPermission.deniedForever) {
              if (kDebugMode) {
                log('⚠️ Permission denied regarding current location fetch.');
              }
              return null;
            }

            final position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
            );

            if (kDebugMode) {
              log(
                '📍 Got position: ${position.latitude}, ${position.longitude}',
              );
            }
            return {
              'latitude': position.latitude.toString(),
              'longitude': position.longitude.toString(),
            };
          } catch (e) {
            rethrow;
          }
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            log(
              '❌ STRICT TIMEOUT REACHED (10s). Returning null to unblock UI.',
            );
          }
          return null;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        log('❌ Exception in _getCurrentLocation: $e');
      }
      return null;
    }
  }

  Future<void> setClockInOut({required bool isClockedIn}) async {
    if (isClockedIn) {
      await clockOut();
    } else {
      await clockIn();
    }
  }

  Future<void> clockIn() async {
    try {
      emit(ClockInOutLoading());

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final currentLocation = await _getCurrentLocation();
      if (currentLocation == null) {
        throw Exception('Failed to get current location');
      }
      final newEntry = {
        "type": "in",
        "time": timestamp,
        "lat": currentLocation['latitude'],
        "long": currentLocation['longitude'],
      };

      await _localRepository.saveClockInOut(date: todayStr, entry: newEntry);

      // Generate and save a random location coordinate on successful clock in

      await LocationTracker.instance.start();

      emit(ClockInOutSuccess(isClockedIn: true, isUserAction: true));
    } catch (e) {
      emit(ClockInOutFailure(error: e.toString()));
    }
  }

  // work only for today date
  Future<void> clockOut() async {
    try {
      emit(ClockInOutLoading());

      // ALWAYS stop location tracking first
      await LocationTracker.instance.stop();

      // at the time of clocck out location data first send to server then clock out
      await LocationRepository().syncLocationsToServer(date: todayStr);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final currentLocation = await _getCurrentLocation();
      if (currentLocation == null) {
        throw Exception('Failed to get current location');
      }

      final newEntry = {
        "type": "out",
        "time": timestamp,
        "lat": currentLocation['latitude'],
        "long": currentLocation['longitude'],
      };

      await _localRepository.saveClockInOut(date: todayStr, entry: newEntry);

      log("clock out success");

      emit(ClockInOutSuccess(isClockedIn: false, isUserAction: true));
    } catch (e) {
      emit(ClockInOutFailure(error: e.toString()));
    }
  }

  Future<void> checkStatus() async {
    final status = await _localRepository.getClockInStatus();
    // Set isUserAction to false because this is just loading the app
    emit(ClockInOutSuccess(isClockedIn: status, isUserAction: false));
  }
}
