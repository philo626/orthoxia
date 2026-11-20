import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Hardened Authenticated Encryption Service (AES-256-GCM AEAD) backed by
/// Android Keystore (RSA-OAEP + AES-GCM) / iOS Keychain + Fail-Closed Biometrics.
/// Guarantees confidentiality AND cryptographic tamper detection for Confession & Private Notes.
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static const _secureKeyName = 'orthodoxia_aes256_master_key_v3';
  static const _legacyKeyNameV2 = 'orthodoxia_aes256_master_key_v2';
  static const _legacyXorKey = 'OrthodoxConfessionKey_1743AM';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );
  final LocalAuthentication _localAuth = LocalAuthentication();

  enc.Key? _cachedAesKey;
  bool _usingHardwareKeystore = false;

  bool get isHardwareKeystoreActive => _usingHardwareKeystore;

  enc.Key _generateSecureRandomKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return enc.Key(Uint8List.fromList(keyBytes));
  }

  /// Initializes or retrieves the 256-bit random master key stored in hardware Keystore/Keychain.
  /// NEVER falls back to a hardcoded static key literal compiled inside the binary.
  Future<void> init() async {
    if (_cachedAesKey != null) return;
    try {
      String? storedBase64 = await _secureStorage.read(key: _secureKeyName);
      // Migrate smoothly from V2 keystore slot if present
      if (storedBase64 == null || storedBase64.isEmpty) {
        storedBase64 = await _secureStorage.read(key: _legacyKeyNameV2);
        if (storedBase64 != null && storedBase64.isNotEmpty) {
          await _secureStorage.write(key: _secureKeyName, value: storedBase64);
        }
      }
      if (storedBase64 == null || storedBase64.isEmpty) {
        final fresh = _generateSecureRandomKey();
        storedBase64 = fresh.base64;
        await _secureStorage.write(key: _secureKeyName, value: storedBase64);
      }
      _cachedAesKey = enc.Key.fromBase64(storedBase64);
      _usingHardwareKeystore = true;
    } catch (e) {
      // Ephemeral cryptographically random key in memory (for headless unit tests — zero hardcoded key!)
      if (kDebugMode) {
        debugPrint('EncryptionService ephemeral test key fallback: $e');
      }
      _cachedAesKey = _generateSecureRandomKey();
      _usingHardwareKeystore = false;
    }
  }

  /// Encrypts sensitive text with Authenticated AES-256-GCM (random 12-byte nonce + 128-bit auth tag).
  /// Any bit flip or tampering in storage causes decryption to fail cleanly.
  String encryptAes256(String plainText) {
    final key = _cachedAesKey ?? (_cachedAesKey = _generateSecureRandomKey());
    final iv = enc.IV.fromSecureRandom(12); // NIST standard 96-bit GCM nonce
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return 'AES256_GCM_V3:${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts AES256_GCM_V3 (authenticated), with seamless backwards read support for V2 & V1.
  String decryptAes256(String stored) {
    final key = _cachedAesKey;
    if (stored.startsWith('AES256_GCM_V3:')) {
      final parts = stored.split(':');
      if (parts.length == 3 && key != null) {
        final iv = enc.IV.fromBase64(parts[1]);
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
        return encrypter.decrypt64(parts[2], iv: iv);
      }
      throw const FormatException('Invalid or tampered AES-256-GCM payload');
    }
    if (stored.startsWith('AES256_V2:')) {
      final parts = stored.split(':');
      if (parts.length == 3 && key != null) {
        final iv = enc.IV.fromBase64(parts[1]);
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
        return encrypter.decrypt64(parts[2], iv: iv);
      }
      throw const FormatException('Invalid AES-256-CBC payload');
    }
    if (stored.startsWith('ENC_V1:')) {
      final encoded = stored.substring(7);
      final cipher = base64Decode(encoded);
      final keyBytes = utf8.encode(_legacyXorKey);
      final out = List<int>.generate(
        cipher.length,
        (i) => cipher[i] ^ keyBytes[i % keyBytes.length] ^ ((i * 31) & 0xFF),
      );
      return utf8.decode(out);
    }
    return stored;
  }

  /// Cryptographically erases the hardware Keystore master key & clears RAM key reference.
  Future<void> wipeMasterKey() async {
    _cachedAesKey = null;
    _usingHardwareKeystore = false;
    try {
      await _secureStorage.delete(key: _secureKeyName);
      await _secureStorage.delete(key: _legacyKeyNameV2);
    } catch (_) {}
  }

  /// Checks whether device supports Biometrics (Fingerprint / FaceID) or Device PIN
  Future<bool> canAuthenticateBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Prompts user for Fingerprint / Face Unlock / Device PIN to unlock Confession Notes.
  /// FAIL-CLOSED: if device lock hardware is available and authentication fails or throws,
  /// returns `false` so private confession notes stay locked.
  Future<bool> authenticateForConfession() async {
    final available = await canAuthenticateBiometric();
    if (!available) return true; // Device has no OS lock screen configured
    try {
      return await _localAuth.authenticate(
        localizedReason: 'تأكيد هويتك لفتح مذكرات الاعتراف وفحص الضمير المشفرة محلياً',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Biometric auth failed (fail-closed): $e');
      }
      return false;
    }
  }
}
