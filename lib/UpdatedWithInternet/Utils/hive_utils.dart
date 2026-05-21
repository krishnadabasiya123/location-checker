import 'package:hive_flutter/adapters.dart';

class HiveUtils {
  Future<void> openBox() async {
    await Hive.openBox("clokINOutData");
    await Hive.openBox("locationdata");
  }
}
