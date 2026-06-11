import 'package:hive_flutter/hive_flutter.dart';

class AuthLocalRepository {
  AuthLocalRepository._();
  static final AuthLocalRepository _authLocalRepository =
      AuthLocalRepository._();
  static AuthLocalRepository get instance => _authLocalRepository;

  static const String _boxName = 'authStatus';

  static const String isLoginKey = 'isLogin';
  static const String jwtTokenKey = 'jwtToken';
  static const String userDetailsKey = 'userDetails';
  static const String _clockInStatusKey = 'is_clocked_in';

  static Box<dynamic> get _box => Hive.box<dynamic>(_boxName);
  Future<void> init() async {
    await Hive.openBox<dynamic>(_boxName);
  }

  String getJwtToken() {
    return _box.get(jwtTokenKey, defaultValue: '') as String;
  }

  Future<void> setJwtToken(String? jwtToken) async {
    await _box.put(jwtTokenKey, jwtToken);
  }

  bool checkIsAuth() {
    return _box.get(isLoginKey, defaultValue: false) as bool;
  }

  Future<void> changeAuthStatus({bool? authStatus}) async {
    await _box.put(isLoginKey, authStatus);
  }

  Future<void> setUserDetails(Map<String, dynamic> userData) async {
    await _box.put(userDetailsKey, userData);
  }

  Map<String, dynamic> getUserDetails() {
    final data = _box.get(userDetailsKey);
    if (data == null) return {};
    return Map<String, dynamic>.from(data as Map);
  }

  // Future<void> clearStorage() async {
  //   await _box.clear();
  // }

  // features/authentication/repositories/auth_local_repositories.dart

  Future<void> clearSessionData() async {
    final box = _box;
    await Future.wait([
      box.delete(isLoginKey),
      box.delete(jwtTokenKey),
      box.delete(userDetailsKey),
      // Do NOT delete isOpenFirstTimeKey here
      // so the user doesn't see onboarding again.
    ]);
  }

  Future<void> setClockedInStatus(bool value) async {
    await _box.put(_clockInStatusKey, value);
  }

  bool getClockedInStatus() {
    return _box.get(_clockInStatusKey, defaultValue: false) as bool;
  }
}
