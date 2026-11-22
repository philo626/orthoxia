import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/encryption_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/security_guard_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../onboarding/auth_view.dart';

class PrivacyPolicyView extends StatefulWidget {
  const PrivacyPolicyView({super.key});

  @override
  State<PrivacyPolicyView> createState() => _PrivacyPolicyViewState();
}

class _PrivacyPolicyViewState extends State<PrivacyPolicyView> {
  DeviceIntegrityStatus _integrity = const DeviceIntegrityStatus();
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadIntegrity();
  }

  Future<void> _loadIntegrity() async {
    final status = await SecurityGuardService().checkDeviceIntegrity();
    if (mounted) {
      setState(() => _integrity = status);
    }
  }

  void _confirmDeleteAccount(BuildContext context) {
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.border),
        ),
        title: Text(
          'حذف الحساب وجميع البيانات نهائياً',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            color: p.ink,
            fontSize: 16,
          ),
        ),
        content: Text(
          'سيتم مسح حسابك السحابي بالكامل وجميع سجلات الجهاد الروحي ومذكرة الاعتراف المشفرة ومفتاح التشفير من هذا الجهاز. لا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.cairo(
            color: p.inkMuted,
            fontSize: 13,
            height: 1.55,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: p.inkMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: p.crimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.heavyImpact();
              setState(() => _deleting = true);
              final err = await FirebaseService().deleteAccountCompletely();
              if (!context.mounted) return;
              if (err != null) {
                setState(() => _deleting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err, style: GoogleFonts.cairo(fontSize: 12.5)),
                    backgroundColor: p.crimson,
                  ),
                );
                return;
              }
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthView()),
                (_) => false,
              );
            },
            child: Text(
              'حذف نهائي',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _policySection({
    required AppPalette p,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: p.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.cairo(
              fontSize: 13,
              height: 1.65,
              color: p.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityStatusCard(AppPalette p) {
    final keystoreActive = EncryptionService().isHardwareKeystoreActive;
    final deviceSafe = !_integrity.hasRisk;

    Widget rowItem(IconData icon, String label, String badge, Color badgeColor) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: p.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.cairo(fontSize: 12.5, color: p.ink),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                badge,
                style: GoogleFonts.cairo(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_rounded, color: p.accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'حالة حماية بياناتك على جهازك',
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
              ),
            ],
          ),
          rowItem(
            Icons.enhanced_encryption_rounded,
            'تشفير مذكرة الاعتراف ودفتر اذكرهم',
            keystoreActive ? 'شريحة الأمان نشطة' : 'مُشفّر محلياً',
            p.success,
          ),
          rowItem(
            Icons.screenshot_monitor_rounded,
            'منع التقاط وتسجيل الشاشة في الأقسام الخاصة',
            'مُفعّل',
            p.success,
          ),
          rowItem(
            Icons.https_rounded,
            'اتصال مشفّر ومنع النسخ السحابي للأسرار',
            'مُفعّل',
            p.success,
          ),
          rowItem(
            Icons.security_rounded,
            'سلامة نظام الجهاز',
            deviceSafe ? 'الجهاز سليم' : 'تنبيه حماية',
            deviceSafe ? p.success : p.crimson,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  LuxeCircleButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'الخصوصية وأمان البيانات',
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                  ),
                  CopticCross(size: 22, color: p.accent),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                children: [
                  _securityStatusCard(p),
                  _policySection(
                    p: p,
                    icon: Icons.shield_outlined,
                    title: '١. التزامنا الكامل بخصوصيتك',
                    body:
                        'تطبيق «أرثوذكسيا» مصمم لخدمتك الروحية والليتورجية بأعلى معايير الأمان والخصوصية. لا نبيع أو نشارك بياناتك الشخصية مع أي جهات إعلانية أو أطراف خارجية.',
                  ),
                  _policySection(
                    p: p,
                    icon: Icons.lock_outline_rounded,
                    title: '٢. تشفير مذكرة الاعتراف ودفتر اذكرهم محلياً فقط',
                    body:
                        'جميع البيانات الحساسة مثل «مذكرة الاعتراف وفحص الضمير» و«سجلات الجهاد الروحي» و«دفتر اذكرهم يا رب» تُشفّر محلياً بمفتاح مخزن داخل شريحة أمان الهاتف مع منع التقاط الشاشة ومنع النسخ السحابي، ولا تُرفع لأي خادم خارجي إطلاقاً.',
                  ),
                  _policySection(
                    p: p,
                    icon: Icons.person_outline_rounded,
                    title: '٣. مزامنة الحساب',
                    body:
                        'عند تسجيل الدخول يُحفظ اسمك الظاهر وشفيعك الشخصي وتقدم قراءة الكتاب المقدس فقط لمزامنتها بين أجهزتك. وفي وضع الزائر يمكنك تصفح الصلوات والقداسات والكتاب المقدس والألحان بحرية كاملة.',
                  ),
                  _policySection(
                    p: p,
                    icon: Icons.delete_forever_outlined,
                    title: '٤. حقك الكامل في حذف الحساب والبيانات',
                    body:
                        'يمكنك في أي وقت مسح حسابك السحابي وجميع بياناتك وسجلاتك المشفرة نهائياً وبضغطة زر واحدة من الزر أدناه.',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.crimson,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _deleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.delete_forever_rounded),
                    label: Text(
                      _deleting
                          ? 'جارٍ المسح النهائي...'
                          : 'حذف الحساب وجميع البيانات نهائياً',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    onPressed:
                        _deleting ? null : () => _confirmDeleteAccount(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
