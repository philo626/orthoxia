import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../confession/my_father_schedule_view.dart';
import '../conscience/conscience_exam_view.dart';

/// Feature #3: Mass, Communion & Confession Readiness Tracker («الاستعداد للقداس والتناول والاعتراف»)
/// 100% private & local on user's device — gentle Egyptian spiritual accompaniment with zero judgment!
class CommunionReadinessView extends StatefulWidget {
  const CommunionReadinessView({super.key});

  @override
  State<CommunionReadinessView> createState() => _CommunionReadinessViewState();
}

class _CommunionReadinessViewState extends State<CommunionReadinessView> {
  final StorageService _storage = StorageService();
  String _lastConfessionIso = '';
  String _lastCommunionIso = '';

  final Map<String, bool> _prepChecklist = {
    'fasting_9h': false,
    'reconcile': false,
    'psalm_50': false,
    'conscience': false,
    'thanksgiving': false,
  };

  static const _prepItems = <({String key, String title, String sub})>[
    (
      key: 'fasting_9h',
      title: 'الصوم الانقطاعي قبل التناول (٩ ساعات)',
      sub: 'حسب إرشاد قدس أب اعترافك وظروفك الصحية',
    ),
    (
      key: 'reconcile',
      title: 'المصالحة والصفح مع الكل',
      sub: '«اذهب أولاً اصطلح مع أخيك، وحينئذ تعال وقدّم قربانك» (مت ٥: ٢٤)',
    ),
    (
      key: 'psalm_50',
      title: 'صلاة المزمور الخمسين (ارحمني يا الله)',
      sub: 'قلب متضع ومنكسر لا يرذله الله قبل الوقوف أمام المذبح',
    ),
    (
      key: 'conscience',
      title: 'مراجعة النفس وفحص الضمير',
      sub: 'دقائق هدوء مع ربنا قبل القداس أو الاعتراف',
    ),
    (
      key: 'thanksgiving',
      title: 'صلاة الشكر وحفظ السلام بعد التناول',
      sub: 'الهدوء وشكر ربنا على نعمة الجسد الأقدس والدم الكريم',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _lastConfessionIso = _storage.getLastConfessionDateIso();
    _lastCommunionIso = _storage.getLastCommunionDateIso();
  }

  String _todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int? _daysSince(String iso) {
    if (iso.isEmpty) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    final today = DateTime.now();
    final diff = DateTime(today.year, today.month, today.day)
        .difference(DateTime(parsed.year, parsed.month, parsed.day))
        .inDays;
    return diff < 0 ? 0 : diff;
  }

  String _formatFriendlyDays(int? days, {required String emptyText}) {
    if (days == null) return emptyText;
    if (days == 0) return 'النهاردة (بركة ونعمة!)';
    if (days == 1) return 'امبارح (من يوم واحد)';
    if (days == 2) return 'من يومين';
    if (days <= 10) return 'من $days أيام';
    return 'من $days يوم';
  }

  Future<void> _pickPastDate({required bool isConfession}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked == null) return;
    final iso =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    HapticFeedback.lightImpact();
    if (isConfession) {
      await _storage.setLastConfessionDateIso(iso);
      setState(() => _lastConfessionIso = iso);
    } else {
      await _storage.setLastCommunionDateIso(iso);
      setState(() => _lastCommunionIso = iso);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final daysConf = _daysSince(_lastConfessionIso);
    final daysComm = _daysSince(_lastCommunionIso);
    final needsConfessionNudge = daysConf != null && daysConf >= 30;
    final checkedCount = _prepChecklist.values.where((v) => v).length;

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        elevation: 0,
        title: Text(
          'الاستعداد للقداس والتناول',
          style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 23, color: p.ink),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
            children: [
              // 1. Warm Spiritual Status Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF2B1C12), Color(0xFF1A120D)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE5C175).withValues(alpha: 0.45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const CopticCross(size: 22, color: Color(0xFFF3D591)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'متابعتك الهادية مع الأسرار المقدسة',
                            style: GoogleFonts.amiri(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFDF5E6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'كل التواريخ دي محفوظة على موبايلك لوحدك بخصوصية تامة عشان تساعدك تحافظ على انتظامك في التناول والاعتراف.',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: const Color(0xFFD8C5A5),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 2. Gentle Monthly Confession Nudge (if >= 30 days)
              if (needsConfessionNudge) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.goldSoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: p.goldBorder, width: 1.3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite_rounded, color: p.gold, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'عدّى $daysConf يوم على آخر اعتراف 😊',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: p.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'القلب بيرتاح أوي لما نقعد مع قدس أبونا! إيه رأيك تشوف مواعيد أبونا وتحجز ميعاد قريب؟',
                        style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, luxeRoute(const MyFatherScheduleView())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: p.gold,
                          foregroundColor: const Color(0xFF19130A),
                        ),
                        icon: const Icon(Icons.event_available_rounded, size: 18),
                        label: Text(
                          'افتح مواعيد قدس أبونا دلوقتي',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 3. Two Tracking Cards: Last Confession + Last Communion
              Row(
                children: [
                  Expanded(
                    child: _trackerCard(
                      p: p,
                      icon: Icons.volunteer_activism_rounded,
                      title: 'آخر اعتراف',
                      statusText: _formatFriendlyDays(daysConf, emptyText: 'لسه متسجّلش'),
                      dateIso: _lastConfessionIso,
                      todayLabel: 'اعترفت النهاردة ✓',
                      onMarkToday: () async {
                        HapticFeedback.mediumImpact();
                        final t = _todayIso();
                        await _storage.setLastConfessionDateIso(t);
                        setState(() => _lastConfessionIso = t);
                      },
                      onPickDate: () => _pickPastDate(isConfession: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _trackerCard(
                      p: p,
                      icon: Icons.church_rounded,
                      title: 'آخر تناول',
                      statusText: _formatFriendlyDays(daysComm, emptyText: 'لسه متسجّلش'),
                      dateIso: _lastCommunionIso,
                      todayLabel: 'اتناولت النهاردة ✓',
                      onMarkToday: () async {
                        HapticFeedback.mediumImpact();
                        final t = _todayIso();
                        await _storage.setLastCommunionDateIso(t);
                        setState(() => _lastCommunionIso = t);
                      },
                      onPickDate: () => _pickPastDate(isConfession: false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 4. Interactive Liturgy & Communion Preparation Checklist
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'قائمة الاستعداد للقداس والتناول',
                      style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: p.ink),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: checkedCount == _prepItems.length ? p.sage.withValues(alpha: 0.16) : p.goldSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$checkedCount / ${_prepItems.length}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: checkedCount == _prepItems.length ? p.sage : p.gold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ..._prepItems.map((item) {
                final checked = _prepChecklist[item.key] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _prepChecklist[item.key] = !checked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: checked ? p.sage.withValues(alpha: p.isDark ? 0.14 : 0.08) : p.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: checked ? p.sage : p.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            checked
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: checked ? p.sage : p.gold,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: p.ink,
                                    decoration: checked ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                Text(
                                  item.sub,
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    color: p.inkSecondary,
                                    height: 1.45,
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
              }),

              const SizedBox(height: 12),

              // 5. Direct shortcuts to Conscience Exam & Father Schedule
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, luxeRoute(const ConscienceExamView())),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.ink,
                        side: BorderSide(color: p.goldBorder),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(Icons.lock_outline_rounded, size: 17, color: p.gold),
                      label: Text('فحص الضمير', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, luxeRoute(const MyFatherScheduleView())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.accent,
                        foregroundColor: p.onAccent,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.calendar_month_rounded, size: 17),
                      label: Text('مواعيد أبونا', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trackerCard({
    required AppPalette p,
    required IconData icon,
    required String title,
    required String statusText,
    required String dateIso,
    required String todayLabel,
    required VoidCallback onMarkToday,
    required VoidCallback onPickDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: p.gold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: p.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: GoogleFonts.amiri(fontSize: 19, fontWeight: FontWeight.bold, color: p.accent),
          ),
          if (dateIso.isNotEmpty)
            Text(
              dateIso,
              style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
            ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onMarkToday,
            style: ElevatedButton.styleFrom(
              backgroundColor: p.gold,
              foregroundColor: const Color(0xFF19130A),
              padding: const EdgeInsets.symmetric(vertical: 7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            ),
            child: Text(
              todayLabel,
              style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: onPickDate,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'اختيار تاريخ سابق',
              style: GoogleFonts.cairo(fontSize: 11, color: p.inkSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
