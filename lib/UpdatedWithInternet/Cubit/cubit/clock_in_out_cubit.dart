// import 'dart:developer';

// import 'package:bloc/bloc.dart';
// import 'package:meta/meta.dart';

// @immutable
// sealed class ClockInOutState {}

// final class ClockInOutInitial extends ClockInOutState {}

// final class ClockInOutLoading extends ClockInOutState {}

// final class ClockInOutSucess extends ClockInOutState {}

// final class ClockInOutFailure extends ClockInOutState {
//   final String error;
//   ClockInOutFailure({required this.error});
// }

// class ClockInOutCubit extends Cubit<ClockInOutState> {
//   ClockInOutCubit() : super(ClockInOutInitial());

//   Future<void> setClockInOut({required bool isClockedIn}) async {
//     if (isClockedIn) {
//       await clockOut();
//     } else {
//       await clockIn();
//     }
//   }

//   Future<void> clockIn() async {
//     log("clock in");
//   }

//   Future<void> clockOut() async {
//     log("clock out");
//   }
// }

import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:location_checker/UpdatedWithInternet/LocalRepository/clockInOutLocalStorage.dart';
import 'package:meta/meta.dart';

@immutable
sealed class ClockInOutState {}

final class ClockInOutInitial extends ClockInOutState {}

final class ClockInOutLoading extends ClockInOutState {}

final class ClockInOutSuccess extends ClockInOutState {
  final bool isClockedIn;

  ClockInOutSuccess({required this.isClockedIn});
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

      final newEntry = {
        "type": "in",
        "time": timestamp,
        "lat": 25.25,
        "long": 58.23,
      };

      await _localRepository.saveClockInOut(date: todayStr, entry: newEntry);

      log("clock in success");

      emit(ClockInOutSuccess(isClockedIn: true));
    } catch (e) {
      emit(ClockInOutFailure(error: e.toString()));
    }
  }

  Future<void> clockOut() async {
    try {
      emit(ClockInOutLoading());

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final newEntry = {
        "type": "out",
        "time": timestamp,
        "lat": 25.30,
        "long": 58.28,
      };

      await _localRepository.saveClockInOut(date: todayStr, entry: newEntry);

      log("clock out success");

      emit(ClockInOutSuccess(isClockedIn: false));
    } catch (e) {
      emit(ClockInOutFailure(error: e.toString()));
    }
  }
}
