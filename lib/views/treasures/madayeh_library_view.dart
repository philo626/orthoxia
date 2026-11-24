import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/blessing_poster_studio_sheet.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../providers/theme_provider.dart';

/// Alphabetical Coptic Orthodox Madayeh & Tamagid Reader («المدائح والتماجيد»):
/// - Alphabetical letter filter + Search + Dropdown Saint Picker
/// - Authentic 2-column poetic couplets layout adapted to Warm Parchment / Charcoal / AMOLED
class MadayehLibraryView extends StatefulWidget {
  const MadayehLibraryView({super.key});

  @override
  State<MadayehLibraryView> createState() => _MadayehLibraryViewState();
}

class _MadayehLibraryViewState extends State<MadayehLibraryView> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _selectedLetter = 'الكل';
  String _query = '';
  int _selectedIdx = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/madayeh_tamagid.json');
      _items = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fontScale = context.watch<ThemeProvider>().fontScale;

    final letters = <String>['الكل'];
    for (final item in _items) {
      final l = '${item['letter'] ?? ''}'.trim();
      if (l.isNotEmpty && !letters.contains(l)) letters.add(l);
    }

    final filtered = _items.where((item) {
      if (_selectedLetter != 'الكل' && '${item['letter']}' != _selectedLetter) {
        return false;
      }
      final q = _query.trim();
      if (q.isEmpty) return true;
      return '${item['saint']}'.contains(q) ||
          '${item['title']}'.contains(q) ||
          '${item['refrain']}'.contains(q);
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
              'مدائح وتماجيد القديسين',
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: p.ink,
                height: 1.15,
              ),
            ),
            Text(
              '${_items.length} مديحاً وتمجيداً للعذراء والشهداء والقديسين',
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
                          hintText: 'ابحث باسم القديس أو الشهيد (العذراء، مارجرجس، مارمينا، أبو سيفين...)',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                        ),
                      ),
                    ),

                    // Alphabetical Letter Strip
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: letters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          final l = letters[i];
                          final sel = l == _selectedLetter;
                          return ChoiceChip(
                            showCheckmark: false,
                            selected: sel,
                            selectedColor: p.accent,
                            backgroundColor: p.surface,
                            side: BorderSide(color: sel ? p.accent : p.border),
                            label: Text(
                              l,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: sel ? p.onAccent : p.ink,
                              ),
                            ),
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedLetter = l;
                                _selectedIdx = 0;
                              });
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Saint & Madyh Dropdown Picker
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
                              final f = filtered[i];
                              return DropdownMenuItem<int>(
                                value: i,
                                child: Text(
                                  '${f['saint']} — ${f['title']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12.5,
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

                    // 2-Column Traditional Couplet Reader
                    Expanded(
                      child: current == null
                          ? Center(
                              child: Text('لا يوجد مديح مطابق للبحث.',
                                  style: GoogleFonts.cairo(color: p.inkMuted)),
                            )
                          : _buildMadeyhCard(context, p, current, fontScale),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMadeyhCard(
    BuildContext context,
    AppPalette p,
    Map<String, dynamic> item,
    double fontScale,
  ) {
    final couplets = (item['couplets'] as List? ?? [])
        .map((c) => List<String>.from((c as List).map((e) => '$e')))
        .toList();

    final fullPlain = StringBuffer()
      ..writeln('${item['saint']} — ${item['title']}')
      ..writeln('المرد: ${item['refrain']}')
      ..writeln();
    for (final c in couplets) {
      fullPlain.writeln('${c[0]}   •   ${c.length > 1 ? c[1] : ''}');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
      children: [
        // Illuminated Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.goldSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.goldBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CopticCross(size: 16, color: p.accent),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${item['saint']}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 22 * fontScale.clamp(0.85, 1.3),
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CopticCross(size: 16, color: p.accent),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${item['title']}',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: p.accent,
                ),
              ),
              if ('${item['refrain'] ?? ''}'.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.border),
                  ),
                  child: Text(
                    'المرد: ${item['refrain']}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: p.crimson,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2-Column Rhythmic Poetic Couplets (just like Orsozoxi!)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: List.generate(couplets.length, (idx) {
              final pair = couplets[idx];
              final rightHemistich = pair.isNotEmpty ? pair[0] : '';
              final leftHemistich = pair.length > 1 ? pair[1] : '';
              final isAlt = idx.isOdd;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: isAlt ? p.surfaceSubtle : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '+ $rightHemistich',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 18.5 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                          height: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: p.goldBorder,
                    ),
                    Expanded(
                      child: Text(
                        leftHemistich,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 18.5 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: p.accent,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: fullPlain.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم نسخ المديح بالكامل', style: GoogleFonts.cairo())),
                );
              },
              icon: Icon(Icons.copy_rounded, size: 16, color: p.accent),
              label: Text('نسخ المديح', style: GoogleFonts.cairo(color: p.accent, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () {
                BlessingPosterStudioSheet.show(
                  context,
                  title: '${item['saint']}',
                  bodyText: couplets.take(4).map((c) => '${c[0]} — ${c.length > 1 ? c[1] : ''}').join('\n'),
                  reference: '${item['title']}',
                );
              },
              icon: const Icon(Icons.ios_share_rounded, size: 16),
              label: Text('مشاركة بطاقة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}
