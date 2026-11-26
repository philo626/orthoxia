import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/patron_saint_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/blessing_poster_studio_sheet.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/sacred_section_banner.dart';
import '../../core/widgets/saint_icon_avatar.dart';
import '../../providers/theme_provider.dart';

/// Katameros-Organized Coptic Orthodox Madayeh & Tamagid Reader («مدايح الشهداء والقديسين»):
/// Exact 3-level cascading selector bar right under the Neo-Coptic Banner:
///   1) الحرف الأبجدي (أ، ب، ت، ج، ح، د، ر، س، ش، ص، ع، غ، ف، ق، ك، ل، م، ه، ي)
///   2) اسم الشهيد أو القديس (يُظهر عدد المدائح لو للقديس أكتر من مديح)
///   3) اسم المديح (للتنقل بين مدائح نفس القديس بسهولة)
/// Plus authentic 2-column poetic couplets layout + Neo-Coptic Saint Portrait + Instant Search.
class MadayehLibraryView extends StatefulWidget {
  const MadayehLibraryView({super.key});

  @override
  State<MadayehLibraryView> createState() => _MadayehLibraryViewState();
}

class _MadayehLibraryViewState extends State<MadayehLibraryView> {
  static const List<String> _arabicAlphaOrder = [
    'أ', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص',
    'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي',
  ];

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _showSearch = false;
  String _selectedLetter = 'الكل';
  String _selectedSaint = '';
  String _selectedMadyhId = '';
  String _query = '';
  double _localFontBoost = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await PatronSaintService.ensureLoaded();
      final raw = await rootBundle.loadString('assets/data/madayeh_tamagid.json');
      _items = (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (_items.isNotEmpty) {
        _selectedLetter = 'الكل';
        _selectedSaint = '${_items.first['saint']}';
        _selectedMadyhId = '${_items.first['id']}';
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _resolveSaintPortrait(String saintName) {
    final s = saintName;
    if (s.contains('العذراء')) return 'assets/images/saints/virgin_mary.jpg';
    if (s.contains('ميخائيل')) return 'assets/images/saints/archangel_michael.jpg';
    if (s.contains('مارجرجس')) return 'assets/images/saints/st_george.jpg';
    if (s.contains('مارمرقس')) return 'assets/images/saints/st_mark.jpg';
    if (s.contains('كيرلس السادس')) return 'assets/images/saints/pope_kyrillos.jpg';
    if (s.contains('دميانة')) return 'assets/images/saints/st_demiana.jpg';
    if (s.contains('أنطونيوس')) return 'assets/images/saints/st_anthony.jpg';
    if (s.contains('مارمينا')) return 'assets/images/saints/st_mina.jpg';
    if (s.contains('موسى الأسود')) return 'assets/images/saints/st_moses.jpg';
    if (s.contains('أبانوب')) return 'assets/images/saints/st_abanoub.jpg';
    if (s.contains('أثناسيوس')) return 'assets/images/saints/st_athanasius.jpg';
    if (s.contains('أبو سيفين') || s.contains('مرقوريوس')) {
      return 'assets/images/saints/st_philopateer.jpg';
    }
    // Check PatronSaintService catalog for any other matched portrait
    for (final ps in PatronSaintService.saints) {
      if (ps.shortName.length >= 4 && s.contains(ps.shortName)) {
        return PatronSaintService.getImageUrlForSaint(ps);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fontScale = context.watch<ThemeProvider>().fontScale;

    // 1. Build sorted available letters list
    final letterSet = <String>{};
    for (final item in _items) {
      final l = '${item['letter'] ?? ''}'.trim();
      if (l.isNotEmpty) letterSet.add(l);
    }
    final sortedLetters = letterSet.toList()
      ..sort((a, b) {
        final ia = _arabicAlphaOrder.indexOf(a);
        final ib = _arabicAlphaOrder.indexOf(b);
        return (ia == -1 ? 99 : ia).compareTo(ib == -1 ? 99 : ib);
      });
    final letterOptions = <String>['الكل', ...sortedLetters];
    final safeLetter =
        letterOptions.contains(_selectedLetter) ? _selectedLetter : 'الكل';

    // 2. Filter items by letter & optional search query
    final q = _query.trim();
    final letterFiltered = _items.where((item) {
      if (safeLetter != 'الكل' && '${item['letter']}' != safeLetter) {
        return false;
      }
      if (q.isEmpty) return true;
      return '${item['saint']}'.contains(q) ||
          '${item['title']}'.contains(q) ||
          '${item['refrain']}'.contains(q);
    }).toList();

    // 3. Group unique saints under current letter/query (preserving order)
    final saintMap = <String, List<Map<String, dynamic>>>{};
    for (final item in letterFiltered) {
      final sName = '${item['saint']}';
      saintMap.putIfAbsent(sName, () => []).add(item);
    }
    final uniqueSaints = saintMap.keys.toList();
    final safeSaint = uniqueSaints.isEmpty
        ? ''
        : (saintMap.containsKey(_selectedSaint) ? _selectedSaint : uniqueSaints.first);

    // 4. All madayeh belonging to the chosen saint!
    final saintMadayeh = saintMap[safeSaint] ?? const <Map<String, dynamic>>[];
    final current = saintMadayeh.isEmpty
        ? null
        : saintMadayeh.firstWhere(
            (m) => '${m['id']}' == _selectedMadyhId,
            orElse: () => saintMadayeh.first,
          );
    final safeMadyhId = current == null ? '' : '${current['id']}';

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        elevation: 0,
        title: Text(
          'مدايح الشهداء والقديسين',
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.bold,
            fontSize: 23,
            color: p.ink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'بحث باسم القديس أو المديح',
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: p.accent,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) _query = '';
              });
            },
          ),
          IconButton(
            tooltip: 'تكبير الخط',
            icon: Icon(Icons.text_increase_rounded, size: 20, color: p.inkSecondary),
            onPressed: () => setState(
              () => _localFontBoost = (_localFontBoost + 1.5).clamp(-3.0, 8.0),
            ),
          ),
          IconButton(
            tooltip: 'تصغير الخط',
            icon: Icon(Icons.text_decrease_rounded, size: 20, color: p.inkSecondary),
            onPressed: () => setState(
              () => _localFontBoost = (_localFontBoost - 1.5).clamp(-3.0, 8.0),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: p.accent, strokeWidth: 2))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: Column(
                  children: [
                    // Handcrafted Neo-Coptic Angels & Praises Banner
                    SacredSectionBanner(
                      imageAsset: 'assets/images/banner_madayeh.jpg',
                      title: 'المدائح والتماجيد القبطية',
                      subtitle:
                          '${_items.length} مديحاً وتمجيداً لـ ${_items.map((e) => e['saint']).toSet().length} قديساً وشهيداً — مرتبة بالحرف والقديس واسم المديح',
                      badge: 'كنوز الكنيسة',
                      height: 108,
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    ),

                    if (_showSearch)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          autofocus: true,
                          onChanged: (v) => setState(() => _query = v),
                          style: GoogleFonts.cairo(color: p.ink, fontSize: 13),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'ابحث باسم القديس أو الشهيد أو المديح...',
                            prefixIcon: Icon(Icons.search_rounded, size: 19),
                          ),
                        ),
                      ),

                    // ==============================================================
                    // EXACT KATAMEROS-STYLE 3-DROPDOWN SELECTOR BAR:
                    // [ الحرف ]  +  [ اسم الشهيد / القديس ]  +  [ اسم المديح ]
                    // ==============================================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Dropdown 1: الحرف
                              SizedBox(
                                width: 84,
                                child: LiturgicalDropdownBox<String>(
                                  label: 'الحرف',
                                  dense: true,
                                  value: safeLetter,
                                  items: letterOptions
                                      .map(
                                        (l) => DropdownMenuItem<String>(
                                          value: l,
                                          child: Text(
                                            l,
                                            style: GoogleFonts.cairo(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: p.ink,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedLetter = v;
                                      _selectedSaint = '';
                                      _selectedMadyhId = '';
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Dropdown 2: اسم الشهيد أو القديس
                              Expanded(
                                child: uniqueSaints.isEmpty
                                    ? Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: p.surfaceSubtle,
                                          borderRadius: BorderRadius.circular(13),
                                          border: Border.all(color: p.border),
                                        ),
                                        child: Text(
                                          'لا يوجد قديس بهذا الحرف',
                                          style: GoogleFonts.cairo(
                                              fontSize: 12, color: p.inkMuted),
                                        ),
                                      )
                                    : LiturgicalDropdownBox<String>(
                                        label: 'الشهيد / القديس (${uniqueSaints.length})',
                                        dense: true,
                                        value: safeSaint,
                                        items: uniqueSaints.map((sName) {
                                          final cnt = saintMap[sName]?.length ?? 1;
                                          return DropdownMenuItem<String>(
                                            value: sName,
                                            child: Text(
                                              cnt > 1 ? '$sName ($cnt مدائح)' : sName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.cairo(
                                                fontSize: 12.2,
                                                fontWeight: FontWeight.bold,
                                                color: p.ink,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (v) {
                                          if (v == null) return;
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _selectedSaint = v;
                                            _selectedMadyhId = '';
                                          });
                                        },
                                      ),
                              ),
                            ],
                          ),
                          // Dropdown 3: اسم المديح (always visible clearly so multi-madyh saints shine!)
                          if (saintMadayeh.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            LiturgicalDropdownBox<String>(
                              label: saintMadayeh.length > 1
                                  ? 'اختر المديح (${saintMadayeh.length} مدائح لهذا القديس)'
                                  : 'اسم المديح',
                              dense: true,
                              value: safeMadyhId,
                              items: saintMadayeh.map((m) {
                                return DropdownMenuItem<String>(
                                  value: '${m['id']}',
                                  child: Text(
                                    '${m['title']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12.2,
                                      fontWeight: FontWeight.bold,
                                      color: p.accent,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                HapticFeedback.selectionClick();
                                setState(() => _selectedMadyhId = v);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 2-Column Traditional Poetic Couplets Reader
                    Expanded(
                      child: current == null
                          ? Center(
                              child: Text('لا يوجد مديح مطابق للبحث.',
                                  style: GoogleFonts.cairo(color: p.inkMuted)),
                            )
                          : _buildMadeyhCard(
                              context,
                              p,
                              current,
                              saintMadayeh.length,
                              fontScale,
                            ),
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
    int saintTotalPraises,
    double fontScale,
  ) {
    final couplets = (item['couplets'] as List? ?? [])
        .map((c) => List<String>.from((c as List).map((e) => '$e')))
        .toList();
    final saintName = '${item['saint']}';
    final portraitUrl = _resolveSaintPortrait(saintName);

    final fullPlain = StringBuffer()
      ..writeln('$saintName — ${item['title']}')
      ..writeln('المرد: ${item['refrain']}')
      ..writeln();
    for (final c in couplets) {
      fullPlain.writeln('${c[0]}   •   ${c.length > 1 ? c[1] : ''}');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 36),
      children: [
        // Illuminated Saint & Praise Header Card with Neo-Coptic Icon Portrait
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.goldSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.goldBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  if (portraitUrl != null) ...[
                    SaintIconAvatar(
                      imageUrl: portraitUrl,
                      size: 56,
                      shape: SaintAvatarShape.arch,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: portraitUrl != null
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: portraitUrl != null
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            CopticCross(size: 14, color: p.accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                saintName,
                                textAlign: portraitUrl != null
                                    ? TextAlign.start
                                    : TextAlign.center,
                                style: GoogleFonts.amiri(
                                  fontSize: (20 + _localFontBoost * 0.4) *
                                      fontScale.clamp(0.85, 1.3),
                                  fontWeight: FontWeight.bold,
                                  color: p.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item['title']}',
                          textAlign: portraitUrl != null
                              ? TextAlign.start
                              : TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 12.2,
                            fontWeight: FontWeight.w700,
                            color: p.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if ('${item['refrain'] ?? ''}'.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

        // 2-Column Rhythmic Poetic Couplets (Exact Katameros Traditional Layout!)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                decoration: BoxDecoration(
                  color: isAlt ? p.surfaceSubtle : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        rightHemistich,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: (18.5 + _localFontBoost) *
                              fontScale.clamp(0.85, 1.35),
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                          height: 1.55,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: CopticCross(
                        size: 11,
                        color: p.gold.withValues(alpha: 0.75),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        leftHemistich,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: (18.5 + _localFontBoost) *
                              fontScale.clamp(0.85, 1.35),
                          fontWeight: FontWeight.w600,
                          color: p.inkSecondary,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 14),

        // Clean Share & Copy Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(ClipboardData(text: fullPlain.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم نسخ المديح كاملاً', style: GoogleFonts.cairo()),
                    ),
                  );
                },
                icon: Icon(Icons.copy_rounded, size: 17, color: p.accent),
                label: Text('نسخ المديح', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  BlessingPosterStudioSheet.show(
                    context,
                    title: saintName,
                    bodyText: couplets.take(4).map((c) => '${c[0]} — ${c.length > 1 ? c[1] : ''}').join('\n'),
                    reference: '${item['title']}',
                  );
                },
                icon: const Icon(Icons.ios_share_rounded, size: 17),
                label: Text('مشاركة كبطاقة بركة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
