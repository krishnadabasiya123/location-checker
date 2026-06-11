import 'package:location_checker/UpdatedWithInternet/LocalRepository/system_local_repository.dart';

class UiUtils {
  static int get locationUpdateInterval =>
      SettingLocalRepository.instance.getLocationUpdateInterval();
}
