import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../providers/theme_provider.dart';

/// Complete 18-Season Coptic Liturgical Rites Encyclopedia («الموسوعة الطقسية الشاملة»).
class LiturgicalEncyclopediaView extends StatefulWidget {
  const LiturgicalEncyclopediaView({super.key});

  @override
  State<LiturgicalEncyclopediaView> createState() => _LiturgicalEncyclopediaViewState();
}

class _LiturgicalEncyclopediaViewState extends State<LiturgicalEncyclopediaView> {
  List<Map<String, dynamic>> _rites = [];
  bool _loading = true;
  int _selectedIdx = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/liturgical_rites_encyclopedia.json');
      _rites = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fontScale = context.watch<ThemeProvider>().fontScale;

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
              'الموسوعة الطقسية الشاملة',
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: p.ink,
                height: 1.15,
              ),
            ),
            Text(
              'طقس وألحان وصوم وقراءات ١٨ موسماً وعيداً كنسياً',
              style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
            ),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: p.accent, strokeWidth: 2))
          : _rites.isEmpty
              ? Center(child: Text('تعذر تحميل الموسوعة الطقسية', style: GoogleFonts.cairo(color: p.inkMuted)))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 740),
                    child: Column(
                      children: [
                        // Dropdown Quick Selector (matching Orsozoxi's exact fast season switcher)
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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
                              value: _selectedIdx.clamp(0, _rites.length - 1),
                              icon: Icon(Icons.keyboard_arrow_down_rounded, color: p.accent),
                              items: List.generate(_rites.length, (i) {
                                return DropdownMenuItem<int>(
                                  value: i,
                                  child: Text(
                                    '${i + 1}. ${_rites[i]['title']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: p.ink,
                                    ),
                                  ),
                                );
                              }),
                              onChanged: (v) {
                                if (v != null) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedIdx = v);
                                }
                              },
                            ),
                          ),
                        ),

                        Expanded(
                          child: _buildRiteDetails(p, _rites[_selectedIdx], fontScale),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildRiteDetails(AppPalette p, Map<String, dynamic> rite, double fontScale) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
      children: [
        // Season Header Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: p.goldSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.goldBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CopticCross(size: 18, color: p.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${rite['title']}',
                      style: GoogleFonts.amiri(
                        fontSize: 23 * fontScale.clamp(0.85, 1.3),
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'الفترة: ${rite['period']}',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: p.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _infoBlock(
          p: p,
          icon: Icons.music_note_rounded,
          title: 'نغمة ولحن الموسم',
          body: '${rite['tune']}',
          fontScale: fontScale,
        ),
        _infoBlock(
          p: p,
          icon: Icons.schedule_rounded,
          title: 'ترتيب صلوات الأجبية',
          body: '${rite['agpeya']}',
          fontScale: fontScale,
        ),
        _infoBlock(
          p: p,
          icon: Icons.spa_outlined,
          title: 'درجة الصوم والانقطاع',
          body: '${rite['fasting']}',
          fontScale: fontScale,
        ),
        _infoBlock(
          p: p,
          icon: Icons.church_outlined,
          title: 'الملاحظات والترتيب الطقسي الكامل',
          body: '${rite['liturgy_notes']}',
          fontScale: fontScale,
        ),

        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedIdx > 0
                    ? () => setState(() => _selectedIdx--)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: Text('الموسم السابق', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedIdx < _rites.length - 1
                    ? () => setState(() => _selectedIdx++)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: Text('الموسم التالي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoBlock({
    required AppPalette p,
    required IconData icon,
    required String title,
    required String body,
    required double fontScale,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: p.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: p.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            body,
            style: GoogleFonts.cairo(
              fontSize: 13.8 * fontScale,
              height: 1.75,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }
}
