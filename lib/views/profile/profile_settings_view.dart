import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/patron_saint_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/saint_icon_avatar.dart';
import '../../providers/theme_provider.dart';
import '../conscience/conscience_exam_view.dart';
import '../onboarding/auth_view.dart';
import '../spiritual_tracker/spiritual_tracker_view.dart';
import '../synaxarium/my_patron_saint_view.dart';
import 'privacy_policy_view.dart';

class ProfileSettingsView extends StatefulWidget {
  const ProfileSettingsView({super.key});

  @override
  State<ProfileSettingsView> createState() => _ProfileSettingsViewState();
}

class _ProfileSettingsViewState extends State<ProfileSettingsView> {
  final StorageService _storage = StorageService();
  final FirebaseService _firebase = FirebaseService();

  void _guardPersonalSection(String title, Widget destination) {
    final p = context.palette;
    if (_storage.isGuestMode() && _firebase.currentUser == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: p.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: p.border),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_person_rounded, color: p.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'قسم خاص محمي ($title)',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'أنت تتصفح حالياً كزائر. لحفظ خصوصيتك وحماية مذكرات الاعتراف وجهادك الروحي على جهازك، يُرجى تسجيل الدخول أولاً.',
            style: GoogleFonts.cairo(
              color: p.inkMuted,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('لاحقاً', style: GoogleFonts.cairo(color: p.inkMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: p.accent,
                foregroundColor: p.onAccent,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthView()),
                );
              },
              child: Text(
                'تسجيل الدخول',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
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
    final p = context.palette;
    final nameCtrl = TextEditingController(
      text: _storage.hasCustomUserName() ? _storage.getUserName() : '',
    );
    final titleCtrl = TextEditingController(text: _storage.getUserTitle());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.border),
        ),
        title: Text(
          'تعديل بيانات الملف الشخصي',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            color: p.ink,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.cairo(color: p.ink),
              decoration: InputDecoration(
                labelText: 'الاسم',
                labelStyle: GoogleFonts.cairo(color: p.inkMuted),
                filled: true,
                fillColor: p.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              style: GoogleFonts.cairo(color: p.ink),
              decoration: InputDecoration(
                labelText: 'الخدمة أو الوصف',
                labelStyle: GoogleFonts.cairo(color: p.inkMuted),
                filled: true,
                fillColor: p.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: p.inkMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: p.accent,
              foregroundColor: p.onAccent,
            ),
            onPressed: () async {
              final cleanName = nameCtrl.text.trim();
              if (cleanName.isNotEmpty) {
                await _storage.setUserName(cleanName);
                await _firebase.syncPublicProfile(
                  displayName: cleanName,
                  patronSaintId: _storage.getPatronSaintId(),
                );
              }
              await _storage.setUserTitle(titleCtrl.text);
              if (mounted) setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('حفظ', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.border),
        ),
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
        content: Text(
          'هل تريد تسجيل الخروج من حسابك؟ ستظل بياناتك المحلية محفوظة على الجهاز.',
          style: GoogleFonts.cairo(color: p.inkMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: p.inkMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: p.crimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('تسجيل الخروج',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firebase.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthView()),
        (_) => false,
      );
    }
  }

  Widget _sectionLabel(AppPalette p, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: p.accent,
        ),
      ),
    );
  }

  Widget _themeCard({
    required AppPalette p,
    required AppThemeMode mode,
    required AppThemeMode current,
    required String title,
    required String subtitle,
    required Color previewBg,
    required Color previewAccent,
    required Color previewInk,
    required VoidCallback onTap,
  }) {
    final selected = mode == current;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? p.accentSoft : p.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? p.accent : p.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              // Swatch miniature
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: previewBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: p.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: previewAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: previewInk.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? p.accent : p.ink,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 9.5,
                  color: p.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final themeProv = Provider.of<ThemeProvider>(context);
    final userName = _storage.getUserName();
    final userTitle = _storage.getUserTitle();
    final patron = PatronSaintService.getSaintById(_storage.getPatronSaintId());
    final patronImg = PatronSaintService.getImageUrlForSaint(patron);
    final user = _firebase.currentUser;
    final email = user?.email ?? _storage.getUserEmail();
    final isSignedIn = user != null || !_storage.isGuestMode();

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        title: Text(
          'حسابي والإعدادات',
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: p.ink,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
            children: [
              // 1. Account Identity Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // User avatar: Google photo or Bespoke Neo-Coptic Patron Saint portrait
                        if (user?.photoURL != null &&
                            user!.photoURL!.startsWith('https://'))
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: p.accentSoft,
                            backgroundImage: NetworkImage(user.photoURL!),
                          )
                        else
                          SaintIconAvatar(
                            imageUrl: patronImg,
                            size: 60,
                            shape: SaintAvatarShape.circle,
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  color: p.ink,
                                ),
                              ),
                              Text(
                                email.isNotEmpty ? email : userTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: p.inkMuted,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSignedIn
                                          ? p.success
                                          : p.inkSubtle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isSignedIn
                                          ? 'حساب مفعّل ومتزامن • شفيعي: ${patron.shortName}'
                                          : 'وضع الزائر • شفيعي: ${patron.shortName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        color: p.accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: p.accent),
                          tooltip: 'تعديل الملف',
                          onPressed: _showEditProfileDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(color: p.border, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (isSignedIn) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: p.crimson,
                                side: BorderSide(
                                    color: p.crimson.withValues(alpha: 0.4)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _confirmSignOut,
                              icon: const Icon(Icons.logout_rounded, size: 17),
                              label: Text(
                                'تسجيل الخروج',
                                style: GoogleFonts.cairo(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: p.accent,
                                foregroundColor: p.onAccent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AuthView()),
                                ).then((_) {
                                  if (mounted) setState(() {});
                                });
                              },
                              icon: const Icon(Icons.login_rounded, size: 17),
                              label: Text(
                                'تسجيل الدخول لحفظ تقدمك',
                                style: GoogleFonts.cairo(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 2. Reading Appearance & Typography
              _sectionLabel(p, 'المظهر وحجم الخط'),
              Container(
                padding: const EdgeInsets.all(14),
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
                        _themeCard(
                          p: p,
                          mode: AppThemeMode.lightParchment,
                          current: themeProv.mode,
                          title: 'نهاري بردي',
                          subtitle: 'دافئ وهادئ',
                          previewBg: const Color(0xFFFAF6EE),
                          previewAccent: const Color(0xFFA47A2E),
                          previewInk: const Color(0xFF1F1B16),
                          onTap: () =>
                              themeProv.setThemeMode(AppThemeMode.lightParchment),
                        ),
                        const SizedBox(width: 8),
                        _themeCard(
                          p: p,
                          mode: AppThemeMode.darkGold,
                          current: themeProv.mode,
                          title: 'ليلي فحمي',
                          subtitle: 'مريح مساءً',
                          previewBg: const Color(0xFF151311),
                          previewAccent: const Color(0xFFD6B067),
                          previewInk: const Color(0xFFF3EFE6),
                          onTap: () =>
                              themeProv.setThemeMode(AppThemeMode.darkGold),
                        ),
                        const SizedBox(width: 8),
                        _themeCard(
                          p: p,
                          mode: AppThemeMode.amoledChurch,
                          current: themeProv.mode,
                          title: 'وضع الكنيسة',
                          subtitle: 'داكن صامت',
                          previewBg: const Color(0xFF000000),
                          previewAccent: const Color(0xFFC9A255),
                          previewInk: const Color(0xFFE6E0D3),
                          onTap: () =>
                              themeProv.setThemeMode(AppThemeMode.amoledChurch),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: p.border, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'حجم الخط في الصلوات والقراءات',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: p.ink,
                          ),
                        ),
                        Text(
                          '${(themeProv.fontScale * 100).toInt()}%',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: p.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: themeProv.fontScale,
                      min: 0.85,
                      max: 1.55,
                      divisions: 7,
                      activeColor: p.accent,
                      inactiveColor: p.border,
                      onChanged: (val) => themeProv.setFontScale(val),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '«أَنَا هُوَ نُورُ الْعَالَمِ» — معاينة لحجم خط القراءة',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 16 * themeProv.fontScale,
                          color: p.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 3. Patron Saint & Daily Notifications
              _sectionLabel(p, 'شفيعك الشخصي والتنبيهات اليومية'),
              Container(
                decoration: BoxDecoration(
                  color: p.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.border),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                    ListTile(
                      leading: SaintIconAvatar(
                        imageUrl: patronImg,
                        size: 40,
                        shape: SaintAvatarShape.circle,
                      ),
                      title: Text(
                        'شفيعي الشخصي وأقواله اليومية',
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                      subtitle: Text(
                        patron.name,
                        style: GoogleFonts.cairo(fontSize: 11.5, color: p.accent),
                      ),
                      trailing: Icon(Icons.chevron_left_rounded,
                          color: p.inkSubtle),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MyPatronSaintView()),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    Divider(color: p.border, height: 1),
                    SwitchListTile(
                      secondary: Icon(Icons.notifications_active_outlined,
                          color: p.accent),
                      title: Text(
                        'إشعار آية اليوم وقول شفيعك',
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: p.ink,
                        ),
                      ),
                      subtitle: Text(
                        'آية يومية متجددة الساعة ${_storage.getDailyVerseHour().toString().padLeft(2, '0')}:${_storage.getDailyVerseMinute().toString().padLeft(2, '0')}',
                        style: GoogleFonts.cairo(
                            fontSize: 11.5, color: p.inkMuted),
                      ),
                      activeThumbColor: p.accent,
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
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
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
                                  await _storage.setDailyVerseTime(
                                      picked.hour, picked.minute);
                                  await NotificationService()
                                      .syncScheduledNotifications();
                                  if (mounted) setState(() {});
                                }
                              },
                              icon: Icon(Icons.access_time_rounded,
                                  size: 16, color: p.accent),
                              label: Text('تغيير الموعد',
                                  style: GoogleFonts.cairo(
                                      fontSize: 12, color: p.accent)),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () async {
                                await NotificationService().requestPermission();
                                await NotificationService()
                                    .sendTestDailyVerseNow();
                              },
                              icon: Icon(Icons.send_rounded,
                                  size: 15, color: p.accent),
                              label: Text('تجربة الإشعار',
                                  style: GoogleFonts.cairo(
                                      fontSize: 12, color: p.accent)),
                            ),
                          ],
                        ),
                      ),
                    Divider(color: p.border, height: 1),
                    SwitchListTile(
                      secondary: Icon(Icons.family_restroom_rounded,
                          color: p.accent),
                      title: Text(
                        'تذكير صلاة العائلة (اختياري)',
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: p.ink,
                        ),
                      ),
                      subtitle: Text(
                        'تذكير يومي هادئ الساعة ${_storage.getFamilyPrayerHour().toString().padLeft(2, '0')}:${_storage.getFamilyPrayerMinute().toString().padLeft(2, '0')}',
                        style: GoogleFonts.cairo(
                            fontSize: 11.5, color: p.inkMuted),
                      ),
                      activeThumbColor: p.accent,
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
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
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
                                await _storage.setFamilyPrayerTime(
                                    picked.hour, picked.minute);
                                await NotificationService()
                                    .syncScheduledNotifications();
                                if (mounted) setState(() {});
                              }
                            },
                            icon: Icon(Icons.schedule_rounded,
                                size: 16, color: p.accent),
                            label: Text('تغيير موعد صلاة العائلة',
                                style: GoogleFonts.cairo(
                                    fontSize: 12, color: p.accent)),
                          ),
                        ),
                      ),
                  ],
                ),
                ),
              ),

              const SizedBox(height: 22),

              // 4. Personal Spiritual Tools & Privacy
              _sectionLabel(p, 'الخصوصية والأدوات الشخصية'),
              Container(
                decoration: BoxDecoration(
                  color: p.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.border),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                    SwitchListTile(
                      secondary: Icon(Icons.fingerprint_rounded, color: p.accent),
                      title: Text(
                        'قفل مذكرة الاعتراف بالبصمة',
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: p.ink,
                        ),
                      ),
                      subtitle: Text(
                        'تُحفظ مشفرة على جهازك فقط ولا تُرفع لأي خادم خارجي',
                        style: GoogleFonts.cairo(
                            fontSize: 11.5, color: p.inkMuted),
                      ),
                      activeThumbColor: p.accent,
                      value: _storage.isBiometricConfessionLockEnabled(),
                      onChanged: (val) async {
                        await _storage.setBiometricConfessionLockEnabled(val);
                        if (mounted) setState(() {});
                      },
                    ),
                    Divider(color: p.border, height: 1),
                    ListTile(
                      leading: Icon(Icons.shield_outlined, color: p.accent),
                      title: Text(
                        'فحص الضمير ومذكرة الاعتراف',
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: p.ink,
                        ),
                      ),
                      subtitle: Text(
                        'خصوصية تامة على جهازك الشخصي فقط',
                        style: GoogleFonts.cairo(
                            fontSize: 11.5, color: p.inkMuted),
                      ),
                      trailing:
                          Icon(Icons.chevron_left_rounded, color: p.inkSubtle),
                      onTap: () => _guardPersonalSection(
                          'فحص الضمير للاعتراف', const ConscienceExamView()),
                    ),
                    Divider(color: p.border, height: 1),
                    ListTile(
                      leading: Icon(Icons.insights_rounded, color: p.accent),
                      title: Text(
                        'مُتتبع الجهاد الروحي اليومي',
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: p.ink,
                        ),
                      ),
                      subtitle: Text(
                        'سجل قراءاتك وصلواتك اليومية بخصوصية كاملة',
                        style: GoogleFonts.cairo(
                            fontSize: 11.5, color: p.inkMuted),
                      ),
                      trailing:
                          Icon(Icons.chevron_left_rounded, color: p.inkSubtle),
                      onTap: () => _guardPersonalSection(
                          'متتبع الجهاد الروحي', const SpiritualTrackerView()),
                    ),
                    Divider(color: p.border, height: 1),
                    ListTile(
                      leading:
                          Icon(Icons.verified_user_outlined, color: p.accent),
                      title: Text(
                        'الخصوصية وأمان بياناتك وحذف الحساب',
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: p.ink,
                        ),
                      ),
                      subtitle: Text(
                        'تفاصيل الحماية وحق المسح النهائي للبيانات',
                        style: GoogleFonts.cairo(
                            fontSize: 11.5, color: p.inkMuted),
                      ),
                      trailing:
                          Icon(Icons.chevron_left_rounded, color: p.inkSubtle),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyView()),
                      ),
                    ),
                  ],
                ),
                ),
              ),

              const SizedBox(height: 20),

              // 5. Offline Readiness Footer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.offline_pin_rounded,
                            color: p.success, size: 19),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'يعمل داخل الكنيسة بدون إنترنت',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الخولاجي المقدس، الأجبية الكاملة، الكتاب المقدس، القطمارس، السنكسار، والمكتبة المقروءة محفوظة جميعها على جهازك.',
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: p.inkMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(color: p.border, height: 1),
                    const SizedBox(height: 8),
                    Text(
                      'تطبيق أرثوذكسيا — الإصدار 1.0.0',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: p.inkSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
