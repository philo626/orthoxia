import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/patron_saint_service.dart';
import '../../core/services/security_guard_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_marks.dart';
import '../../core/widgets/saint_icon_avatar.dart';
import '../../providers/theme_provider.dart';
import '../confession/fathers_directory_view.dart';
import '../confession/priest_dashboard_view.dart';
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
  String _selectedRole = 'member'; // 'member' = فرد من الشعب | 'priest' = أب كاهن
  int _step = 0; // 0 = Clean Sign-In / Sign-Up, 1 = Serene Personalization (Name + Patron Saint)
  bool _isLogin = true;
  bool _obscure = true;
  bool _busy = false;
  bool _pendingGuest = false;
  String? _pendingEmail;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _selectedSaintId = _storage.getPatronSaintId();
    _selectedRole = _storage.getUserRole();
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

  void _proceedToPersonalization({
    required bool guest,
    String? resolvedName,
    String? email,
  }) {
    if (resolvedName != null && resolvedName.trim().isNotEmpty) {
      _nameCtrl.text = resolvedName.trim();
    }
    _pendingGuest = guest;
    _pendingEmail = email;

    // If returning user already personalized before and logged in again, enter directly
    if (_storage.isOnboardingCompleted() && !guest && _nameCtrl.text.trim().isNotEmpty) {
      _finalizeAndEnter();
      return;
    }

    setState(() {
      _busy = false;
      _errorMsg = null;
      _step = 1;
    });
  }

  Future<void> _finalizeAndEnter() async {
    setState(() => _busy = true);
    final rawName = SecurityGuardService.sanitizeText(
      _nameCtrl.text,
      maxLength: 60,
      allowNewlines: false,
    );
    final finalName = rawName.isNotEmpty ? rawName : 'صديق أرثوذكسيا';

    await _storage.setUserName(finalName);
    await _storage.setUserRole(_selectedRole);
    if (_pendingEmail != null && _pendingEmail!.trim().isNotEmpty) {
      await _storage.setUserEmail(_pendingEmail!.trim());
    }
    await _storage.setPatronSaintId(_selectedSaintId);
    await _storage.setGuestMode(_pendingGuest);
    await _storage.setOnboardingCompleted(true);
    await _storage.setAuthV2Completed(true);

    if (!_pendingGuest) {
      await _firebase.syncPublicProfile(
        displayName: finalName,
        patronSaintId: _selectedSaintId,
      );
    }

    if (!mounted) return;
    final openPriestPortal = _selectedRole == 'priest' && !_pendingGuest;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const MainNavigationShell(),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    );
    if (openPriestPortal) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PriestDashboardView()),
          );
        }
      });
    }
  }

  Future<void> _submitEmailAuth() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (!_isLogin && name.isEmpty) {
      setState(() => _errorMsg = 'من فضلك اكتب اسمك أولاً.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'من فضلك أدخل بريدك الإلكتروني بشكل صحيح.');
      return;
    }
    if (!_isLogin) {
      final passErr = SecurityGuardService.validateNewPassword(pass);
      if (passErr != null) {
        setState(() => _errorMsg = passErr);
        return;
      }
    } else if (pass.length < 6) {
      setState(() => _errorMsg = 'من فضلك أدخل كلمة المرور بشكل صحيح.');
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

    _proceedToPersonalization(
      guest: false,
      resolvedName: res.displayName ?? name,
      email: res.email ?? email,
    );
  }

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _errorMsg = null;
    });

    if (_firebase.isFirebaseReady) {
      final res = await _firebase.signInWithGoogle();
      if (!mounted) return;
      if (res.success) {
        _proceedToPersonalization(
          guest: false,
          resolvedName: res.displayName ?? _nameCtrl.text.trim(),
          email: res.email,
        );
        return;
      }
      setState(() {
        _busy = false;
        _errorMsg = res.message;
      });
      return;
    }

    setState(() {
      _busy = false;
      _errorMsg = 'تعذر الاتصال بخدمة Google حالياً. يمكنك الدخول بالبريد الإلكتروني أو المتابعة كزائر.';
    });
  }

  void _showForgotPasswordSheet() {
    final resetCtrl = TextEditingController(text: _emailCtrl.text.trim());
    bool sending = false;
    String? feedback;
    bool isSuccess = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final p = ctx.palette;
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: p.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'استعادة كلمة المرور',
                    style: GoogleFonts.amiri(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'أدخل بريدك الإلكتروني المسجّل وسنرسل لك رابطاً لتعيين كلمة مرور جديدة.',
                    style: GoogleFonts.cairo(fontSize: 13, color: p.inkSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                    ),
                  ),
                  if (feedback != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: (isSuccess ? p.sage : p.danger).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        feedback!,
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          color: isSuccess ? p.sage : p.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: sending
                        ? null
                        : () async {
                            setSheet(() {
                              sending = true;
                              feedback = null;
                            });
                            final res = await _firebase.sendPasswordResetEmail(resetCtrl.text);
                            if (!ctx.mounted) return;
                            setSheet(() {
                              sending = false;
                              isSuccess = res.success;
                              feedback = res.message;
                            });
                          },
                    child: sending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: p.onAccent),
                          )
                        : const Text('إرسال رابط الاستعادة'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final themeProv = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: p.canvas,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SubtleArchWatermark(height: 170),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    // Quiet top bar: subtle Day/Night switch + back on Step 2
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_step == 1)
                            IconButton(
                              onPressed: () => setState(() => _step = 0),
                              icon: Icon(Icons.arrow_forward_rounded, color: p.ink),
                              tooltip: 'رجوع',
                            )
                          else
                            const SizedBox(width: 40),
                          TextButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              themeProv.setThemeMode(
                                p.isDark ? AppThemeMode.lightParchment : AppThemeMode.darkGold,
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: p.inkSecondary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: Icon(
                              p.isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                              size: 17,
                            ),
                            label: Text(
                              p.isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 360),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _step == 0
                            ? _buildAuthStep(p)
                            : _buildPersonalizeStep(p),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthStep(AppPalette p) {
    return SingleChildScrollView(
      key: const ValueKey('auth_step_0'),
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand Identity
          Column(
            children: [
              const OrthodoxEmblem(size: 68),
              const SizedBox(height: 14),
              Text(
                'أرثوذكسيا',
                style: GoogleFonts.amiri(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: p.ink,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'صلواتك اليومية، القداس الإلهي، والكتاب المقدس',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: p.inkSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Main Elevated Auth Surface
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: p.border),
              boxShadow: [
                BoxShadow(
                  color: p.shadow,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role Selector (Page 01/04: فرد من الشعب vs أب كاهن)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: p.surfaceSubtle,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _segmentedTab(
                          p: p,
                          label: 'دخول كفرد من الشعب',
                          active: _selectedRole == 'member',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedRole = 'member');
                          },
                        ),
                      ),
                      Expanded(
                        child: _segmentedTab(
                          p: p,
                          label: 'دخول كأب كاهن',
                          active: _selectedRole == 'priest',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedRole = 'priest');
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                if (_selectedRole == 'priest') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.goldSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.goldBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أهلاً بيك يا قدس أبونا — التطبيق نوّر بوجود قدسك',
                          style: GoogleFonts.amiri(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: p.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'بعد تسجيل الدخول، تقدر تكمّل توثيق صفة الكهنوت وتفتح مواعيد الاعتراف وتستخدم مكتبة أبونا الليتورجية فوراً.',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: p.inkSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // 1. Authentic One-Tap Google Sign-In
                OutlinedButton(
                  onPressed: _busy ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: p.isDark ? p.surfaceSubtle : Colors.white,
                    foregroundColor: p.ink,
                    side: BorderSide(color: p.border, width: 1.1),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GoogleLogoMark(size: 20),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'المتابعة بحساب Google',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: p.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Subtle Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: p.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'أو بالبريد الإلكتروني',
                        style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                      ),
                    ),
                    Expanded(child: Divider(color: p.border)),
                  ],
                ),

                const SizedBox(height: 16),

                // Smooth Segmented Switcher (Login / Create Account)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: p.surfaceSubtle,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _segmentedTab(
                          p: p,
                          label: 'تسجيل الدخول',
                          active: _isLogin,
                          onTap: () => setState(() {
                            _isLogin = true;
                            _errorMsg = null;
                          }),
                        ),
                      ),
                      Expanded(
                        child: _segmentedTab(
                          p: p,
                          label: 'حساب جديد',
                          active: !_isLogin,
                          onTap: () => setState(() {
                            _isLogin = false;
                            _errorMsg = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (_errorMsg != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: p.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 17, color: p.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: GoogleFonts.cairo(fontSize: 12.5, color: p.danger),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Name field ONLY when registering
                if (!_isLogin) ...[
                  TextField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'الاسم الكامل',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitEmailAuth(),
                  style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _isLogin ? 'كلمة المرور' : 'كلمة المرور (٨ أحرف بحروف وأرقام)',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: p.inkMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),

                if (_isLogin)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _busy ? null : _showForgotPasswordSheet,
                      style: TextButton.styleFrom(
                        foregroundColor: p.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'نسيت كلمة المرور؟',
                        style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 14),

                const SizedBox(height: 8),

                ElevatedButton(
                  onPressed: _busy ? null : _submitEmailAuth,
                  child: _busy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: p.onAccent),
                        )
                      : Text(_isLogin ? 'تسجيل الدخول' : 'إنشاء الحساب'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Quiet Secondary Action (Guest Mode — 100% reliable without blocked paid SMS OTP)
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _proceedToPersonalization(guest: true),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
              backgroundColor: p.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: Icon(Icons.arrow_back_rounded, size: 17, color: p.inkSecondary),
            label: Text(
              'متابعة كزائر',
              style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.ink),
            ),
          ),

          const SizedBox(height: 18),

          // Calm Human Privacy Footer
          Center(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyView()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Text(
                  'بياناتك ومذكراتك محفوظة بخصوصية تامة • سياسة الخصوصية',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: p.inkMuted,
                    decoration: TextDecoration.underline,
                    decorationColor: p.inkMuted.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizeStep(AppPalette p) {
    final featuredSaints = PatronSaintService.saints.take(14).toList();

    return SingleChildScrollView(
      key: const ValueKey('auth_step_1'),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'أهلاً بك في أرثوذكسيا',
            style: GoogleFonts.amiri(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'خطوة سريعة لنخصّص لك التحية اليومية وأقوال شفيعك الشخصي.',
            style: GoogleFonts.cairo(fontSize: 13.5, color: p.inkSecondary, height: 1.55),
          ),

          const SizedBox(height: 24),

          Text(
            'كيف نحب أن نناديك؟',
            style: GoogleFonts.cairo(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: GoogleFonts.cairo(color: p.ink, fontSize: 14.5),
            decoration: const InputDecoration(
              hintText: 'مثال: كيرلس، مريم، مينا...',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: Text(
                  'اختر شفيعك الشخصي',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: p.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'يمكنك تغييره لاحقاً',
                style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 144,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: featuredSaints.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final s = featuredSaints[idx];
                final selected = s.id == _selectedSaintId;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedSaintId = s.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 106,
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                    decoration: BoxDecoration(
                      color: selected ? p.goldSoft : p.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? p.accent : p.border,
                        width: selected ? 1.6 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SaintIconAvatar(
                              imageUrl: PatronSaintService.getImageUrlForSaint(s),
                              size: 62,
                              shape: SaintAvatarShape.arch,
                              showBorder: true,
                            ),
                            if (selected)
                              Positioned(
                                top: -4,
                                left: -4,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: p.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: p.onAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.shortName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                            color: selected ? p.accent : p.ink,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 22),

          if (_selectedRole == 'member') ...[
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                HapticFeedback.selectionClick();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FathersDirectoryView(isFirstTimeFlow: true),
                  ),
                );
                if (mounted) setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.goldBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.church_outlined, color: p.accent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _storage.getConfessionFatherName().isNotEmpty
                                ? 'أب اعترافي: ${_storage.getConfessionFatherName()}'
                                : 'اختيار أب الاعتراف (اختياري)',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                            ),
                          ),
                          Text(
                            _storage.getConfessionFatherChurch().isNotEmpty
                                ? _storage.getConfessionFatherChurch()
                                : 'تقدر تختار قدسه دلوقتي أو تختار بعدين في أي وقت',
                            style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_left_rounded, color: p.accent),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ] else
            const SizedBox(height: 10),

          ElevatedButton(
            onPressed: _busy ? null : _finalizeAndEnter,
            child: _busy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: p.onAccent),
                  )
                : const Text('البدء الآن'),
          ),
        ],
      ),
    );
  }

  Widget _segmentedTab({
    required AppPalette p,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? p.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active && !p.isDark
              ? [
                  BoxShadow(
                    color: p.shadow,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.w600,
            color: active ? p.ink : p.inkMuted,
          ),
        ),
      ),
    );
  }
}
