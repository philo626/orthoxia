import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/patron_saint_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/coptic_cross.dart';
import '../main_navigation_shell.dart';
import '../profile/privacy_policy_view.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final StorageService _storage = StorageService();
  final FirebaseService _firebase = FirebaseService();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  late String _selectedSaintId;
  bool _isLogin = false; // Default to quick account creation so user clearly sees Name field!
  bool _obscure = true;
  bool _busy = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _selectedSaintId = _storage.getPatronSaintId();
    if (_storage.hasCustomUserName()) {
      _nameCtrl.text = _storage.getUserName();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeEntry({
    required bool guest,
    required String resolvedName,
    String? email,
    String? phone,
  }) async {
    final finalName = resolvedName.trim().isNotEmpty ? resolvedName.trim() : 'صديق أرثوذكسيا';
    await _storage.setUserName(finalName);
    if (email != null && email.trim().isNotEmpty) {
      await _storage.setUserEmail(email.trim());
    }
    if (phone != null && phone.trim().isNotEmpty) {
      await _storage.setUserPhone(phone.trim());
    }
    await _storage.setPatronSaintId(_selectedSaintId);
    await _storage.setGuestMode(guest);
    await _storage.setOnboardingCompleted(true);
    await _storage.setAuthV2Completed(true);

    if (!guest) {
      await _firebase.syncPublicProfile(
        displayName: finalName,
        patronSaintId: _selectedSaintId,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, _, _) => const MainNavigationShell(),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  Future<void> _submitEmailAuth() async {
    HapticFeedback.mediumImpact();
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (!_isLogin && name.isEmpty) {
      setState(() => _errorMsg = 'من فضلك اكتب اسمك أولاً ليرحب بك التطبيق باسمك.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'من فضلك أدخل بريدك الإلكتروني بشكل صحيح.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorMsg = 'كلمة المرور يجب أن تكون ٦ أحرف على الأقل.');
      return;
    }

    setState(() {
      _busy = true;
      _errorMsg = null;
    });

    final res = await _firebase.signInOrRegisterWithEmail(
      email: email,
      password: pass,
      displayName: name,
      isLogin: _isLogin,
    );

    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _busy = false;
        _errorMsg = res.message;
      });
      return;
    }

    await _completeEntry(
      guest: false,
      resolvedName: res.displayName ?? name,
      email: res.email ?? email,
    );
  }

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _errorMsg = null;
    });

    if (_firebase.isFirebaseReady) {
      final res = await _firebase.signInWithGoogle();
      if (!mounted) return;
      if (res.success) {
        final chosenName = _nameCtrl.text.trim().isNotEmpty
            ? _nameCtrl.text.trim()
            : (res.displayName ?? '');
        await _completeEntry(
          guest: false,
          resolvedName: chosenName,
          email: res.email,
        );
        return;
      } else {
        setState(() {
          _busy = false;
          _errorMsg = res.message;
        });
        return;
      }
    }

    // Graceful sheet if google-services.json isn't added yet
    setState(() => _busy = false);
    if (!mounted) return;
    _showQuickGoogleNameSheet();
  }

  void _showQuickGoogleNameSheet() {
    final gNameCtrl = TextEditingController(text: _nameCtrl.text.trim());
    final gEmailCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF161619),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.45)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'الدخول السريع بحساب Google',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGoldLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'أدخل اسمك وبريدك الجيميل (تُفعّل المزامنة السحابية تلقائياً فور ربط ملف Firebase)',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              _pillField(ctrl: gNameCtrl, hint: 'اكتب اسمك هنا...', icon: Icons.person_outline_rounded),
              const SizedBox(height: 10),
              _pillField(
                ctrl: gEmailCtrl,
                hint: 'بريدك الإلكتروني (example@gmail.com)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _completeEntry(
                    guest: false,
                    resolvedName: gNameCtrl.text.trim(),
                    email: gEmailCtrl.text.trim(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('متابعة الدخول', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhoneOtpSheet() {
    final phoneCtrl = TextEditingController(text: '+20');
    final otpCtrl = TextEditingController();
    String? verificationId;
    bool sending = false;
    String? sheetErr;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF161619),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.45)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'تسجيل الدخول برقم الهاتف (OTP)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
                const SizedBox(height: 12),
                if (sheetErr != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      sheetErr!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(fontSize: 12, color: Colors.redAccent),
                    ),
                  ),
                _pillField(
                  ctrl: phoneCtrl,
                  hint: '+2010xxxxxxxx',
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                ),
                if (verificationId != null) ...[
                  const SizedBox(height: 10),
                  _pillField(
                    ctrl: otpCtrl,
                    hint: 'أدخل رمز التحقق (٦ أرقام)',
                    icon: Icons.sms_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: sending
                      ? null
                      : () async {
                          if (verificationId == null) {
                            setSheet(() {
                              sending = true;
                              sheetErr = null;
                            });
                            await _firebase.verifyPhoneNumber(
                              phoneNumber: phoneCtrl.text.trim(),
                              onCodeSent: (vId) => setSheet(() {
                                verificationId = vId;
                                sending = false;
                              }),
                              onError: (err) => setSheet(() {
                                sheetErr = err;
                                sending = false;
                              }),
                              onAutoVerified: (res) {
                                Navigator.pop(ctx);
                                _completeEntry(
                                  guest: false,
                                  resolvedName: _nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                );
                              },
                            );
                          } else {
                            setSheet(() => sending = true);
                            final res = await _firebase.confirmPhoneOtp(
                              verificationId: verificationId!,
                              smsCode: otpCtrl.text.trim(),
                              displayName: _nameCtrl.text.trim(),
                              phoneNumber: phoneCtrl.text.trim(),
                            );
                            if (res.success) {
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _completeEntry(
                                guest: false,
                                resolvedName: _nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                              );
                            } else {
                              setSheet(() {
                                sending = false;
                                sheetErr = res.message;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    verificationId == null ? 'إرسال رمز التحقق' : 'تأكيد الدخول',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Brand Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGold.withValues(alpha: 0.14),
                        border: Border.all(color: AppColors.primaryGold, width: 1.5),
                      ),
                      child: const CopticCross(size: 34),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'أهلاً بك في أرثوذكسيا',
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'رفيقك اليومي للقداس والسنكسار والأجبية وشفيعك الشخصي',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms),

              const SizedBox(height: 22),

              // 1. User's Own Name Field (Always prominent & editable!)
              Text(
                'اسمك الشخصي (سيظهر للترحيب بك في التطبيق):',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGoldLight,
                ),
              ),
              const SizedBox(height: 8),
              _pillField(
                ctrl: _nameCtrl,
                hint: 'اكتب اسمك هنا (مثال: كيرلس، مريم...)',
                icon: Icons.person_rounded,
              ),

              const SizedBox(height: 18),

              // 2. Choose Personal Patron Saint (شفيعك الشخصي)
              Text(
                'اختر شفيعك الشخصي (لتصلك أقواله يومياً):',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGoldLight,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: PatronSaintService.saints.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final s = PatronSaintService.saints[idx];
                    final sel = s.id == _selectedSaintId;
                    return ChoiceChip(
                      label: Text(
                        '${s.iconEmoji} ${s.shortName}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: sel ? Colors.black : AppColors.textLight,
                        ),
                      ),
                      selected: sel,
                      selectedColor: AppColors.primaryGold,
                      backgroundColor: AppColors.cardNavy,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedSaintId = s.id);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 3. Login / Register Mode Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.cardNavy,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _modeTab('إنشاء حساب جديد', !_isLogin, () => setState(() => _isLogin = false)),
                    ),
                    Expanded(
                      child: _modeTab('تسجيل الدخول', _isLogin, () => setState(() => _isLogin = true)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (_errorMsg != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.redAccent),
                  ),
                ),

              _pillField(
                ctrl: _emailCtrl,
                hint: 'البريد الإلكتروني',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              _pillField(
                ctrl: _passCtrl,
                hint: 'كلمة المرور (٦ أحرف على الأقل)',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textMuted,
                    size: 19,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),

              const SizedBox(height: 16),

              // Primary Submit Button
              ElevatedButton(
                onPressed: _busy ? null : _submitEmailAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.black),
                      )
                    : Text(
                        _isLogin ? 'تسجيل الدخول عبر Firebase' : 'إنشاء حساب والبدء الآن',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
              ),

              const SizedBox(height: 14),

              // Social / OTP Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _handleGoogleSignIn,
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 24, color: AppColors.primaryGold),
                      label: Text('حساب Google', style: GoogleFonts.cairo(color: Colors.white, fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _showPhoneOtpSheet,
                      icon: const Icon(Icons.phone_android_rounded, size: 18, color: AppColors.primaryGold),
                      label: Text('رقم الهاتف OTP', style: GoogleFonts.cairo(color: Colors.white, fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Guest Mode Entry (Respects user's entered name!)
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => _completeEntry(
                          guest: true,
                          resolvedName: _nameCtrl.text.trim(),
                        ),
                icon: const Icon(Icons.explore_outlined, color: AppColors.primaryGoldLight, size: 18),
                label: Text(
                  'تصفح التطبيق مباشرة بدون حساب (وضع الزائر)',
                  style: GoogleFonts.cairo(
                    color: AppColors.primaryGoldLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Privacy Policy Link (Google Play compliance)
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyView()),
                  ),
                  child: Text(
                    'سياسة الخصوصية وأمان مذكرات الاعتراف (AES-256 محلياً)',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: active ? Colors.black : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _pillField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.25)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.cairo(color: Colors.white, fontSize: 13.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.primaryGold, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }
}
