import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço de armazenamento seguro (Keychain no iOS / EncryptedSharedPreferences no Android)
/// para guardar tokens JWT, refresh tokens e unidade UBS ativa.
class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'filafacil_access_token';
  static const String _refreshTokenKey = 'filafacil_refresh_token';
  static const String _activeUbsKey = 'filafacil_active_ubs';

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> setAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> setRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getActiveUbs() => _storage.read(key: _activeUbsKey);

  Future<void> setActiveUbs(String ubsName) =>
      _storage.write(key: _activeUbsKey, value: ubsName);

  Future<void> clearAuthSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService(FlutterSecureStorage());
});
