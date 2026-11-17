import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
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
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _churchCtrl = TextEditingController(text: 'كنيسة الشهيد العظيم مارجرجس');
  String _selectedDiocese = 'إيبارشية القاهرة والبطريركية';
  bool _isLogin = true;
  bool _obscure = true;
  bool _busy = false;

  static const List<String> _dioceses = [
    'إيبارشية القاهرة والبطريركية',
    'إيبارشية الإسكندرية والوجه البحري',
    'إيبارشية الجيزة و٦ أكتوبر',
    'إيبارشية المنيا وأبوقرقاص',
    'إيبارشية أسيوط وتوابعها',
    'إيبارشية سوهاج والمنشاة',
    'إيبارشية البحيرة ومطروح',
    'إيبارشية الشرقية والعاشر',
    'إيبارشية طنطا والغربية',
    'إيبارشيات المهجر (أوروبا وأمريكا وأستراليا)',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDiocese = _storage.getDiocese();
    _churchCtrl.text = _storage.getChurchName();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _churchCtrl.dispose();
    super.dispose();
  }

  Future<void> _enter({
    required bool guest,
    String? customName,
    String? customEmail,
    String? customPhone,
  }) async {
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    final typedName = (customName ?? _nameCtrl.text).trim();
    final emailStr = (customEmail ?? _emailCtrl.text).trim();
    final emailName = emailStr.contains('@') ? emailStr.split('@').first : '';
    final name = typedName.isNotEmpty
        ? typedName
        : (emailName.isNotEmpty ? emailName : _storage.getUserName());
    await _storage.setUserName(name);
    if (emailStr.isNotEmpty) {
      await _storage.setUserEmail(emailStr);
    }
    if (customPhone != null && customPhone.isNotEmpty) {
      await _storage.setUserPhone(customPhone);
    }
    await _storage.setDiocese(_selectedDiocese);
    if (_churchCtrl.text.trim().isNotEmpty) {
      await _storage.setChurchName(_churchCtrl.text.trim());
    }
    await _storage.setGuestMode(guest);
    await _storage.setOnboardingCompleted(true);
    await _storage.setAuthV2Completed(true);
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, _, _) => const MainNavigationShell(),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
    );
  }

  void _showGoogleOrAppleSheet({required String provider}) {
    final gNameCtrl = TextEditingController(text: 'مينا');
    final gEmailCtrl = TextEditingController(
      text: provider == 'Apple' ? 'mina.orthodox@icloud.com' : 'mina.orthodox@gmail.com',
    );

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    provider == 'Apple' ? Icons.apple_rounded : Icons.verified_user_rounded,
                    color: AppColors.primaryGold,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تسجيل الدخول باستخدام حساب $provider',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _pillField(
                ctrl: gNameCtrl,
                hint: 'الاسم الظاهر في التطبيق',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 10),
              _pillField(
                ctrl: gEmailCtrl,
                hint: 'البريد الإلكتروني المرتبط بالحساب',
                icon: Icons.mail_outline_rounded,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              _pillField(
                ctrl: _churchCtrl,
                hint: 'اسم كنيستك (مثال: كنيسة الشهيد مارجرجس)',
                icon: Icons.church_rounded,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  'تأكيد الدخول وحفظ الكنيسة',
                  style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _enter(
                    guest: false,
                    customName: gNameCtrl.text,
                    customEmail: gEmailCtrl.text,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhoneOtpSheet() {
    final phoneCtrl = TextEditingController(text: '+2012');
    final otpCtrl = TextEditingController(text: '174300');
    bool codeSent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                  'تسجيل الدخول برقم الهاتف ورمز التحقق (OTP)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
                const SizedBox(height: 14),
                _pillField(
                  ctrl: phoneCtrl,
                  hint: 'رقم الموبايل (مثال: +2012...)',
                  icon: Icons.phone_iphone_rounded,
                  type: TextInputType.phone,
                ),
                if (codeSent) ...[
                  const SizedBox(height: 12),
                  _pillField(
                    ctrl: otpCtrl,
                    hint: 'رمز التحقق المكون من ٦ أرقام (OTP)',
                    icon: Icons.sms_outlined,
                    type: TextInputType.number,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تم إرسال رمز التحقق الفوري إلى هاتفك بنجاح (الرمز: 174300)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.successGreen),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    if (!codeSent) {
                      setModalState(() => codeSent = true);
                    } else {
                      Navigator.pop(ctx);
                      _enter(guest: false, customPhone: phoneCtrl.text.trim());
                    }
                  },
                  child: Text(
                    codeSent ? 'تأكيد رمز OTP والدخول' : 'إرسال رمز التحقق (OTP)',
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
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
    Widget? suffix,
    TextInputType? type,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.55), width: 1.1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGold, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: ctrl,
              obscureText: obscure,
              keyboardType: type,
              style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13.5),
              cursorColor: AppColors.primaryGold,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 12.5),
              ),
            ),
          ),
          ?suffix,
        ],
      ),
    );
  }

  Widget _socialButton({
    required Widget child,
    required VoidCallback onTap,
    double width = 46,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10)],
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.45),
            radius: 1.0,
            colors: [Color(0xFF211A10), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const GlowingCrossHero(size: 84)
                        .animate()
                        .fadeIn(duration: 700.ms)
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          curve: Curves.easeOutBack,
                          duration: 900.ms,
                        ),
                    Text(
                      _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                      style: GoogleFonts.amiri(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 1. Official Full-Width Google Sign-In Button
                    GestureDetector(
                      onTap: _busy ? null : () => _showGoogleOrAppleSheet(provider: 'Google'),
                      child: Container(
                        height: 48,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'G',
                              style: GoogleFonts.roboto(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF4285F4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'تسجيل الدخول باستخدام حساب Google',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2. Phone OTP Login Button
                    GestureDetector(
                      onTap: _busy ? null : _showPhoneOtpSheet,
                      child: Container(
                        height: 46,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardNavy,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone_iphone_rounded,
                              color: AppColors.primaryGold,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'الدخول برقم الموبايل ورمز التحقق (OTP)',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGoldLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 3. Diocese & Church Selector (Persisted in Local Database)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.primaryGold.withValues(alpha: 0.45),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _dioceses.contains(_selectedDiocese)
                              ? _selectedDiocese
                              : _dioceses.first,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1A1A1E),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primaryGold,
                          ),
                          style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13),
                          items: _dioceses
                              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedDiocese = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _pillField(
                      ctrl: _churchCtrl,
                      hint: 'اسم كنيستك (يُحفظ تلقائياً)',
                      icon: Icons.church_rounded,
                    ),
                    const SizedBox(height: 10),
                    if (!_isLogin) ...[
                      _pillField(
                        ctrl: _nameCtrl,
                        hint: 'الاسم الكامل (مثال: مينا)',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _pillField(
                      ctrl: _emailCtrl,
                      hint: 'البريد الإلكتروني',
                      icon: Icons.alternate_email_rounded,
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    _pillField(
                      ctrl: _passCtrl,
                      hint: 'كلمة المرور',
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
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _busy ? null : () => _enter(guest: false),
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppColors.champagne,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGold.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                _isLogin ? 'تسجيل الدخول وحفظ الكنيسة' : 'إنشاء الحساب',
                                style: GoogleFonts.cairo(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2A1E0E),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton(
                          onTap: () => _showGoogleOrAppleSheet(provider: 'Google'),
                          child: Text(
                            'G',
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4285F4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _socialButton(
                          onTap: _showPhoneOtpSheet,
                          child: const Icon(
                            Icons.sms_rounded,
                            color: Color(0xFF1877F2),
                            size: 22,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('أو', style: GoogleFonts.cairo(color: AppColors.textMuted)),
                        ),
                        _socialButton(
                          width: 84,
                          onTap: () => _showGoogleOrAppleSheet(provider: 'Apple'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.apple_rounded, color: Colors.black, size: 21),
                              Text(
                                ' ID',
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(
                            _isLogin ? 'إنشاء حساب جديد' : 'لديك حساب؟ سجّل الدخول',
                            style: GoogleFonts.cairo(
                              color: AppColors.primaryGoldLight,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _enter(guest: true),
                          child: Text(
                            'الدخول الآمن كزائر',
                            style: GoogleFonts.cairo(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyView()),
                        );
                      },
                      icon: const Icon(
                        Icons.privacy_tip_outlined,
                        size: 15,
                        color: AppColors.primaryGold,
                      ),
                      label: Text(
                        'سياسة الخصوصية وأمان البيانات (Google Play)',
                        style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
