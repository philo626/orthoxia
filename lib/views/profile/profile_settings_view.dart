import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/patron_saint_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/saint_icon_avatar.dart';
import '../../providers/theme_provider.dart';
import '../spiritual_tracker/spiritual_tracker_view.dart';
import '../conscience/conscience_exam_view.dart';
import '../onboarding/auth_view.dart';
import '../synaxarium/my_patron_saint_view.dart';
import 'privacy_policy_view.dart';

class ProfileSettingsView extends StatefulWidget {
  const ProfileSettingsView({super.key});

  @override
  State<ProfileSettingsView> createState() => _ProfileSettingsViewState();
}

class _ProfileSettingsViewState extends State<ProfileSettingsView> {
  final StorageService _storage = StorageService();

  void _guardPersonalSection(String title, Widget destination) {
    if (_storage.isGuestMode()) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.45)),
          ),
          title: Row(
            children: [
              const Icon(Icons.lock_person_rounded, color: AppColors.primaryGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'قسم شخصي محمي ($title)',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGoldLight,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'أنت تتصفح حالياً في «وضع الزائر». لحماية خصوصيتك وتشفير بيانات الاعتراف والجهاد الروحي محلياً، يُرجى تسجيل الدخول بحسابك أولاً.',
            style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13, height: 1.55),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('لاحقاً', style: GoogleFonts.cairo(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthView()),
                );
              },
              child: Text(
                'تسجيل الدخول الآن',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _storage.getUserName());
    final titleCtrl = TextEditingController(text: _storage.getUserTitle());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.4)),
        ),
        title: Text(
          'تعديل بيانات الملف الشخصي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.primaryGold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.cairo(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'الاسم',
                labelStyle: GoogleFonts.cairo(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              style: GoogleFonts.cairo(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'الوصف / الخدمة الكنسية',
                labelStyle: GoogleFonts.cairo(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold, foregroundColor: Colors.black),
            onPressed: () async {
              await _storage.setUserName(nameCtrl.text);
              await _storage.setUserTitle(titleCtrl.text);
              if (mounted) setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('حفظ', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final userName = _storage.getUserName();
    final userTitle = _storage.getUserTitle();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'الإعدادات والتخصيص',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // User Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.sacredBurgundy.withValues(alpha: 0.4),
                      AppColors.cardNavy,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryGold, width: 2),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/app_cover.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.cairo(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            userTitle,
                            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'شفيعي الشخصي: ${PatronSaintService.getSaintById(_storage.getPatronSaintId()).shortName}',
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              color: AppColors.primaryGoldLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AppColors.primaryGold),
                      tooltip: 'تعديل الاسم',
                      onPressed: _showEditProfileDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.login_rounded, color: AppColors.primaryGoldLight),
                      tooltip: 'تسجيل الدخول بحساب Google / تبديل الحساب',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthView()),
                        );
                      },
                    ),
                  ],
                ),
              ),

          const SizedBox(height: 24),

          // Section 1: Themes & Reading
          Text(
            'مظهر القراءة والخطوط',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: AppColors.cardNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined, color: AppColors.primaryGold),
                    title: Text('المظهر والسمة', style: GoogleFonts.cairo(fontSize: 14)),
                    subtitle: Text(
                      themeProv.mode == AppThemeMode.darkGold
                          ? 'الوضع الليلي الكنسي الذهبي'
                          : themeProv.mode == AppThemeMode.amoledChurch
                              ? 'وضع الكنيسة المعتم (AMOLED)'
                              : 'الوضع النهاري (ورق البردي)',
                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted),
                    ),
                    trailing: DropdownButton<AppThemeMode>(
                      value: themeProv.mode,
                      dropdownColor: AppColors.cardNavy,
                      underline: const SizedBox.shrink(),
                      onChanged: (newMode) {
                        if (newMode != null) themeProv.setThemeMode(newMode);
                      },
                      items: const [
                        DropdownMenuItem(
                          value: AppThemeMode.darkGold,
                          child: Text('ليلي ذهبي', style: TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: AppThemeMode.amoledChurch,
                          child: Text('AMOLED كنيسة', style: TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                        DropdownMenuItem(
                          value: AppThemeMode.lightParchment,
                          child: Text('نهاري بردي', style: TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Font Size Scale Slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('حجم الخط في الصلوات والقطمارس',
                                style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight)),
                            Text('${(themeProv.fontScale * 100).toInt()}%',
                                style: GoogleFonts.cairo(fontSize: 13, color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: themeProv.fontScale,
                          min: 0.8,
                          max: 1.6,
                          divisions: 8,
                          activeColor: AppColors.primaryGold,
                          inactiveColor: Colors.white.withValues(alpha: 0.15),
                          onChanged: (val) => themeProv.setFontScale(val),
                        ),
                        Text(
                          '«أَنَا هُوَ نُورُ الْعَالَمِ» (معاينة لحجم الخط)',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 14 * themeProv.fontScale,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 1.5: Daily Verse, Patron Saint & Optional Family Prayer Notifications
          Text(
            'الإشعارات اليومية وشفيعك الشخصي (اختياري تماماً)',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    leading: SaintIconAvatar(
                      imageUrl: PatronSaintService.getImageUrlForSaint(
                        PatronSaintService.getSaintById(_storage.getPatronSaintId()),
                      ),
                      size: 38,
                      shape: SaintAvatarShape.circle,
                    ),
                    title: Text('شفيعي الشخصي وأقواله اليومية', style: GoogleFonts.cairo(fontSize: 14)),
                    subtitle: Text(
                      PatronSaintService.getSaintById(_storage.getPatronSaintId()).name,
                      style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.primaryGoldLight),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryGold),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyPatronSaintView()),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryGold),
                    title: Text('إشعار آية اليوم وقول شفيعك', style: GoogleFonts.cairo(fontSize: 14)),
                    subtitle: Text(
                      'تصلك آية من الكتاب المقدس يومياً الساعة ${_storage.getDailyVerseHour().toString().padLeft(2, '0')}:${_storage.getDailyVerseMinute().toString().padLeft(2, '0')}',
                      style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                    activeThumbColor: AppColors.primaryGold,
                    value: _storage.isDailyVerseNotificationEnabled(),
                    onChanged: (val) async {
                      if (val) {
                        await NotificationService().requestPermission();
                      }
                      await _storage.setDailyVerseNotificationEnabled(val);
                      await NotificationService().syncScheduledNotifications();
                      if (mounted) setState(() {});
                    },
                  ),
                  if (_storage.isDailyVerseNotificationEnabled())
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: _storage.getDailyVerseHour(),
                                  minute: _storage.getDailyVerseMinute(),
                                ),
                              );
                              if (picked != null) {
                                await _storage.setDailyVerseTime(picked.hour, picked.minute);
                                await NotificationService().syncScheduledNotifications();
                                if (mounted) setState(() {});
                              }
                            },
                            icon: const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primaryGold),
                            label: Text('تغيير وقت الآية', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.primaryGoldLight)),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async {
                              await NotificationService().requestPermission();
                              await NotificationService().sendTestDailyVerseNow();
                            },
                            icon: const Icon(Icons.send_rounded, size: 15, color: AppColors.primaryGold),
                            label: Text('تجربة إشعار الآن', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.primaryGold)),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.family_restroom_rounded, color: AppColors.primaryGold),
                    title: Text('تذكير صلاة العائلة (اختياري)', style: GoogleFonts.cairo(fontSize: 14)),
                    subtitle: Text(
                      'تذكير لطيف لو حابين تصلّوا سوا الساعة ${_storage.getFamilyPrayerHour().toString().padLeft(2, '0')}:${_storage.getFamilyPrayerMinute().toString().padLeft(2, '0')} — مش فرض وتقدر تقفله في أي وقت',
                      style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                    activeThumbColor: AppColors.primaryGold,
                    value: _storage.isFamilyPrayerReminderEnabled(),
                    onChanged: (val) async {
                      if (val) {
                        await NotificationService().requestPermission();
                      }
                      await _storage.setFamilyPrayerReminderEnabled(val);
                      await NotificationService().syncScheduledNotifications();
                      if (mounted) setState(() {});
                    },
                  ),
                  if (_storage.isFamilyPrayerReminderEnabled())
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: _storage.getFamilyPrayerHour(),
                                minute: _storage.getFamilyPrayerMinute(),
                              ),
                            );
                            if (picked != null) {
                              await _storage.setFamilyPrayerTime(picked.hour, picked.minute);
                              await NotificationService().syncScheduledNotifications();
                              if (mounted) setState(() {});
                            }
                          },
                          icon: const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primaryGold),
                          label: Text('تحديد موعد صلاة العائلة', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.primaryGoldLight)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Privacy & Spiritual Tools
          Text(
            'الأدوات الروحية والخصوصية',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: AppColors.cardNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primaryGold),
                    title: Text('قفل مذكرات الاعتراف بالبصمة (AES-256)', style: GoogleFonts.cairo(fontSize: 13.5)),
                    subtitle: Text(
                      'تشفير بنكي AES-256 محلياً على جهازك فقط — لا تُرفع أبداً للإنترنت',
                      style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                    activeThumbColor: AppColors.primaryGold,
                    value: _storage.isBiometricConfessionLockEnabled(),
                    onChanged: (val) async {
                      await _storage.setBiometricConfessionLockEnabled(val);
                      if (mounted) setState(() {});
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.shield_moon_rounded, color: AppColors.primaryGold),
                    title: Text('فحص الضمير للاعتراف', style: GoogleFonts.cairo(fontSize: 14)),
                    subtitle: Text('مشفرة بتقنية AES-256 ومحفوظة على جهازك فقط',
                        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryGold),
                    onTap: () => _guardPersonalSection('فحص الضمير للاعتراف', const ConscienceExamView()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      FirebaseService().isFirebaseReady ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                      color: FirebaseService().isFirebaseReady ? AppColors.successGreen : AppColors.primaryGold,
                    ),
                    title: Text('حالة المزامنة السحابية (Firebase)', style: GoogleFonts.cairo(fontSize: 14)),
                    subtitle: Text(
                      FirebaseService().isFirebaseReady
                          ? 'متصل بـ Firebase Auth و Cloud Firestore بنجاح'
                          : 'الوضع المحلي مفعل (أضف google-services.json لتفعيل السحابة)',
                      style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.insights_rounded, color: AppColors.primaryGold),
                    title: Text('مُتتبع الجهاد الروحي الشخصي', style: GoogleFonts.cairo(fontSize: 14)),
                    subtitle: Text('سجل قراءة الإنجيل وصلوات الأجبية والتناول (مشفر محلياً)',
                        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryGold),
                    onTap: () => _guardPersonalSection('متتبع الجهاد الروحي', const SpiritualTrackerView()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_rounded, color: AppColors.primaryGold),
                    title: Text('سياسة الخصوصية وأمان البيانات (Google Play)',
                        style: GoogleFonts.cairo(fontSize: 14)),
                    subtitle: Text('تفاصيل التشفير المحلي وحق حذف الحساب والبيانات',
                        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryGold),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyView()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Offline Content & Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_done_rounded, color: AppColors.successGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'حالة العمل بدون إنترنت (Offline-First)',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'الأجبية كاملة، القطمارس، والسنكسار محملة محلياً وتعمل في أي وقت بدون شبكة.',
                  style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'تطبيق أرثوذكسيا - إصدار 1.0.0 (المجمع المقدس)',
                    style: GoogleFonts.cairo(fontSize: 11, color: AppColors.primaryGoldLight),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
        ),
      ),
    );
  }
}
