import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/sacred_section_banner.dart';
import '../../providers/theme_provider.dart';

List<Map<String, dynamic>> _decodeRitesList(String raw) =>
    (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();

/// Complete Coptic Orthodox Sacraments & Liturgical Rites Reader (8 complete verbatim rites:
/// Lakan, Pentecost Sagda 3 Prostrations, Baptism & Myron, Holy Matrimony 37 prayers,
/// Unction of the Sick / Qandil 7 full prayers, Repentance & Confession, Funeral, Home Blessing)
/// — Lazy ListView.builder with instant prayer-index filter & 100% adaptive AppPalette.
class ChurchSacramentsRitesView extends StatefulWidget {
  final bool embedded;

  const ChurchSacramentsRitesView({super.key, this.embedded = false});

  @override
  State<ChurchSacramentsRitesView> createState() =>
      _ChurchSacramentsRitesViewState();
}

class _ChurchSacramentsRitesViewState extends State<ChurchSacramentsRitesView> {
  static List<Map<String, dynamic>>? _cachedRites;

  List<Map<String, dynamic>> _rites = [];
  int _selectedRiteIdx = 0;
  int _selectedSectionIdx = -1; // -1 = all sections (lazy), >= 0 = focus on 1 prayer
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRites();
  }

  Future<void> _loadRites() async {
    try {
      if (_cachedRites != null) {
        _rites = _cachedRites!;
      } else {
        final raw = await rootBundle
            .loadString('assets/data/sacraments_rites_complete.json');
        _rites = await compute(_decodeRitesList, raw);
        _cachedRites = _rites;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    SpeechPronunciationService().stop();
    super.dispose();
  }

  void _copyText(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1400),
        content: Text('تم نسخ النص', style: GoogleFonts.cairo(fontSize: 12.5)),
      ),
    );
  }

  IconData _resolveIcon(String name) {
    switch (name) {
      case 'water_drop':
        return Icons.water_drop_outlined;
      case 'local_fire_department':
        return Icons.local_fire_department_outlined;
      case 'spa':
        return Icons.spa_outlined;
      case 'workspace_premium':
        return Icons.workspace_premium_outlined;
      case 'healing':
        return Icons.healing_outlined;
      case 'favorite_border':
        return Icons.favorite_border_rounded;
      case 'church':
        return Icons.church_outlined;
      case 'home':
        return Icons.home_outlined;
      default:
        return Icons.auto_stories_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fontScale = context.watch<ThemeProvider>().fontScale;

    final content = _loading
        ? Center(child: CircularProgressIndicator(color: p.accent))
        : _rites.isEmpty
            ? Center(
                child: Text('تعذر تحميل نصوص الطقوس',
                    style: GoogleFonts.cairo(color: p.inkMuted)),
              )
            : _buildRitesBody(p, fontScale);

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'الطقوس الكنسية والأسرار واللقان',
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.w700,
            fontSize: 21,
            color: p.ink,
          ),
        ),
      ),
      body: content,
    );
  }

  Widget _buildRitesBody(AppPalette p, double fontScale) {
    final safeIdx = _selectedRiteIdx.clamp(0, _rites.length - 1);
    final rite = _rites[safeIdx];
    final sections = (rite['sections'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final visibleSections =
        (_selectedSectionIdx >= 0 && _selectedSectionIdx < sections.length)
            ? [sections[_selectedSectionIdx]]
            : sections;

    final riteIcon = _resolveIcon('${rite['icon'] ?? ''}');
    final riteTitle = '${rite['title'] ?? ''}';
    final riteOccasion = '${rite['occasion'] ?? ''}';
    final riteOverview = '${rite['overview'] ?? ''}';

    final bodyStyle = GoogleFonts.amiri(
      fontSize: 19 * fontScale,
      height: 1.85,
      color: p.ink,
    );
    final copticStyle = TextStyle(
      fontFamily: 'Coptic',
      fontSize: 14 * fontScale,
      color: p.accent,
      height: 1.55,
    );

    return Column(
      children: [
        // Sacred Church Sacraments & Qandil Banner
        SacredSectionBanner(
          imageAsset: 'assets/images/banner_sacraments.jpg',
          title: riteTitle,
          subtitle: '$riteOccasion • ${sections.length} قسماً كاملاً',
          badge: 'الطقوس والأسرار الكنسية',
          height: 100,
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        ),

        // Katameros-style Dual Dropdown Bar (Rite / Sacrament + Prayer Section)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: LiturgicalDropdownBox<int>(
                  label: 'السر / الطقس',
                  dense: true,
                  value: safeIdx,
                  items: List.generate(_rites.length, (idx) {
                    return DropdownMenuItem<int>(
                      value: idx,
                      child: Text(
                        '${_rites[idx]['title']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                        ),
                      ),
                    );
                  }),
                  onChanged: (idx) {
                    if (idx == null) return;
                    HapticFeedback.selectionClick();
                    SpeechPronunciationService().stop();
                    setState(() {
                      _selectedRiteIdx = idx;
                      _selectedSectionIdx = -1;
                    });
                  },
                ),
              ),
              if (sections.length > 1) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: LiturgicalDropdownBox<int>(
                    label: 'الانتقال للصلاة (${sections.length})',
                    dense: true,
                    value: _selectedSectionIdx.clamp(-1, sections.length - 1),
                    items: [
                      DropdownMenuItem<int>(
                        value: -1,
                        child: Text(
                          'عرض الطقس كاملاً (${sections.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: p.ink,
                          ),
                        ),
                      ),
                      ...List.generate(sections.length, (sIdx) {
                        return DropdownMenuItem<int>(
                          value: sIdx,
                          child: Text(
                            '${sIdx + 1}. ${sections[sIdx]['title'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 11.8,
                              fontWeight: FontWeight.bold,
                              color: p.accent,
                            ),
                          ),
                        );
                      }),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSectionIdx = v);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),

        // Lazy Virtualized ListView.builder
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
            itemCount: visibleSections.length + 1,
            itemBuilder: (ctx, idx) {
              if (idx == 0) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: p.accent.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.accentSoft,
                            ),
                            child: Icon(riteIcon, color: p.accent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  riteTitle,
                                  style: GoogleFonts.amiri(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: p.ink,
                                  ),
                                ),
                                Text(
                                  '$riteOccasion • ${sections.length} قسماً كاملاً',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: p.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        riteOverview,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          height: 1.6,
                          color: p.inkMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final sec = visibleSections[idx - 1];
              final role = '${sec['role'] ?? 'الكاهن'}';
              final secTitle = '${sec['title'] ?? ''}';
              final secCop = '${sec['coptic'] ?? ''}';
              final secAr = '${sec['arabic'] ?? ''}';
              final isPeople = role.contains('الشعب');

              return GestureDetector(
                onLongPress: () => _copyText('$secTitle\n$secAr'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
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
                          CopticCross(size: 14, color: p.accent),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPeople ? p.crimsonSoft : p.accentSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              role,
                              style: GoogleFonts.cairo(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isPeople ? p.crimson : p.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              secTitle,
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                              ),
                            ),
                          ),
                          SpeechPlayStopButton(
                            textToSpeak: '$secTitle. ${secAr.length > 1600 ? secAr.substring(0, 1600) : secAr}',
                            label: secTitle,
                            playText: 'استماع',
                            stopText: 'إيقاف',
                            compact: true,
                          ),
                        ],
                      ),
                      if (secCop.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: p.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            secCop,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            style: copticStyle,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(secAr, style: bodyStyle),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
