import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../firebase_options.dart';
import '../../models/prayer_request_model.dart';
import 'security_guard_service.dart';

class FirebaseAuthResult {
  final bool success;
  final bool isCloudBacked;
  final String? uid;
  final String? displayName;
  final String? email;
  final String? phone;
  final String message;

  const FirebaseAuthResult({
    required this.success,
    required this.isCloudBacked,
    this.uid,
    this.displayName,
    this.email,
    this.phone,
    this.message = '',
  });
}

/// Unified Firebase Service (Auth + Cloud Firestore) with safe offline/unconfigured fallback.
/// Privacy Guarantee: Confession notes & spiritual tracker logs are NEVER uploaded to Firestore.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  bool get isFirebaseReady => _isInitialized;

  User? get currentUser => _isInitialized ? FirebaseAuth.instance.currentUser : null;

  /// Safely initializes Firebase using DefaultFirebaseOptions & google-services.json
  Future<void> initSafely() async {
    if (_isInitialized) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('Firebase initialized successfully.');
      }
    } catch (e) {
      _isInitialized = false;
      if (kDebugMode) {
        debugPrint('Firebase running in local offline-first mode: $e');
      }
    }
  }

  /// Syncs ONLY sanitized non-sensitive public profile fields (display name + patron saint).
  /// Strictly matches Firestore zero-trust schema; NEVER syncs confession notes.
  Future<void> syncPublicProfile({
    required String displayName,
    String? patronSaintId,
  }) async {
    if (!_isInitialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final safeName = SecurityGuardService.sanitizeText(displayName, maxLength: 60, allowNewlines: false);
    final safeSaint = SecurityGuardService.sanitizeText(patronSaintId ?? 'virgin_mary', maxLength: 60, allowNewlines: false);
    if (safeName.isEmpty) return;
    try {
      await user.updateDisplayName(safeName);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': safeName,
        'patronSaintId': safeSaint.isEmpty ? 'virgin_mary' : safeSaint,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('Firestore profile sync skipped: $e');
    }
  }

  /// Email & Password Login or Registration via Firebase Auth (with brute-force rate limiting)
  Future<FirebaseAuthResult> signInOrRegisterWithEmail({
    required String email,
    required String password,
    required String displayName,
    required bool isLogin,
  }) async {
    if (!SecurityGuardService().allowAction(
      'auth_email',
      cooldown: const Duration(seconds: 2),
      maxPerWindow: 8,
      window: const Duration(minutes: 5),
    )) {
      return const FirebaseAuthResult(
        success: false,
        isCloudBacked: true,
        message: 'عدد محاولات الدخول متكرر جداً. يُرجى الانتظار قليلاً ثم المحاولة مرة أخرى.',
      );
    }

    if (!isLogin) {
      final pwdErr = SecurityGuardService.validateNewPassword(password);
      if (pwdErr != null) {
        return FirebaseAuthResult(
          success: false,
          isCloudBacked: _isInitialized,
          message: pwdErr,
        );
      }
    }

    if (!_isInitialized) {
      return FirebaseAuthResult(
        success: true,
        isCloudBacked: false,
        displayName: displayName,
        email: email,
        message: 'تم حفظ بياناتك بنجاح على جهازك.',
      );
    }

    try {
      UserCredential cred;
      if (isLogin) {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } else {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (displayName.trim().isNotEmpty) {
          await cred.user?.updateDisplayName(displayName.trim());
        }
      }

      final resolvedName = displayName.trim().isNotEmpty
          ? displayName.trim()
          : (cred.user?.displayName ?? email.split('@').first);

      await syncPublicProfile(displayName: resolvedName);

      return FirebaseAuthResult(
        success: true,
        isCloudBacked: true,
        uid: cred.user?.uid,
        displayName: resolvedName,
        email: cred.user?.email ?? email,
        message: isLogin ? 'أهلاً بعودتك إلى أرثوذكسيا.' : 'تم إنشاء حسابك بنجاح.',
      );
    } on FirebaseAuthException catch (e) {
      return FirebaseAuthResult(
        success: false,
        isCloudBacked: true,
        message: _arabicAuthError(e.code),
      );
    } catch (e) {
      return FirebaseAuthResult(
        success: false,
        isCloudBacked: true,
        message: 'حدث خطأ أثناء الاتصال بالخادم، حاول مرة أخرى.',
      );
    }
  }

  /// Real Google Sign-In via GoogleSignIn + FirebaseAuth
  Future<FirebaseAuthResult> signInWithGoogle() async {
    if (!_isInitialized) {
      return const FirebaseAuthResult(
        success: false,
        isCloudBacked: false,
        message: 'يتطلب تسجيل الدخول بحساب Google تفعيل ملف google-services.json من Firebase Console.',
      );
    }

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: '374506508479-1oq4tomh0rjrp2o6voevcvta7l1qa47k.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return const FirebaseAuthResult(
          success: false,
          isCloudBacked: true,
          message: 'تم إلغاء تسجيل الدخول بحساب Google',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final name = userCred.user?.displayName ?? googleUser.displayName ?? '';
      await syncPublicProfile(displayName: name);

      return FirebaseAuthResult(
        success: true,
        isCloudBacked: true,
        uid: userCred.user?.uid,
        displayName: name,
        email: userCred.user?.email ?? googleUser.email,
        message: 'مرحباً بك يا $name! تم الربط بحساب Google بنجاح.',
      );
    } catch (e) {
      return FirebaseAuthResult(
        success: false,
        isCloudBacked: true,
        message: 'تعذر إتمام تسجيل الدخول بـ Google: تأكد من إضافة بصمة SHA-1 في Firebase.',
      );
    }
  }

  /// Real Phone OTP initiation via FirebaseAuth.verifyPhoneNumber
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String errorMessage) onError,
    required void Function(FirebaseAuthResult result) onAutoVerified,
  }) async {
    if (!_isInitialized) {
      onCodeSent('offline_local_otp');
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
          onAutoVerified(FirebaseAuthResult(
            success: true,
            isCloudBacked: true,
            uid: userCred.user?.uid,
            phone: phoneNumber,
            displayName: userCred.user?.displayName,
          ));
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_arabicAuthError(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      onError('تعذر إرسال رمز التحقق حالياً.');
    }
  }

  /// Confirm SMS OTP Code with FirebaseAuth
  Future<FirebaseAuthResult> confirmPhoneOtp({
    required String verificationId,
    required String smsCode,
    required String displayName,
    required String phoneNumber,
  }) async {
    if (!_isInitialized || verificationId == 'offline_local_otp') {
      return FirebaseAuthResult(
        success: true,
        isCloudBacked: false,
        displayName: displayName,
        phone: phoneNumber,
      );
    }

    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(cred);
      if (displayName.trim().isNotEmpty) {
        await syncPublicProfile(displayName: displayName.trim());
      }
      return FirebaseAuthResult(
        success: true,
        isCloudBacked: true,
        uid: userCred.user?.uid,
        displayName: displayName,
        phone: phoneNumber,
      );
    } on FirebaseAuthException catch (e) {
      return FirebaseAuthResult(
        success: false,
        isCloudBacked: true,
        message: _arabicAuthError(e.code),
      );
    }
  }

  /// Sends a password reset link to the user's registered email address.
  Future<FirebaseAuthResult> sendPasswordResetEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      return const FirebaseAuthResult(
        success: false,
        isCloudBacked: false,
        message: 'يرجى كتابة بريدك الإلكتروني بشكل صحيح أولاً.',
      );
    }
    if (!SecurityGuardService().allowAction(
      'auth_pwd_reset',
      cooldown: const Duration(seconds: 20),
      maxPerWindow: 4,
      window: const Duration(minutes: 10),
    )) {
      return const FirebaseAuthResult(
        success: false,
        isCloudBacked: true,
        message: 'تم إرسال طلب استعادة مؤخراً. يرجى الانتظار قليلاً قبل إعادة المحاولة.',
      );
    }
    if (!_isInitialized) {
      return const FirebaseAuthResult(
        success: false,
        isCloudBacked: false,
        message: 'تعذر الاتصال بالخادم حالياً. تأكد من اتصالك بالإنترنت.',
      );
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: trimmed);
      return const FirebaseAuthResult(
        success: true,
        isCloudBacked: true,
        message: 'إذا كان البريد مسجلاً لدينا، ستصلك رسالة استعادة كلمة المرور خلال لحظات.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Anti-enumeration: identical reassuring response
        return const FirebaseAuthResult(
          success: true,
          isCloudBacked: true,
          message: 'إذا كان البريد مسجلاً لدينا، ستصلك رسالة استعادة كلمة المرور خلال لحظات.',
        );
      }
      return FirebaseAuthResult(
        success: false,
        isCloudBacked: true,
        message: _arabicAuthError(e.code),
      );
    } catch (_) {
      return const FirebaseAuthResult(
        success: false,
        isCloudBacked: true,
        message: 'تعذر إرسال رابط الاستعادة حالياً. حاول مرة أخرى.',
      );
    }
  }

  Future<void> signOut() async {
    if (!_isInitialized) return;
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  // ==================== CLOUD FIRESTORE PRAYER WALL ====================

  Stream<List<PrayerRequest>>? watchPrayerWall() {
    if (!_isInitialized) return null;
    try {
      return FirebaseFirestore.instance
          .collection('prayer_requests')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((snap) => snap.docs.map((doc) {
                final d = doc.data();
                final ts = d['createdAt'];
                final created = ts is Timestamp ? ts.toDate() : DateTime.now();
                return PrayerRequest(
                  id: doc.id,
                  authorName: '${d['authorName'] ?? ''}',
                  isAnonymous: d['isAnonymous'] == true,
                  title: '${d['title'] ?? ''}',
                  content: '${d['content'] ?? ''}',
                  createdAt: created,
                  prayedCount: (d['prayedCount'] as num?)?.toInt() ?? 1,
                );
              }).toList());
    } catch (_) {
      return null;
    }
  }

  Future<void> addPrayerRequestToCloud({
    required String title,
    required String content,
    required bool isAnonymous,
    required String authorName,
  }) async {
    if (!_isInitialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Zero-trust: Firestore requires signed-in authorUid

    if (!SecurityGuardService().allowAction(
      'prayer_wall_post',
      cooldown: const Duration(seconds: 15),
      maxPerWindow: 4,
      window: const Duration(minutes: 10),
    )) {
      return;
    }

    final safeTitle = SecurityGuardService.sanitizeText(title, maxLength: 120, allowNewlines: false);
    final safeContent = SecurityGuardService.sanitizeText(content, maxLength: 800, allowNewlines: true);
    final safeAuthor = isAnonymous
        ? ''
        : SecurityGuardService.sanitizeText(authorName, maxLength: 60, allowNewlines: false);
    if (safeTitle.length < 3 || safeContent.length < 5) return;

    try {
      await FirebaseFirestore.instance.collection('prayer_requests').add({
        'title': safeTitle,
        'content': safeContent,
        'isAnonymous': isAnonymous,
        'authorName': safeAuthor,
        'authorUid': user.uid,
        'prayedCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Firestore addPrayerRequest skipped: $e');
    }
  }

  Future<void> incrementPrayedCountInCloud(String docId, int delta) async {
    if (!_isInitialized || docId.startsWith('req_')) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    // Strictly clamp delta to +1 or -1 to match server-side Firestore Rules
    final safeDelta = delta >= 0 ? 1 : -1;
    try {
      await FirebaseFirestore.instance
          .collection('prayer_requests')
          .doc(docId)
          .update({'prayedCount': FieldValue.increment(safeDelta)});
    } catch (_) {}
  }

  String _arabicAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        // Generic message prevents account enumeration attacks
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مسجل بالفعل.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، يُرجى اختيار ٨ أحرف على الأقل تتضمن حروفاً وأرقاماً.';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة.';
      case 'too-many-requests':
        return 'تم تقييد المحاولات مؤقتاً لحماية حسابك. حاول بعد قليل.';
      case 'invalid-verification-code':
        return 'رمز التحقق (OTP) غير صحيح.';
      default:
        return 'تعذر إتمام العملية حالياً. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.';
    }
  }
}
