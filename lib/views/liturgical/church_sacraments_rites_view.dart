import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../providers/theme_provider.dart';

/// Complete Coptic Orthodox Sacraments & Liturgical Rites Reader (8 complete rites:
/// Lakan, Pentecost Sagda, Baptism & Myron, Matrimony, Unction of the Sick / Qandil,
/// Repentance & Confession, Funeral, and Home Blessing) — 100% adaptive to AppPalette.
class ChurchSacramentsRitesView extends StatefulWidget {
  final bool embedded;

  const ChurchSacramentsRitesView({super.key, this.embedded = false});

  @override
  State<ChurchSacramentsRitesView> createState() =>
      _ChurchSacramentsRitesViewState();
}

class _ChurchSacramentsRitesViewState extends State<ChurchSacramentsRitesView> {
  List<Map<String, dynamic>> _rites = [];
  int _selectedRiteIdx = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRites();
  }

  Future<void> _loadRites() async {
    try {
      final raw = await rootBundle
          .loadString('assets/data/sacraments_rites_complete.json');
      final list = jsonDecode(raw) as List;
      _rites = list.map((e) => Map<String, dynamic>.from(e)).toList();
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
    final riteIcon = _resolveIcon('${rite['icon'] ?? ''}');
    final riteTitle = '${rite['title'] ?? ''}';
    final riteOccasion = '${rite['occasion'] ?? ''}';
    final riteOverview = '${rite['overview'] ?? ''}';

    return Column(
      children: [
        // 8-Rites Selector Ribbon
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _rites.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final r = _rites[idx];
              final sel = idx == safeIdx;
              return ChoiceChip(
                showCheckmark: false,
                avatar: Icon(
                  _resolveIcon('${r['icon'] ?? ''}'),
                  size: 15,
                  color: sel ? p.onAccent : p.accent,
                ),
                label: Text(
                  '${r['title']}',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: sel ? p.onAccent : p.ink,
                  ),
                ),
                selected: sel,
                selectedColor: p.accent,
                backgroundColor: p.surfaceElevated,
                side: BorderSide(color: sel ? p.accent : p.border),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  SpeechPronunciationService().stop();
                  setState(() => _selectedRiteIdx = idx);
                },
              );
            },
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
            children: [
              // Overview Header Card
              Container(
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
                                riteOccasion,
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
                    const SizedBox(height: 12),
                    SpeechPlayStopButton(
                      textToSpeak:
                          '$riteTitle. $riteOverview. ${sections.map((s) => "${s['title']}: ${s['arabic']}").join(". ")}',
                      label: riteTitle,
                      playText: 'استماع للطقس كاملاً',
                      stopText: 'إيقاف الصوت',
                      compact: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Complete Liturgical Sections
              for (final sec in sections) ...[
                Container(
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: '${sec['role']}' == 'الشعب'
                                  ? p.crimsonSoft
                                  : p.accentSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${sec['role']}',
                              style: GoogleFonts.cairo(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: '${sec['role']}' == 'الشعب'
                                    ? p.crimson
                                    : p.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${sec['title']}',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                              ),
                            ),
                          ),
                          SpeechPlayStopButton(
                            textToSpeak: '${sec['title']}. ${sec['arabic']}',
                            label: '${sec['title']}',
                            playText: 'استماع',
                            stopText: 'إيقاف',
                            compact: true,
                          ),
                        ],
                      ),
                      if ('${sec['coptic'] ?? ''}'.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: p.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: SelectableText(
                            '${sec['coptic']}',
                            textDirection: TextDirection.ltr,
                            style: GoogleFonts.cairo(
                              fontSize: 13 * fontScale,
                              fontWeight: FontWeight.w700,
                              color: p.accent,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      SelectableText(
                        '${sec['arabic']}',
                        style: GoogleFonts.amiri(
                          fontSize: 19 * fontScale,
                          height: 1.85,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
