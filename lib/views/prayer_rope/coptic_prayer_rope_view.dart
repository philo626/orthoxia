import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';

class CopticPrayerRopeView extends StatefulWidget {
  const CopticPrayerRopeView({super.key});

  @override
  State<CopticPrayerRopeView> createState() => _CopticPrayerRopeViewState();
}

class _CopticPrayerRopeViewState extends State<CopticPrayerRopeView>
    with SingleTickerProviderStateMixin {
  int _totalBeads = 41; // 41 (Coptic Kyrie Eleison count) or 33 (Years of Christ)
  int _currentBead = 0;
  int _completedRopes = 0;
  int _metaniaCount = 0;
  int _selectedPrayerIdx = 0;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  static const List<Map<String, String>> _prayers = [
    {
      'title': 'صلاة يسوع (السهمية)',
      'coptic':
          'Ⲡⲁϭⲟⲓⲥ Ⲓⲏⲥⲟⲩⲥ Ⲡⲓⲭ̀ⲣⲓⲥⲧⲟⲥ Ⲡ̀ϣⲏⲣⲓ ⲙ̀Ⲫ̀ⲛⲟⲩϯ ⲉⲧⲟⲛϧ: ⲛⲁⲓ ⲛⲏⲓ ⲁ̀ⲛⲟⲕ ϧⲁ ⲡⲓⲣⲉϥⲉⲣⲛⲟⲃⲓ.',
      'arabized':
          'باشويس إيسوس بي إخريستوس إبشيري إم إفنوتي إت أونخ: ناي ني آنوك خا بي ريف إيرنوفي.',
      'arabic': 'يا ربي يسوع المسيح ابن الله الحي، ارحمني أنا الخاطئ.',
    },
    {
      'title': 'كيرياليسون (٤١ مرة)',
      'coptic': 'Ⲕⲩⲣⲓⲉ ⲉ̀ⲗⲉⲏ̀ⲥⲟⲛ (overline{ⲙⲁ})',
      'arabized': 'كيرياليسون • يا رب ارحم',
      'arabic': 'يا رب ارحم (٤١ حبة على مثال الـ ٣٩ جلدة والحربة وإكليل الشوك).',
    },
    {
      'title': 'صلاة العشار التائب',
      'coptic': 'Ⲫ̀ⲛⲟⲩϯ ⲭⲱ ⲛⲏⲓ ⲉ̀ⲃⲟⲗ ⲁ̀ⲛⲟⲕ ϧⲁ ⲡⲓⲣⲉϥⲉⲣⲛⲟⲃⲓ.',
      'arabized': 'إفنوتي كو ني إيفول آنوك خا بي ريف إيرنوفي.',
      'arabic': 'اللهم ارحمني أنا الخاطئ، اللهم اغفر لي كثرة آثامي.',
    },
  ];

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _advanceBead() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_currentBead + 1 >= _totalBeads) {
        _currentBead = 0;
        _completedRopes++;
        HapticFeedback.heavyImpact();
      } else {
        _currentBead++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prayer = _prayers[_selectedPrayerIdx];

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Toggle 41 vs 33 beads
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _totalBeads = _totalBeads == 41 ? 33 : 41;
                        _currentBead = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryGold.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        '$_totalBeads حبة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGoldLight,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'المسبحة القبطية والمطانيات',
                    style: GoogleFonts.cairo(
                      fontSize: 17.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  LuxeCircleButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Prayer Type Selector Chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: _prayers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final sel = idx == _selectedPrayerIdx;
                  return ChoiceChip(
                    label: Text(
                      _prayers[idx]['title']!,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: sel ? Colors.black : AppColors.textLight,
                      ),
                    ),
                    selected: sel,
                    selectedColor: AppColors.primaryGold,
                    backgroundColor: AppColors.cardNavy,
                    side: BorderSide(
                      color: sel
                          ? AppColors.primaryGold
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPrayerIdx = idx);
                    },
                  );
                },
              ),
            ),

            // Interactive Circular 33/41-Bead Coptic Prayer Rope
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _advanceBead,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) {
                      return SizedBox(
                        width: 300,
                        height: 300,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(300, 300),
                              painter: _PrayerRopePainter(
                                totalBeads: _totalBeads,
                                currentBead: _currentBead,
                                phase: _pulseCtrl.value,
                              ),
                            ),
                            // Center Counter & Coptic Cross
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CopticCross(size: 46, glow: 0.8),
                                const SizedBox(height: 8),
                                Text(
                                  '${_currentBead + 1} / $_totalBeads',
                                  style: GoogleFonts.roboto(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGoldLight,
                                  ),
                                ),
                                Text(
                                  'اضغط في أي مكان للتسبيح',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                if (_completedRopes > 0) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGold.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'أكملت $_completedRopes مسبحة ☦',
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGoldLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Trilingual Jesus Prayer Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.obsidianCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primaryGold.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    prayer['coptic']!,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: GoogleFonts.cairo(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGoldLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    prayer['arabized']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      color: AppColors.textArabized,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    prayer['arabic']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      SpeechPronunciationService().speakText(
                        '${prayer['arabized']}. ${prayer['arabic']}',
                        label: prayer['title']!,
                      );
                    },
                    icon: const Icon(Icons.volume_up_rounded, size: 17, color: AppColors.primaryGold),
                    label: Text(
                      'استمع لنطق الصلاة السهمية 🔊',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate(key: ValueKey(_selectedPrayerIdx)).fadeIn(duration: 280.ms),

            const SizedBox(height: 12),

            // Bottom Row: Metanias Counter + Reset
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: PressScale(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _metaniaCount++);
                      },
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: AppColors.champagne,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGold.withValues(alpha: 0.3),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.self_improvement_rounded,
                                color: Colors.black, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'تسجيل مطانية ($_metaniaCount)',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  LuxeCircleButton(
                    icon: Icons.refresh_rounded,
                    size: 50,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _currentBead = 0;
                        _metaniaCount = 0;
                      });
                    },
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

class _PrayerRopePainter extends CustomPainter {
  final int totalBeads;
  final int currentBead;
  final double phase;

  _PrayerRopePainter({
    required this.totalBeads,
    required this.currentBead,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.42;

    // Subtle knotted cord circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = AppColors.primaryGold.withValues(alpha: 0.25),
    );

    for (int i = 0; i < totalBeads; i++) {
      // Start from bottom (pi/2) where the Coptic cross tassel hangs
      final angle = (math.pi / 2) + (i / totalBeads) * 2 * math.pi;
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * radius;

      final isPassed = i <= currentBead;
      final isCurrent = i == currentBead;
      final isDividerBead = i > 0 && i % 10 == 0;

      final beadRadius = isCurrent ? 8.5 : (isDividerBead ? 6.5 : 5.0);

      if (isCurrent) {
        final glowR = 14.0 + 4.0 * math.sin(phase * 2 * math.pi);
        canvas.drawCircle(
          pos,
          glowR,
          Paint()
            ..color = AppColors.primaryGold.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }

      final beadPaint = Paint()
        ..shader = RadialGradient(
          colors: isPassed
              ? [const Color(0xFFFFF2D6), AppColors.primaryGold, AppColors.primaryGoldDark]
              : [const Color(0xFF3A3630), const Color(0xFF1B1916)],
        ).createShader(Rect.fromCircle(center: pos, radius: beadRadius));

      canvas.drawCircle(pos, beadRadius, beadPaint);
      canvas.drawCircle(
        pos,
        beadRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = isPassed
              ? AppColors.primaryGoldLight
              : Colors.white.withValues(alpha: 0.15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PrayerRopePainter old) =>
      old.currentBead != currentBead ||
      old.totalBeads != totalBeads ||
      old.phase != phase;
}
