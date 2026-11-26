import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/sacred_section_banner.dart';
import '../../models/agpeya_model.dart';
import '../../providers/theme_provider.dart';
import 'widgets/floating_church_bar.dart';

/// Interactive Book-Printed Coptic Agpeya Reader:
/// - Complete canonical Coptic Orthodox prayers (zero truncations)
/// - Katameros-style Dual Dropdown Bar (Hour switcher + Instant Section jump)
/// - Sacred Banner Header adapted to each liturgical hour
/// - Interactive 41x Kyrie Eleison Haptic Tap Counter
class AgpeyaReaderView extends StatefulWidget {
  final AgpeyaHour hour;
  final List<AgpeyaHour>? allHours;

  const AgpeyaReaderView({super.key, required this.hour, this.allHours});

  @override
  State<AgpeyaReaderView> createState() => _AgpeyaReaderViewState();
}

class _AgpeyaReaderViewState extends State<AgpeyaReaderView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _sectionKeys = {};
  late AgpeyaHour _currentHour;
  int _selectedSectionIdx = 0;
  int _kyrieCount = 0;

  @override
  void initState() {
    super.initState();
    _currentHour = widget.hour;
  }

  String _hourBannerAsset(String id) {
    switch (id) {
      case 'prime':
        return 'assets/images/christ_resurrection.jpg';
      case 'vespers':
      case 'compline':
      case 'veil':
      case 'midnight':
        return 'assets/images/banner_tasbeha.jpg';
      default:
        return 'assets/images/thumb_agpeya.jpg';
    }
  }

  @override
  void dispose() {
    SpeechPronunciationService().stop();
    _scrollController.dispose();
    super.dispose();
  }

  String _collectHourFullText() {
    final buf = StringBuffer('${_currentHour.nameAr}. ${_currentHour.theme}. ');
    for (final s in _currentHour.sections) {
      buf.write('${s.title}. ');
      if (s.content != null) buf.write('${s.content} ');
      if (s.psalms != null) {
        for (final p in s.psalms!) {
          buf.write('${p.title}. ${p.text} ');
        }
      }
    }
    return buf.toString();
  }

  void _jumpToSection(int idx) {
    setState(() => _selectedSectionIdx = idx);
    final key = _sectionKeys[idx];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        alignment: 0.04,
      );
    }
  }

  void _openSectionIndexSheet() {
    HapticFeedback.selectionClick();
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CopticCross(size: 18, color: p.isDark ? p.gold : p.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'فهرس ${_currentHour.nameAr}',
                    style: GoogleFonts.amiri(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: p.ink,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: p.inkMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: _currentHour.sections.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (_, idx) {
                  final sec = _currentHour.sections[idx];
                  final isKey = sec.type == 'gospel' ||
                      sec.type == 'kyrie41' ||
                      sec.type == 'absolution' ||
                      sec.type == 'watch_header' ||
                      sec.type == 'creed';
                  return Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isKey ? p.goldBorder : p.border),
                      ),
                      tileColor: isKey ? p.goldSoft : p.surfaceSubtle,
                      leading: Text(
                        '${idx + 1}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isKey ? p.accent : p.inkMuted,
                        ),
                      ),
                      title: Text(
                        sec.title,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: isKey ? FontWeight.bold : FontWeight.w500,
                          color: p.ink,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_left_rounded, size: 18, color: p.inkMuted),
                      onTap: () {
                        Navigator.pop(ctx);
                        _jumpToSection(idx);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKyrie41Counter(AppPalette p, double fontScale) {
    final progress = (_kyrieCount / 41.0).clamp(0.0, 1.0);
    final done = _kyrieCount >= 41;

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: done ? p.goldSoft : p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? p.accent : p.goldBorder,
          width: done ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            done ? 'تمّت ٤١ مرة — كيرياليسون يا رب ارحم' : 'اضغط مع كل ترديد: «يا رب ارحم»',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13 * fontScale.clamp(0.9, 1.25),
              fontWeight: FontWeight.bold,
              color: done ? p.accent : p.inkSecondary,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              if (_kyrieCount < 41) {
                HapticFeedback.lightImpact();
                setState(() => _kyrieCount++);
                if (_kyrieCount == 41) {
                  HapticFeedback.heavyImpact();
                }
              }
            },
            child: SizedBox(
              width: 118,
              height: 118,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 118,
                    height: 118,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: p.surfaceSubtle,
                      valueColor: AlwaysStoppedAnimation(p.accent),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_kyrieCount',
                        style: GoogleFonts.amiri(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'من ٤١',
                        style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _kyrieCount = 0);
                },
                icon: Icon(Icons.refresh_rounded, size: 16, color: p.inkMuted),
                label: Text(
                  'تصفير العداد',
                  style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final themeProv = Provider.of<ThemeProvider>(context);
    final fontScale = themeProv.fontScale;

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        title: Column(
          children: [
            Text(
              _currentHour.nameAr,
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.bold,
                fontSize: 21,
                color: p.ink,
              ),
            ),
            if (_currentHour.nameCoptic.isNotEmpty)
              Text(
                _currentHour.nameCoptic,
                style: TextStyle(
                  fontFamily: 'Coptic',
                  fontSize: 11.5,
                  color: p.gold,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'فهرس الساعية',
            icon: Icon(Icons.format_list_bulleted_rounded, color: p.accent),
            onPressed: _openSectionIndexSheet,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
            child: SpeechPlayStopButton(
              textToSpeak: _collectHourFullText(),
              label: _currentHour.nameAr,
              playText: 'استماع',
              stopText: 'إيقاف',
              compact: true,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  // Katameros-style Dual Quick-Jump Dropdown Bar (Hour Switcher + Section Jump)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Row(
                      children: [
                        if (widget.allHours != null && widget.allHours!.length > 1) ...[
                          Expanded(
                            flex: 4,
                            child: LiturgicalDropdownBox<String>(
                              label: 'الساعة',
                              dense: true,
                              value: _currentHour.id,
                              items: widget.allHours!.map((h) {
                                return DropdownMenuItem<String>(
                                  value: h.id,
                                  child: Text(
                                    h.nameAr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.8,
                                      fontWeight: FontWeight.bold,
                                      color: p.ink,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newId) {
                                if (newId == null) return;
                                final picked = widget.allHours!
                                    .where((h) => h.id == newId)
                                    .firstOrNull;
                                if (picked != null) {
                                  HapticFeedback.selectionClick();
                                  SpeechPronunciationService().stop();
                                  setState(() {
                                    _currentHour = picked;
                                    _sectionKeys.clear();
                                    _selectedSectionIdx = 0;
                                    _kyrieCount = 0;
                                  });
                                  if (_scrollController.hasClients) {
                                    _scrollController.jumpTo(0);
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (_currentHour.sections.isNotEmpty)
                          Expanded(
                            flex: 5,
                            child: LiturgicalDropdownBox<int>(
                              label: 'الانتقال السريع للجزء',
                              dense: true,
                              value: _selectedSectionIdx.clamp(
                                0,
                                _currentHour.sections.length - 1,
                              ),
                              items: List.generate(_currentHour.sections.length, (i) {
                                return DropdownMenuItem<int>(
                                  value: i,
                                  child: Text(
                                    _currentHour.sections[i].title,
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
                              onChanged: (idx) {
                                if (idx != null) {
                                  HapticFeedback.selectionClick();
                                  _jumpToSection(idx);
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sacred Illuminated Hour Banner (just like Katameros Agpeya!)
                          SacredSectionBanner(
                            imageAsset: _hourBannerAsset(_currentHour.id),
                            title: _currentHour.nameAr,
                            subtitle: _currentHour.theme,
                            badge: _currentHour.timeRange,
                            height: 118,
                            margin: const EdgeInsets.only(bottom: 18),
                          ),

                          // All Canonical Sections
                          for (int i = 0; i < _currentHour.sections.length; i++) ...[
                            Builder(
                              builder: (_) {
                                final section = _currentHour.sections[i];
                          final key = _sectionKeys.putIfAbsent(i, () => GlobalKey());
                          final isGospel = section.type == 'gospel';
                          final isWatch = section.type == 'watch_header';
                          final isKyrie = section.type == 'kyrie41';
                          final isRubricAccent =
                              isGospel || section.type == 'absolution' || section.type == 'creed';

                          return Container(
                            key: key,
                            margin: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (isWatch)
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: p.accent,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      section.title,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.amiri(
                                        fontSize: 20 * fontScale.clamp(0.9, 1.3),
                                        fontWeight: FontWeight.bold,
                                        color: p.onAccent,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: isRubricAccent ? p.crimson : p.gold,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      section.title,
                                      style: GoogleFonts.amiri(
                                        fontSize: 20 * fontScale.clamp(0.9, 1.35),
                                        fontWeight: FontWeight.bold,
                                        color: isRubricAccent ? p.crimson : p.accent,
                                      ),
                                    ),
                                  ),

                                if (isKyrie)
                                  _buildKyrie41Counter(p, fontScale),

                                if (section.content != null && section.content!.isNotEmpty)
                                  Container(
                                    padding: isGospel
                                        ? const EdgeInsets.all(16)
                                        : EdgeInsets.zero,
                                    decoration: isGospel
                                        ? BoxDecoration(
                                            color: p.surface,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: p.goldBorder),
                                          )
                                        : null,
                                    child: SelectableText(
                                      section.content!,
                                      style: GoogleFonts.amiri(
                                        fontSize: 19 * fontScale,
                                        color: p.ink,
                                        height: 1.9,
                                      ),
                                    ),
                                  ),

                                if (section.psalms != null)
                                  for (final psalm in section.psalms!) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                                      child: Text(
                                        psalm.title,
                                        style: GoogleFonts.amiri(
                                          fontSize: 18 * fontScale,
                                          fontWeight: FontWeight.bold,
                                          color: p.accent,
                                        ),
                                      ),
                                    ),
                                    SelectableText(
                                      psalm.text,
                                      style: GoogleFonts.amiri(
                                        fontSize: 18.5 * fontScale,
                                        color: p.ink,
                                        height: 1.85,
                                      ),
                                    ),
                                  ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'المجد للثالوث الأقدس دائماً وأبداً. آمين.',
                        style: GoogleFonts.amiri(
                          fontSize: 17 * fontScale.clamp(0.9, 1.3),
                          fontWeight: FontWeight.bold,
                          color: p.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
                  ],
                ),
              ),
            ),

          const FloatingChurchBar(),
        ],
      ),
    );
  }
}
