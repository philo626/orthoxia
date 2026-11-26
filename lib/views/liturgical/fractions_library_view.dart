import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/blessing_poster_studio_sheet.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../core/widgets/sacred_section_banner.dart';
import '../../providers/theme_provider.dart';

/// Complete Seasonal & Annual Fractions Encyclopedia («صلوات القِسَم» — 39+ Fractions).
class FractionsLibraryView extends StatefulWidget {
  const FractionsLibraryView({super.key});

  @override
  State<FractionsLibraryView> createState() => _FractionsLibraryViewState();
}

class _FractionsLibraryViewState extends State<FractionsLibraryView> {
  List<Map<String, dynamic>> _fractions = [];
  bool _loading = true;
  String _query = '';
  int _selectedIdx = 0;

  @override
  void initState() {
    super.initState();
    _loadFractions();
  }

  Future<void> _loadFractions() async {
    try {
      final raw = await rootBundle.loadString('assets/data/seasonal_fractions.json');
      final list = (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _fractions = list;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fontScale = context.watch<ThemeProvider>().fontScale;

    final filtered = _query.trim().isEmpty
        ? _fractions
        : _fractions.where((f) {
            final q = _query.trim();
            return '${f['title']}'.contains(q) ||
                '${f['occasion']}'.contains(q) ||
                '${f['text']}'.contains(q);
          }).toList();

    final safeIdx = filtered.isEmpty ? 0 : _selectedIdx.clamp(0, filtered.length - 1);
    final current = filtered.isEmpty ? null : filtered[safeIdx];

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
              'صلوات القِسَم المقدسة',
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: p.ink,
                height: 1.15,
              ),
            ),
            Text(
              '${_fractions.length} قسمة سنوية وموسمية وللأعياد',
              style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
            ),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: p.accent, strokeWidth: 2))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: Column(
                  children: [
                    SacredSectionBanner(
                      imageAsset: 'assets/images/thumb_cyril.jpg',
                      title: 'صلوات القِسَم المقدسة',
                      subtitle: '${_fractions.length} قسمة سنوية وموسمية وللأعياد والأصوام',
                      badge: 'الخولاجي المقدس',
                      height: 98,
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    ),
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                      child: TextField(
                        onChanged: (v) => setState(() {
                          _query = v;
                          _selectedIdx = 0;
                        }),
                        style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                        decoration: const InputDecoration(
                          hintText: 'ابحث عن قسمة (الميلاد، الصوم الكبير، القيامة، النيروز، العذراء...)',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                        ),
                      ),
                    ),

                    // Quick Dropdown Selector (matching Orsozoxi speed!)
                    if (filtered.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                            value: safeIdx,
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: p.accent),
                            items: List.generate(filtered.length, (i) {
                              return DropdownMenuItem<int>(
                                value: i,
                                child: Text(
                                  '${i + 1}. ${filtered[i]['title']}',
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
                            onChanged: (v) {
                              if (v != null) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedIdx = v);
                              }
                            },
                          ),
                        ),
                      ),

                    // Illuminated Fraction Reader
                    Expanded(
                      child: current == null
                          ? Center(
                              child: Text('لا توجد قسمة مطابقة للبحث.',
                                  style: GoogleFonts.cairo(color: p.inkMuted)),
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: p.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: p.goldBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          CopticCross(size: 16, color: p.accent),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${current['title']}',
                                              style: GoogleFonts.amiri(
                                                fontSize: 21 * fontScale.clamp(0.85, 1.3),
                                                fontWeight: FontWeight.bold,
                                                color: p.crimson,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if ('${current['occasion'] ?? ''}'.isNotEmpty &&
                                          current['occasion'] != current['title']) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'المناسبة: ${current['occasion']}',
                                          style: GoogleFonts.cairo(
                                            fontSize: 11.5,
                                            color: p.accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Divider(color: p.border, height: 1),
                                      const SizedBox(height: 14),
                                      SelectableText(
                                        '${current['text']}',
                                        style: GoogleFonts.amiri(
                                          fontSize: 20 * fontScale,
                                          height: 1.9,
                                          color: p.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Divider(color: p.border, height: 1),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(
                                                  text: '${current['title']}\n\n${current['text']}'));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('تم نسخ نص القسمة',
                                                      style: GoogleFonts.cairo()),
                                                ),
                                              );
                                            },
                                            icon: Icon(Icons.copy_rounded,
                                                size: 16, color: p.accent),
                                            label: Text('نسخ النص',
                                                style: GoogleFonts.cairo(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: p.accent)),
                                          ),
                                          const Spacer(),
                                          TextButton.icon(
                                            onPressed: () {
                                              final rawText = '${current['text']}';
                                              BlessingPosterStudioSheet.show(
                                                context,
                                                title: '${current['title']}',
                                                bodyText: rawText.length > 260
                                                    ? '${rawText.substring(0, 260)}...'
                                                    : rawText,
                                                reference: 'الخولاجي المقدس — صلوات القسمة',
                                              );
                                            },
                                            icon: Icon(Icons.ios_share_rounded,
                                                size: 16, color: p.accent),
                                            label: Text('مشاركة',
                                                style: GoogleFonts.cairo(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: p.accent)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // Quick Prev/Next row
                                Row(
                                  children: [
                                    Expanded(
                                      child: PressScale(
                                        onTap: safeIdx > 0
                                            ? () => setState(() => _selectedIdx = safeIdx - 1)
                                            : null,
                                        child: OutlinedButton.icon(
                                          onPressed: safeIdx > 0
                                              ? () => setState(() => _selectedIdx = safeIdx - 1)
                                              : null,
                                          icon: const Icon(Icons.chevron_right_rounded, size: 18),
                                          label: Text('القسمة السابقة',
                                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: safeIdx < filtered.length - 1
                                            ? () => setState(() => _selectedIdx = safeIdx + 1)
                                            : null,
                                        icon: const Icon(Icons.chevron_left_rounded, size: 18),
                                        label: Text('القسمة التالية',
                                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
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
