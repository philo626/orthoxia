import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/confession_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/patron_saint_service.dart';
import '../../core/services/security_guard_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_marks.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/diocese_church_picker.dart';
import '../../core/widgets/saint_icon_avatar.dart';
import '../../models/confession_models.dart';
import '../../providers/theme_provider.dart';
import '../confession/fathers_directory_view.dart';
import '../main_navigation_shell.dart';
import '../priest/priest_navigation_shell.dart';
import '../profile/privacy_policy_view.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> with TickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final FirebaseService _firebase = FirebaseService();
  final ConfessionService _confession = ConfessionService();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  late String _selectedSaintId;
  String _selectedRole = 'member'; // 'member' = فرد من الشعب | 'priest' = أب كاهن
  String _priestTitlePrefix = 'القس';
  String _selectedDiocese = CopticDiocesesCatalog.dioceses.first;
  String _selectedChurch = CopticDiocesesCatalog.churchesFor(CopticDiocesesCatalog.dioceses.first).first;

  int _step = 0; // 0 = Cinematic Christ Welcome & Sign-In, 1 = Role-Aware Setup
  bool _isLogin = true;
  bool _obscure = true;
  bool _busy = false;
  bool _pendingGuest = false;
  String? _pendingEmail;
  String? _errorMsg;

  late final AnimationController _ambientCtrl;
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _selectedSaintId = _storage.getPatronSaintId();
    _selectedRole = _storage.getUserRole();
    _priestTitlePrefix = _storage.getPriestTitlePrefix();
    final savedDiocese = _storage.getPriestDiocese();
    if (CopticDiocesesCatalog.dioceses.contains(savedDiocese)) {
      _selectedDiocese = savedDiocese;
    }
    final savedChurch = _storage.getPriestChurch();
    _selectedChurch = savedChurch.isNotEmpty
        ? savedChurch
        : CopticDiocesesCatalog.churchesFor(_selectedDiocese).first;
    if (_storage.hasCustomUserName()) {
      _nameCtrl.text = _storage.getUserName();
    }

    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _entryCtrl.dispose();
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

    // Returning user logging back in with saved profile enters their role-specific app immediately!
    if (_storage.isOnboardingCompleted() &&
        !guest &&
        _nameCtrl.text.trim().isNotEmpty &&
        (_selectedRole == 'member' || _storage.getPriestChurch().isNotEmpty)) {
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
    final isPriest = _selectedRole == 'priest';
    final finalName = rawName.isNotEmpty
        ? rawName
        : (isPriest ? 'أبونا الحبيب' : 'صديق أرثوذكسيا');

    await _storage.setUserName(finalName);
    await _storage.setUserRole(_selectedRole);
    if (_pendingEmail != null && _pendingEmail!.trim().isNotEmpty) {
      await _storage.setUserEmail(_pendingEmail!.trim());
    }
    await _storage.setPatronSaintId(_selectedSaintId);
    await _storage.setGuestMode(_pendingGuest);
    await _storage.setOnboardingCompleted(true);
    await _storage.setAuthV2Completed(true);

    if (isPriest) {
      await _storage.setPriestTitlePrefix(_priestTitlePrefix);
      await _storage.setPriestDiocese(_selectedDiocese);
      final churchClean = _selectedChurch.trim();
      if (churchClean.isNotEmpty) {
        await _storage.setPriestChurch(churchClean);
      }
      await _confession.ensureLocalPrivateCode();

      // If signed in and church selected, sync initial Priest Profile + Private Code immediately
      if (!_pendingGuest && churchClean.length >= 2 && finalName.length >= 2) {
        await _confession.submitOrUpdatePriestVerification(
          titlePrefix: _priestTitlePrefix,
          displayName: finalName,
          diocese: _selectedDiocese,
          church: churchClean,
        );
      }
    } else if (!_pendingGuest) {
      await _firebase.syncPublicProfile(
        displayName: finalName,
        patronSaintId: _selectedSaintId,
      );
    }

    if (!mounted) return;
    // DIRECTLY launch the dedicated Priest App Shell OR the Congregation App Shell!
    final Widget destination = isPriest
        ? const PriestNavigationShell()
        : const MainNavigationShell();

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => destination,
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
      (_) => false,
    );
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
          // Cinematic Sacred Top Backdrop with Animated Golden Motes
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _step == 0 ? 370 : 210,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 420),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _selectedRole == 'priest'
                      ? const [
                          Color(0xFF281912),
                          Color(0xFF1C130E),
                          Color(0xFF120D0A),
                        ]
                      : const [
                          Color(0xFF1D1510),
                          Color(0xFF15100C),
                          Color(0xFF0E0B08),
                        ],
                ),
              ),
              child: AnimatedBuilder(
                animation: _ambientCtrl,
                builder: (_, _) => CustomPaint(
                  painter: _GoldenIncenseMotesPainter(progress: _ambientCtrl.value),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    // Contemporary Translucent Top Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_step == 1)
                            IconButton(
                              onPressed: () => setState(() => _step = 0),
                              icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFF6ECDC)),
                              tooltip: 'رجوع',
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFD8B46C).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CopticCross(size: 13, color: Color(0xFFE5C175)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'أرثوذكسيا',
                                    style: GoogleFonts.amiri(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFF8F0E0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              themeProv.setThemeMode(
                                p.isDark ? AppThemeMode.lightParchment : AppThemeMode.darkGold,
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFEBD9B7),
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: Icon(
                              p.isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                              size: 16,
                            ),
                            label: Text(
                              p.isDark ? 'نهاري' : 'ليلي',
                              style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 380),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _step == 0
                            ? _buildCinematicAuthStep(p)
                            : _buildRoleAwarePersonalizeStep(p),
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

  Widget _buildCinematicAuthStep(AppPalette p) {
    final fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);

    return SingleChildScrollView(
      key: const ValueKey('auth_step_0'),
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 28),
      child: FadeTransition(
        opacity: fadeAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ANIMATED LORD JESUS CHRIST HERO MEDALLION
            _buildAnimatedChristHero(),

            const SizedBox(height: 14),

            // 2. CONTEMPORARY FLOATING AUTH CARD
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: _selectedRole == 'priest' ? p.goldBorder : p.border,
                  width: _selectedRole == 'priest' ? 1.4 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: p.isDark ? 0.45 : 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'اختر نوع حسابك',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: p.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Modern Visual Dual-Role Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoleTile(
                          p: p,
                          active: _selectedRole == 'member',
                          icon: Icons.menu_book_rounded,
                          title: 'فرد من الشعب',
                          subtitle: 'صلواتي • الكتاب • أب اعترافي',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedRole = 'member');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildRoleTile(
                          p: p,
                          active: _selectedRole == 'priest',
                          icon: Icons.church_rounded,
                          title: 'أب كاهن',
                          subtitle: 'المذبح • الاعترافات • الافتقاد',
                          isPriestCard: true,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedRole = 'priest');
                          },
                        ),
                      ),
                    ],
                  ),

                  // Animated Dignified Welcome Strip for Priest Mode
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: _selectedRole == 'priest'
                        ? Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: p.goldSoft,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: p.goldBorder),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: CopticCross(size: 18, color: p.gold),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'سلام ونعمة يا قدس أبونا',
                                        style: GoogleFonts.amiri(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: p.ink,
                                        ),
                                      ),
                                      Text(
                                        'سيفتح التطبيق مباشرة بواجهة خاصة لخدمة قدسك: الخولاجي السري، جدول الاعترافات، أسماء المذبح، ودفتر الافتقاد.',
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
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 16),

                  // 1-Tap Google Sign-In
                  OutlinedButton(
                    onPressed: _busy ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: p.isDark ? p.surfaceSubtle : Colors.white,
                      foregroundColor: p.ink,
                      side: BorderSide(color: p.border, width: 1.1),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GoogleLogoMark(size: 20),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _selectedRole == 'priest'
                                ? 'دخول قدسك بحساب Google'
                                : 'المتابعة بحساب Google',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: Divider(color: p.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'أو بالبريد الإلكتروني',
                          style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                        ),
                      ),
                      Expanded(child: Divider(color: p.border)),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Login / Create Account Segmented Switch
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

                  const SizedBox(height: 14),

                  if (_errorMsg != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
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

                  if (!_isLogin) ...[
                    TextField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _selectedRole == 'priest'
                            ? 'اسم قدسك الكامل (مثال: بولس جرجس)'
                            : 'الاسم الكامل',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 11),
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

                  const SizedBox(height: 11),

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
                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),

                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: _busy ? null : _submitEmailAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedRole == 'priest' ? p.gold : p.accent,
                      foregroundColor: _selectedRole == 'priest' ? const Color(0xFF19130A) : p.onAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : Text(
                            _isLogin
                                ? (_selectedRole == 'priest' ? 'دخول بوابة الأب الكاهن' : 'تسجيل الدخول')
                                : (_selectedRole == 'priest' ? 'إنشاء حساب أب كاهن' : 'إنشاء الحساب'),
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Secondary Guest / Preview Entry (respects chosen role so user can explore Priest Portal too!)
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _proceedToPersonalization(guest: true),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                backgroundColor: p.surface,
                side: BorderSide(color: p.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              icon: Icon(Icons.arrow_back_rounded, size: 17, color: p.inkSecondary),
              label: Text(
                _selectedRole == 'priest'
                    ? 'معاينة بوابة الأب الكاهن كزائر'
                    : 'متابعة كزائر بدون تسجيل',
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink),
              ),
            ),

            const SizedBox(height: 12),

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
      ),
    );
  }

  /// Luminous Animated Lord Jesus Christ Hero Medallion with Breathing Halo & Rotating Rays
  Widget _buildAnimatedChristHero() {
    return AnimatedBuilder(
      animation: _ambientCtrl,
      builder: (_, child) {
        final t = _ambientCtrl.value;
        final wave = math.sin(t * 2 * math.pi);
        final pulse = 0.5 + 0.5 * math.sin(t * 4 * math.pi);
        final floatY = wave * 3.5;
        final imgScale = 1.0 + 0.045 * (0.5 + 0.5 * math.cos(t * 2 * math.pi));

        return Column(
          children: [
            SizedBox(
              height: 186,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Soft pulsing golden aura
                  Container(
                    width: 172 + pulse * 18,
                    height: 172 + pulse * 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFE8C476).withValues(alpha: 0.38 + pulse * 0.14),
                          const Color(0xFFB38634).withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Slowly turning sacred Byzantine/Coptic halo rays
                  Transform.rotate(
                    angle: t * 2 * math.pi,
                    child: CustomPaint(
                      size: const Size(182, 182),
                      painter: _SacredChristHaloPainter(),
                    ),
                  ),

                  // Floating Arched Medallion of Lord Jesus Christ Pantocrator
                  Transform.translate(
                    offset: Offset(0, floatY),
                    child: Container(
                      width: 138,
                      height: 152,
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(72),
                          bottom: Radius.circular(26),
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF6DB9C),
                            Color(0xFFC29542),
                            Color(0xFF704D18),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE3BD6E).withValues(alpha: 0.32),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(69),
                          bottom: Radius.circular(23),
                        ),
                        child: Transform.scale(
                          scale: imgScale,
                          child: Image.asset(
                            'assets/images/christ_pantocrator.jpg',
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            child!,
          ],
        );
      },
      child: Column(
        children: [
          Text(
            'أرثوذكسيا',
            style: GoogleFonts.amiri(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFBF3E4),
              height: 1.05,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE5C175).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE5C175).withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              '«أَنَا هُوَ نُورُ الْعَالَمِ»  •  يو ٨: ١٢',
              style: GoogleFonts.amiri(
                fontSize: 15,
                color: const Color(0xFFF4DCAA),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTile({
    required AppPalette p,
    required bool active,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPriestCard = false,
  }) {
    final activeBorder = isPriestCard ? p.gold : p.accent;
    final activeFill = isPriestCard ? p.goldSoft : p.accent.withValues(alpha: p.isDark ? 0.18 : 0.08);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: active ? activeFill : p.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? activeBorder : p.border,
            width: active ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? activeBorder.withValues(alpha: 0.18)
                    : p.surface,
              ),
              child: Icon(
                icon,
                size: 20,
                color: active ? activeBorder : p.inkMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: active ? p.ink : p.inkSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: p.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleAwarePersonalizeStep(AppPalette p) {
    final isPriest = _selectedRole == 'priest';
    final featuredSaints = PatronSaintService.saints.take(14).toList();

    return SingleChildScrollView(
      key: const ValueKey('auth_step_1'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isPriest ? p.goldBorder : p.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: p.isDark ? 0.35 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CopticCross(size: 22, color: isPriest ? p.gold : p.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isPriest ? 'تجهيز بوابة قدس أبونا' : 'أهلاً بك في أرثوذكسيا',
                    style: GoogleFonts.amiri(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: p.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isPriest
                  ? 'بيانات سريعة لتخصيص واجهة قدسك وتجهيز كود الاعتراف الخاص بأولادك فوراً.'
                  : 'خطوة سريعة لنخصّص لك التحية اليومية وأقوال شفيعك الشخصي.',
              style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkSecondary, height: 1.55),
            ),
            const SizedBox(height: 18),

            if (isPriest) ...[
              // Title Prefix: القس / القمص
              Row(
                children: ['القس', 'القمص'].map((prefix) {
                  final sel = _priestTitlePrefix == prefix;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: prefix == 'القس' ? 8 : 0),
                      child: ChoiceChip(
                        showCheckmark: false,
                        selected: sel,
                        selectedColor: p.gold,
                        backgroundColor: p.surfaceSubtle,
                        label: Center(
                          child: Text(
                            prefix,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              color: sel ? const Color(0xFF19130A) : p.ink,
                            ),
                          ),
                        ),
                        onSelected: (_) => setState(() => _priestTitlePrefix = prefix),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'اسم قدسك (مثال: بولس جرجس)',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              DioceseChurchSelector(
                selectedDiocese: _selectedDiocese,
                selectedChurch: _selectedChurch,
                onDioceseChanged: (d) => setState(() => _selectedDiocese = d),
                onChurchChanged: (c) => setState(() => _selectedChurch = c),
              ),
              const SizedBox(height: 18),
            ] else ...[
              Text(
                'كيف نحب أن نناديك؟',
                style: GoogleFonts.cairo(
                  fontSize: 13,
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'اختر شفيعك الشخصي',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                  ),
                  Text(
                    'يمكن تغييره لاحقاً',
                    style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 138,
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
                        width: 102,
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                        decoration: BoxDecoration(
                          color: selected ? p.goldSoft : p.surfaceSubtle,
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
                                  size: 58,
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
                                      child: Icon(Icons.check_rounded, size: 13, color: p.onAccent),
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
                                fontSize: 11,
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
              const SizedBox(height: 18),
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
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: p.goldSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.goldBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_rounded, color: p.accent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _storage.getConfessionFatherName().isNotEmpty
                                  ? 'أب اعترافي: ${_storage.getConfessionFatherName()}'
                                  : 'ربط بأب اعترافك (بكود أبونا أو الدليل)',
                              style: GoogleFonts.cairo(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: p.ink,
                              ),
                            ),
                            Text(
                              _storage.getConfessionFatherChurch().isNotEmpty
                                  ? _storage.getConfessionFatherChurch()
                                  : 'اختياري — تقدر تربط بكود قدسه أو تختار بعدين',
                              style: GoogleFonts.cairo(fontSize: 11, color: p.inkSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_left_rounded, color: p.accent),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            ElevatedButton(
              onPressed: _busy ? null : _finalizeAndEnter,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPriest ? p.gold : p.accent,
                foregroundColor: isPriest ? const Color(0xFF19130A) : p.onAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Text(
                      isPriest ? 'الدخول لبوابة الأب الكاهن' : 'البدء الآن',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 9),
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
            fontSize: 12.5,
            fontWeight: active ? FontWeight.bold : FontWeight.w600,
            color: active ? p.ink : p.inkMuted,
          ),
        ),
      ),
    );
  }
}

class _SacredChristHaloPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final ringPaint = Paint()
      ..color = const Color(0xFFE6C275).withValues(alpha: 0.30)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(c, size.width * 0.43, ringPaint);
    canvas.drawCircle(c, size.width * 0.48, ringPaint..color = const Color(0xFFE6C275).withValues(alpha: 0.14));

    final rayPaint = Paint()
      ..color = const Color(0xFFF3D591).withValues(alpha: 0.25)
      ..strokeWidth = 1.1;

    const rays = 24;
    for (int i = 0; i < rays; i++) {
      final a = (i * 2 * math.pi) / rays;
      final rIn = size.width * 0.42;
      final rOut = i % 3 == 0 ? size.width * 0.50 : size.width * 0.46;
      canvas.drawLine(
        Offset(c.dx + rIn * math.cos(a), c.dy + rIn * math.sin(a)),
        Offset(c.dx + rOut * math.cos(a), c.dy + rOut * math.sin(a)),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoldenIncenseMotesPainter extends CustomPainter {
  final double progress;
  _GoldenIncenseMotesPainter({required this.progress});

  static const _seeds = [
    (0.12, 0.25, 2.2, 0.7),
    (0.24, 0.72, 1.6, 1.1),
    (0.36, 0.40, 2.6, 0.9),
    (0.48, 0.85, 1.8, 1.3),
    (0.62, 0.30, 2.4, 0.8),
    (0.75, 0.68, 1.9, 1.2),
    (0.86, 0.42, 2.2, 1.0),
    (0.18, 0.90, 1.5, 0.6),
    (0.55, 0.15, 2.0, 1.4),
    (0.91, 0.78, 1.7, 0.85),
    (0.08, 0.58, 2.1, 1.15),
    (0.70, 0.12, 1.5, 0.95),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final (sx, sy, radius, speed) in _seeds) {
      final yNorm = (sy - progress * speed) % 1.0;
      final y = (yNorm < 0 ? yNorm + 1.0 : yNorm) * size.height;
      final x = (sx + math.sin((progress * 2 * math.pi) + sy * 6) * 0.025) * size.width;
      final alpha = (math.sin(yNorm * math.pi).clamp(0.0, 1.0)) * 0.45;
      paint.color = const Color(0xFFF3D591).withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoldenIncenseMotesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
