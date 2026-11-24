import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../providers/theme_provider.dart';

/// Complete Raising of Incense (رفع بخور عشية وباكر) Reader:
/// - 14 canonical sections from Elisoneemas & Thanksgiving through Absolution & Final Blessing
/// - Instant 5-checkbox language/role toggle bar: ع (عربي) | م (معرّب) | ق (قبطي) | E (English) | ص.ك (سراً)
/// - Quick dropdown section switcher just like Orsozoxi, with calm modern illuminated styling
class RaisingOfIncenseView extends StatefulWidget {
  const RaisingOfIncenseView({super.key});

  @override
  State<RaisingOfIncenseView> createState() => _RaisingOfIncenseViewState();
}

class _RaisingOfIncenseViewState extends State<RaisingOfIncenseView> {
  List<Map<String, dynamic>> _sections = [];
  bool _loading = true;
  int _selectedIdx = 0;

  bool _showArabic = true;
  bool _showArabized = true;
  bool _showCoptic = true;
  bool _showEnglish = false;
  bool _showSilent = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final raw = await rootBundle.loadString('assets/data/raising_of_incense.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _sections = (map['sections'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _roleColor(AppPalette p, String role) {
    switch (role) {
      case 'priest':
      case 'priest_silent':
        return p.crimson;
      case 'deacon':
        return p.accent;
      default:
        return p.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fontScale = context.watch<ThemeProvider>().fontScale;
    final copticToday = CopticCalendarService.todayLiturgical();

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رفع بخور عشية وباكر',
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: p.ink,
                height: 1.15,
              ),
            ),
            Text(
              '${copticToday.formatted} • ${copticToday.seasonName}',
              style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
            ),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: p.accent, strokeWidth: 2))
          : _sections.isEmpty
              ? Center(
                  child: Text('تعذر تحميل نص رفع البخور',
                      style: GoogleFonts.cairo(color: p.inkMuted)),
                )
              : Column(
                  children: [
                    // 1. Instant 5-checkbox language strip (ع | م | ق | E | ص.ك)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: p.surfaceSubtle,
                        border: Border(
                          top: BorderSide(color: p.border, width: 0.7),
                          bottom: BorderSide(color: p.border, width: 0.7),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _toggle(p, 'ع', _showArabic, () {
                              if (_showArabic && !_showArabized && !_showCoptic && !_showEnglish) return;
                              setState(() => _showArabic = !_showArabic);
                            }),
                            const SizedBox(width: 6),
                            _toggle(p, 'م', _showArabized, () => setState(() => _showArabized = !_showArabized)),
                            const SizedBox(width: 6),
                            _toggle(p, 'ق', _showCoptic, () => setState(() => _showCoptic = !_showCoptic)),
                            const SizedBox(width: 6),
                            _toggle(p, 'E', _showEnglish, () => setState(() => _showEnglish = !_showEnglish)),
                            const SizedBox(width: 6),
                            _toggle(p, 'ص.ك', _showSilent, () => setState(() => _showSilent = !_showSilent)),
                          ],
                        ),
                      ),
                    ),

                    // 2. Quick Section Dropdown Selector (exact 1-tap navigation!)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.goldBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          dropdownColor: p.surface,
                          value: _selectedIdx.clamp(0, _sections.length - 1),
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: p.accent),
                          items: List.generate(_sections.length, (i) {
                            return DropdownMenuItem<int>(
                              value: i,
                              child: Text(
                                '${_sections[i]['title']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: p.ink,
                                ),
                              ),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedIdx = val);
                            }
                          },
                        ),
                      ),
                    ),

                    // 3. Illuminated Reader Body
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 740),
                          child: _buildSectionBody(p, fontScale),
                        ),
                      ),
                    ),

                    // 4. Prev / Next Section Navigation Bar
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      decoration: BoxDecoration(
                        color: p.surface,
                        border: Border(top: BorderSide(color: p.border)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _selectedIdx > 0
                                    ? () => setState(() => _selectedIdx--)
                                    : null,
                                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                                label: Text('السابق', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_selectedIdx + 1} / ${_sections.length}',
                              style: GoogleFonts.cairo(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: p.accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _selectedIdx < _sections.length - 1
                                    ? () => setState(() => _selectedIdx++)
                                    : null,
                                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                                label: Text('التالي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSectionBody(AppPalette p, double fontScale) {
    final sec = _sections[_selectedIdx];
    final rawVerses = (sec['verses'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .where((v) => _showSilent || v['role'] != 'priest_silent')
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Row(
          children: [
            CopticCross(size: 16, color: p.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${sec['title']}',
                style: GoogleFonts.amiri(
                  fontSize: 22 * fontScale.clamp(0.85, 1.3),
                  fontWeight: FontWeight.bold,
                  color: p.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (rawVerses.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
            ),
            child: Text(
              'فعّل خيار «ص.ك» في الأعلى لإظهار صلوات الكاهن السرية لهذا القسم.',
              style: GoogleFonts.cairo(color: p.inkMuted, fontSize: 13),
            ),
          )
        else
          ...rawVerses.map((v) {
            final role = '${v['role'] ?? 'people'}';
            final roleAr = '${v['roleArabic'] ?? 'الشعب'}';
            final ar = '${v['arabic'] ?? ''}'.trim();
            final ab = '${v['arabized'] ?? ''}'.trim();
            final cop = '${v['coptic'] ?? ''}'.trim();
            final en = '${v['english'] ?? ''}'.trim();
            final rColor = _roleColor(p, role);
            final isPeople = role == 'people';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isPeople ? p.goldSoft.withValues(alpha: p.isDark ? 0.45 : 0.6) : p.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isPeople ? p.goldBorder : p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: rColor.withValues(alpha: p.isDark ? 0.18 : 0.11),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        roleAr,
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: rColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_showArabic && ar.isNotEmpty)
                    SelectableText(
                      ar,
                      style: GoogleFonts.amiri(
                        fontSize: 19.5 * fontScale,
                        height: 1.85,
                        color: p.ink,
                        fontWeight: isPeople ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  if (_showArabized && ab.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SelectableText(
                      ab,
                      style: GoogleFonts.cairo(
                        fontSize: 14 * fontScale,
                        height: 1.65,
                        color: p.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_showCoptic && cop.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SelectableText(
                      cop,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Coptic',
                        fontSize: 15 * fontScale,
                        height: 1.6,
                        color: p.inkSecondary,
                      ),
                    ),
                  ],
                  if (_showEnglish && en.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SelectableText(
                      en,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      style: GoogleFonts.cairo(
                        fontSize: 13 * fontScale,
                        height: 1.55,
                        color: p.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _toggle(AppPalette p, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? p.accent : p.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? p.accent : p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 14,
              color: active ? p.onAccent : p.inkMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: active ? p.onAccent : p.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
