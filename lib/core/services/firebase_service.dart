import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../../models/prayer_request_model.dart';
import 'security_guard_service.dart';
import 'storage_service.dart';

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

/// Unified Firebase Service (Auth + Cloud Firestore) with safe offline-first fallback.
/// Privacy Guarantee: Confession notes & spiritual tracker logs are NEVER uploaded to Firestore.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  bool get isFirebaseReady => _isInitialized;

  User? get currentUser =>
      _isInitialized ? FirebaseAuth.instance.currentUser : null;

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
      // Restore cloud public profile silently if already signed in
      if (FirebaseAuth.instance.currentUser != null) {
        await fetchAndRestorePublicProfile();
      }
    } catch (e) {
      _isInitialized = false;
      if (kDebugMode) {
        debugPrint('Firebase running in local offline-first mode: $e');
      }
    }
  }

  /// Syncs ONLY sanitized non-sensitive public profile fields (display name,
  /// patron saint, and optional Bible reading progress).
  /// Strictly matches Firestore zero-trust schema; NEVER syncs confession notes.
  Future<void> syncPublicProfile({
    required String displayName,
    String? patronSaintId,
    List<String>? completedChapters,
  }) async {
    if (!_isInitialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final safeName = SecurityGuardService.sanitizeText(
      displayName,
      maxLength: 60,
      allowNewlines: false,
    );
    final resolvedSaint = patronSaintId ?? StorageService().getPatronSaintId();
    final safeSaint = SecurityGuardService.sanitizeText(
      resolvedSaint,
      maxLength: 60,
      allowNewlines: false,
    );
    if (safeName.isEmpty) return;

    final payload = <String, dynamic>{
      'displayName': safeName,
      'patronSaintId': safeSaint.isEmpty ? 'virgin_mary' : safeSaint,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (completedChapters != null && completedChapters.length <= 1500) {
      payload['completedChapters'] = completedChapters;
    }

    try {
      await user.updateDisplayName(safeName);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(payload, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('Firestore profile sync skipped: $e');
    }
  }

  /// Restores user's public display name, patron saint, and Bible completed chapters
  /// from Firestore on sign-in or new device startup.
  Future<void> fetchAndRestorePublicProfile() async {
    if (!_isInitialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      final storage = StorageService();
      final cloudName = (data['displayName'] as String? ?? '').trim();
      final cloudSaint = (data['patronSaintId'] as String? ?? '').trim();
      if (cloudName.isNotEmpty) {
        await storage.setUserName(cloudName);
      }
      if (cloudSaint.isNotEmpty) {
        await storage.setPatronSaintId(cloudSaint);
      }
      if (user.email != null && user.email!.isNotEmpty) {
        await storage.setUserEmail(user.email!);
      }

      final cloudChapters = data['completedChapters'];
      if (cloudChapters is List && cloudChapters.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final local =
            (prefs.getStringList('bible_completed_chapters_v1') ?? []).toSet();
        for (final item in cloudChapters) {
          if (item is String && item.isNotEmpty) local.add(item);
        }
        await prefs.setStringList('bible_completed_chapters_v1', local.toList());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Firestore profile restore skipped: $e');
    }
  }

  /// Syncs Bible completed chapters list to user's Firestore profile if signed in.
  Future<void> syncBibleCompletedChapters(List<String> chapters) async {
    if (!_isInitialized) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final storage = StorageService();
    await syncPublicProfile(
      displayName: storage.getUserName(),
      patronSaintId: storage.getPatronSaintId(),
      completedChapters: chapters.take(1500).toList(),
    );
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
        message:
            'عدد محاولات الدخول متكرر جداً. يُرجى الانتظار قليلاً ثم المحاولة مرة أخرى.',
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
        await fetchAndRestorePublicProfile();
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
          : (cred.user?.displayName ??
              (StorageService().hasCustomUserName()
                  ? StorageService().getUserName()
                  : email.split('@').first));

      if (!isLogin || displayName.trim().isNotEmpty) {
        await syncPublicProfile(displayName: resolvedName);
      }

      return FirebaseAuthResult(
        success: true,
        isCloudBacked: true,
        uid: cred.user?.uid,
        displayName: resolvedName,
        email: cred.user?.email ?? email,
        message:
            isLogin ? 'أهلاً بعودتك إلى أرثوذكسيا.' : 'تم إنشاء حسابك بنجاح.',
      );
    } on FirebaseAuthException catch (e) {
      return FirebaseAuthResult(
        success: false,
        isCloudBacked: true,
        message: _arabicAuthError(e.code),
      );
    } catch (_) {
      return const FirebaseAuthResult(
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
        message: 'تعذر الاتصال بخدمة تسجيل الدخول حالياً.',
      );
    }

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '374506508479-1oq4tomh0rjrp2o6voevcvta7l1qa47k.apps.googleusercontent.com',
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

      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      await fetchAndRestorePublicProfile();

      final name = StorageService().hasCustomUserName()
          ? StorageService().getUserName()
          : (userCred.user?.displayName ?? googleUser.displayName ?? '');
      if (name.isNotEmpty) {
        await syncPublicProfile(displayName: name);
      }

      return FirebaseAuthResult(
        success: true,
        isCloudBacked: true,
        uid: userCred.user?.uid,
        displayName: name,
        email: userCred.user?.email ?? googleUser.email,
        message: 'أهلاً بك يا $name!',
      );
    } catch (_) {
      return const FirebaseAuthResult(
        success: false,
        isCloudBacked: true,
        message: 'تعذر إتمام تسجيل الدخول بحساب Google حالياً. حاول مرة أخرى.',
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
      onError('تعذر إرسال رمز التحقق دون اتصال بالإنترنت.');
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          final userCred =
              await FirebaseAuth.instance.signInWithCredential(credential);
          await fetchAndRestorePublicProfile();
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
    } catch (_) {
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
    if (!_isInitialized) {
      return const FirebaseAuthResult(
        success: false,
        isCloudBacked: false,
        message: 'تعذر التحقق من الرمز حالياً.',
      );
    }

    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(cred);
      await fetchAndRestorePublicProfile();
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
        message:
            'تم إرسال طلب استعادة مؤخراً. يرجى الانتظار قليلاً قبل إعادة المحاولة.',
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
        message:
            'إذا كان البريد مسجلاً لدينا، ستصلك رسالة استعادة كلمة المرور خلال لحظات.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return const FirebaseAuthResult(
          success: true,
          isCloudBacked: true,
          message:
              'إذا كان البريد مسجلاً لدينا، ستصلك رسالة استعادة كلمة المرور خلال لحظات.',
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
    if (_isInitialized) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    final storage = StorageService();
    await storage.setGuestMode(true);
    await storage.setUserEmail('');
    await storage.setUserPhone('');
  }

  /// Permanently deletes the user's cloud profile doc, Firebase Auth account,
  /// and ALL local encrypted device data & hardware encryption key.
  /// Returns `null` on success, or an Arabic explanation message on error.
  Future<String?> deleteAccountCompletely() async {
    if (_isInitialized) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();
        } catch (_) {}
        try {
          await user.delete();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            return 'لحماية حسابك، يُرجى تسجيل الخروج ثم الدخول مجدداً قبل حذف الحساب السحابي نهائياً.';
          }
          return _arabicAuthError(e.code);
        } catch (_) {}
      }
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    await StorageService().deleteAllUserData();
    return null;
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
                  authorUid: '${d['authorUid'] ?? ''}',
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

  /// Posts a prayer request to Firestore. Returns `null` on success or an Arabic
  /// error message if blocked/unauthenticated/offline.
  Future<String?> addPrayerRequestToCloud({
    required String title,
    required String content,
    required bool isAnonymous,
    required String authorName,
  }) async {
    if (!_isInitialized) {
      return 'تعذر الاتصال بالسحابة حالياً. تأكد من اتصالك بالإنترنت.';
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return 'يرجى تسجيل الدخول بحسابك أولاً لنشر طلبة صلاة على حائط الصلاة المشترك.';
    }

    if (!SecurityGuardService().allowAction(
      'prayer_wall_post',
      cooldown: const Duration(seconds: 15),
      maxPerWindow: 4,
      window: const Duration(minutes: 10),
    )) {
      return 'يرجى الانتظار بضع ثوانٍ قبل إرسال طلبة صلاة جديدة.';
    }

    final safeTitle = SecurityGuardService.sanitizeText(title,
        maxLength: 120, allowNewlines: false);
    final safeContent = SecurityGuardService.sanitizeText(content,
        maxLength: 800, allowNewlines: true);
    final safeAuthor = isAnonymous
        ? ''
        : SecurityGuardService.sanitizeText(authorName,
            maxLength: 60, allowNewlines: false);
    if (safeTitle.length < 3) {
      return 'يرجى كتابة عنوان واضح لطلبة الصلاة (٣ أحرف على الأقل).';
    }
    if (safeContent.length < 5) {
      return 'يرجى كتابة تفاصيل طلبة الصلاة (٥ أحرف على الأقل).';
    }

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
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Firestore addPrayerRequest error: $e');
      return 'تعذر نشر طلبة الصلاة حالياً. تأكد من اتصالك بالإنترنت.';
    }
  }

  Future<bool> deletePrayerRequestFromCloud(String docId) async {
    if (!_isInitialized || docId.startsWith('req_')) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      await FirebaseFirestore.instance
          .collection('prayer_requests')
          .doc(docId)
          .delete();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Firestore deletePrayerRequest error: $e');
      return false;
    }
  }

  Future<void> incrementPrayedCountInCloud(String docId, int delta) async {
    if (!_isInitialized || docId.startsWith('req_')) return;
    if (FirebaseAuth.instance.currentUser == null) return;
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
        return 'رمز التحقق غير صحيح.';
      default:
        return 'تعذر إتمام العملية حالياً. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.';
    }
  }
}
