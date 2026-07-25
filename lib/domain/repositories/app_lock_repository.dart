abstract class AppLockRepository {
  Future<void> savePinHash(String hash);
  Future<String?> getPinHash();
  Future<void> setPinEnabled(bool enabled);
  Future<bool> getPinEnabled();
  Future<void> setBiometricEnabled(bool enabled);
  Future<bool> getBiometricEnabled();
  Future<bool> isBiometricAvailable();

  /// Session expiry — after unlock, session stays active for [sessionDuration].
  Future<void> saveSessionExpiry(DateTime expiry);
  Future<DateTime?> getSessionExpiry();
  Future<void> clearSession();
  Future<bool> isSessionActive();

  Future<void> clear();
}