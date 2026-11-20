import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/encryption_service.dart';
import '../../core/services/security_guard_service.dart';
import '../../core/services/storage_service.dart';
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.45)),
        ),
        title: Text(
          'حذف الحساب وجميع البيانات نهائياً',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGoldLight,
            fontSize: 16,
          ),
        ),
        content: Text(
          'هل أنت متأكد من مسح جميع بياناتك الشخصية وسجلات الجهاد الروحي ومذكرة الاعتراف المشفرة من هذا الجهاز؟ لا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              HapticFeedback.heavyImpact();
              await StorageService().deleteAllUserData();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthView()),
                (_) => false,
              );
            },
            child: Text(
              'حذف نهائي',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _policySection({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.obsidianCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGoldLight,
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
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityStatusCard() {
    final keystoreActive = EncryptionService().isHardwareKeystoreActive;
    final deviceSafe = !_integrity.hasRisk;

    Widget rowItem(IconData icon, String label, String badge, Color badgeColor) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.textLight),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
              ),
              child: Text(
                badge,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
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
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2218), Color(0xFF13151B)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppColors.primaryGold, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'حالة درع الأمان على جهازك الآن',
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
              ),
            ],
          ),
          rowItem(
            Icons.enhanced_encryption_rounded,
            'تشفير الأسرار والاعتراف (AES-256-GCM)',
            keystoreActive ? 'Keystore نشط' : 'مُشفّر محلياً',
            AppColors.successGreen,
          ),
          rowItem(
            Icons.screenshot_monitor_rounded,
            'حجب لقطات وتسجيل الشاشة (FLAG_SECURE)',
            'مُفعّل',
            AppColors.successGreen,
          ),
          rowItem(
            Icons.https_rounded,
            'تشفير الاتصالات ومنع النسخ الاحتياطي السحابي',
            'HTTPS-Only',
            AppColors.successGreen,
          ),
          rowItem(
            Icons.security_rounded,
            'فحص سلامة نظام التشغيل (Root / Integrity)',
            deviceSafe ? 'الجهاز سليم' : 'تنبيه Root',
            deviceSafe ? AppColors.successGreen : Colors.amberAccent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CopticCross(size: 24),
                  Text(
                    'سياسة الخصوصية وأمان البيانات',
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGoldLight,
                    ),
                  ),
                  LuxeCircleButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  _securityStatusCard(),
                  _policySection(
                    icon: Icons.shield_outlined,
                    title: '١. التزامنا الكامل بخصوصيتك (Google Play Data Safety)',
                    body:
                        'تطبيق «أرثوذكسيا» مصمم لخدمتك الروحية والليتورجية بأعلى معايير الأمان والخصوصية. لا يقوم التطبيق ببيع أو مشاركة أي بيانات شخصية مع أي طرف ثالث أو جهات إعلانية إطلاقاً.',
                  ),
                  _policySection(
                    icon: Icons.lock_outline_rounded,
                    title: '٢. التشفير الموثّق AES-256-GCM لمذكرة الاعتراف ودفتر اذكرهم',
                    body:
                        'جميع البيانات الحساسة مثل «مذكرة الاعتراف وفحص الضمير» و«سجلات متتبع الجهاد الروحي» و«دفتر اذكرهم يا رب» يتم تشفيرها محلياً بتشفير AES-256-GCM الموثّق بمفتاح مخزن داخل شريحة أمان الهاتف (Android Keystore) مع منع النسخ الاحتياطي السحابي ومنع التقاط أو تسجيل الشاشة (FLAG_SECURE)، ولا تُرفع إطلاقاً لأي سيرفر سحابي.',
                  ),
                  _policySection(
                    icon: Icons.person_outline_rounded,
                    title: '٣. بيانات الحساب واختيار الإيبارشية والكنيسة ووضع الزائر',
                    body:
                        'عند تسجيل الدخول (عبر Google أو Apple أو البريد الإلكتروني أو رقم الهاتف OTP) يتم حفظ اسمك وإيبارشيتك وكنيستك لتخصيص تجربتك. وفي «وضع الزائر» يُتاح تصفح كافة الأقسام العامة (القداسات، الكتاب المقدس، الأجبية، الألحان، القطمارس) مع حجب الأقسام الشخصية لحين تسجيل الدخول.',
                  ),
                  _policySection(
                    icon: Icons.volume_up_outlined,
                    title: '٤. أذونات التطبيق (الصوت في الخلفية ووضع الكنيسة الذكي)',
                    body:
                        '• إذن الإنترنت وتشغيل الوسائط في الخلفية (FOREGROUND_SERVICE_MEDIA_PLAYBACK): لاستمرار تشغيل الألحان القبطية عند قفل الشاشة.\n• وضع الكنيسة الذكي: لتخفيض إضاءة الشاشة وتهدئة الإشعارات أثناء التواجد داخل الكنيسة.',
                  ),
                  _policySection(
                    icon: Icons.delete_forever_rounded,
                    title: '٥. حق المستخدم في حذف الحساب والبيانات (Data Deletion)',
                    body:
                        'طبقاً لسياسات متجر Google Play، يمكنك في أي وقت مسح حسابك وجميع بياناتك وسجلاتك المشفرة فوراً وبضغطة زر واحدة من الزر أدناه.',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A1818),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE57373)),
                      ),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFE57373)),
                    label: Text(
                      'حذف الحساب ومسح جميع البيانات الشخصية نهائياً',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    onPressed: () => _confirmDeleteAccount(context),
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
