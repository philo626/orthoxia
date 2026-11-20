import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceIntegrityStatus {
  final bool isRooted;
  final bool isDebuggable;
  final bool isEmulator;

  const DeviceIntegrityStatus({
    this.isRooted = false,
    this.isDebuggable = false,
    this.isEmulator = false,
  });

  bool get hasRisk => isRooted || (!kDebugMode && isDebuggable);
}

/// Central OWASP Mobile Security Guard for Orthodoxia:
/// - Native Android FLAG_SECURE screenshot/screen-recording protection
/// - Device root / debug integrity checks
/// - Strict HTTPS-only + Anti-SSRF URL & domain allowlist enforcement
/// - User input sanitization (anti-HTML/script/BiDi spoofing)
/// - Sliding-window client-side rate limiting (anti-spam & brute-force protection)
/// - Password strength enforcement for account registration
class SecurityGuardService {
  static final SecurityGuardService _instance = SecurityGuardService._internal();
  factory SecurityGuardService() => _instance;
  SecurityGuardService._internal();

  static const MethodChannel _channel = MethodChannel('com.orthodox.app/security');

  /// Trusted Orthodox digital library hosts permitted for in-app HTML/API fetching.
  static const Set<String> trustedLibraryHosts = {
    'st-takla.org',
    'www.st-takla.org',
    'christianlib.com',
    'www.christianlib.com',
    'archive.org',
    'www.archive.org',
    'arabchurch.com',
    'www.arabchurch.com',
    'stmacariusmonastery.org',
    'www.stmacariusmonastery.org',
    'upload.wikimedia.org',
    'thumb.wikimedia.org',
    'commons.wikimedia.org',
  };

  final Map<String, List<DateTime>> _rateBuckets = {};

  /// Activates or clears Android hardware FLAG_SECURE (blocks screenshots, screen recording,
  /// and Recent Apps thumbnail previews on sensitive screens like Confession Notes).
  Future<void> setSecureScreen(bool enable) async {
    try {
      await _channel.invokeMethod('setSecureScreen', {'enable': enable});
    } catch (_) {
      // Safe no-op on unit tests or unsupported platforms
    }
  }

  /// Queries native Android checks for root binaries (su/Magisk), test-keys, or debug flags.
  Future<DeviceIntegrityStatus> checkDeviceIntegrity() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('checkDeviceIntegrity');
      if (res != null) {
        return DeviceIntegrityStatus(
          isRooted: res['isRooted'] == true,
          isDebuggable: res['isDebuggable'] == true,
          isEmulator: res['isEmulator'] == true,
        );
      }
    } catch (_) {}
    return const DeviceIntegrityStatus();
  }

  /// Strips control chars, Unicode BiDi spoofing overrides, and HTML/script tags, and caps length.
  static String sanitizeText(
    String input, {
    int maxLength = 500,
    bool allowNewlines = true,
  }) {
    var s = input
        // Remove BiDi spoofing / invisible override characters
        .replaceAll(RegExp(r'[\u202A-\u202E\u2066-\u2069\u200E\u200F\uFEFF]'), '')
        // Remove ASCII control characters except optional newline/tab
        .replaceAll(allowNewlines ? RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]') : RegExp(r'[\x00-\x1F\x7F]'), ' ')
        // Strip any HTML/script tags
        .replaceAll(RegExp(r'<[^>]*>'), '');

    if (!allowNewlines) {
      s = s.replaceAll(RegExp(r'\s+'), ' ');
    } else {
      s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    }
    s = s.trim();
    if (s.length > maxLength) {
      s = s.substring(0, maxLength).trim();
    }
    return s;
  }

  /// Upgrades known cleartext URLs safely to HTTPS and trims whitespace.
  static String upgradeToHttps(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://')) {
      return 'https://${trimmed.substring(7)}';
    }
    return trimmed;
  }

  /// Strict URL safety check for launching external links:
  /// - Enforces HTTPS only (blocks javascript:, file:, intent:, data:, cleartext http:)
  /// - Blocks private/loopback IPs and localhost (Anti-SSRF)
  static bool isSafeExternalUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasScheme || uri.scheme.toLowerCase() != 'https') {
      return false;
    }
    final host = uri.host.toLowerCase();
    if (host.isEmpty || !host.contains('.')) return false;
    if (_isPrivateOrLocalHost(host)) return false;
    return true;
  }

  /// Strict host allowlist check for in-app HTML/API fetching (prevents SSRF / untrusted scraping).
  static bool isTrustedLibraryUrl(String rawUrl) {
    if (!isSafeExternalUrl(rawUrl)) return false;
    final host = Uri.parse(rawUrl.trim()).host.toLowerCase();
    return trustedLibraryHosts.contains(host) ||
        trustedLibraryHosts.any((allowed) => host.endsWith('.$allowed'));
  }

  static bool _isPrivateOrLocalHost(String host) {
    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host == '::1' ||
        host.endsWith('.local') ||
        host.endsWith('.internal')) {
      return true;
    }
    // Block RFC1918 & link-local IPv4 ranges (10.x, 172.16-31.x, 192.168.x, 169.254.x)
    final ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$').firstMatch(host);
    if (ipv4 != null) {
      final a = int.tryParse(ipv4.group(1)!) ?? 0;
      final b = int.tryParse(ipv4.group(2)!) ?? 0;
      if (a == 10 || a == 127 || a == 0) return true;
      if (a == 169 && b == 254) return true;
      if (a == 192 && b == 168) return true;
      if (a == 172 && b >= 16 && b <= 31) return true;
    }
    return false;
  }

  /// Client-side sliding-window + cooldown rate limiter against spam & brute-force attempts.
  bool allowAction(
    String bucket, {
    Duration cooldown = const Duration(seconds: 3),
    int maxPerWindow = 5,
    Duration window = const Duration(minutes: 2),
  }) {
    final now = DateTime.now();
    final history = _rateBuckets.putIfAbsent(bucket, () => []);
    history.removeWhere((t) => now.difference(t) > window);

    if (history.isNotEmpty && now.difference(history.last) < cooldown) {
      return false;
    }
    if (history.length >= maxPerWindow) {
      return false;
    }
    history.add(now);
    return true;
  }

  /// Validates password strength for new user registrations (min 8 chars + letter & digit).
  /// Returns null if valid, or a clear Arabic error message if weak.
  static String? validateNewPassword(String password) {
    if (password.length < 8) {
      return 'كلمة المرور يجب أن تكون ٨ أحرف على الأقل لحماية حسابك.';
    }
    final hasLetter = RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    if (!hasLetter || !hasDigit) {
      return 'لحماية أقوى، يُرجى أن تحتوي كلمة المرور على حروف وأرقام معاً.';
    }
    return null;
  }
}
