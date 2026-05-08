import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  static Future<void> saveUserRole(String role) async {
    await _storage.write(key: 'user_role', value: role);
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: 'user_role');
  }

  static Future<void> saveUserId(String id) async {
    await _storage.write(key: 'user_id', value: id);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  static Future<void> saveUserName(String name) async {
    await _storage.write(key: 'user_name', value: name);
  }

  static Future<String?> getUserName() async {
    return await _storage.read(key: 'user_name');
  }

  static Future<void> saveUserPhone(String phone) async {
    await _storage.write(key: 'user_phone', value: phone);
  }

  static Future<String?> getUserPhone() async {
    return await _storage.read(key: 'user_phone');
  }

  static Future<void> saveIsVerified(bool isVerified) async {
    await _storage.write(key: 'is_verified', value: isVerified.toString());
  }

  static Future<bool> getIsVerified() async {
    final value = await _storage.read(key: 'is_verified');
    return value == 'true';
  }

  static Future<void> saveConfirmationCode(String code) async {
    await _storage.write(key: 'confirmation_code', value: code);
  }

  static Future<String?> getConfirmationCode() async {
    return await _storage.read(key: 'confirmation_code');
  }

  static Future<void> saveMerchantData(String data) async {
    await _storage.write(key: 'merchant_data', value: data);
  }

  static Future<String?> getMerchantData() async {
    return await _storage.read(key: 'merchant_data');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
