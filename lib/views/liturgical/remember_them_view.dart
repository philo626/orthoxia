import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/security_guard_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';

/// Personal Liturgical Diptych ("دفتر اذكرهم يا رب على مذبح صلاتي")
/// Saves names of family, sick, travelers, and departed encrypted locally via AES-256-GCM.
class RememberThemView extends StatefulWidget {
  const RememberThemView({super.key});

  @override
  State<RememberThemView> createState() => _RememberThemViewState();
}

class _RememberThemViewState extends State<RememberThemView> {
  final SpeechPronunciationService _speech = SpeechPronunciationService();
  final TextEditingController _nameCtrl = TextEditingController();
  int _activeCatIndex = 0;

  static const List<Map<String, dynamic>> _categories = [
    {
      'id': 'family',
      'title': 'الأسرة والأحباء',
      'iconData': Icons.people_outline_rounded,
      'subtitle': 'اذكر يا رب سلام وحفظ أسرتي وأحبائي',
    },
    {
      'id': 'sick',
      'title': 'المرضى والمتضايقون',
      'iconData': Icons.healing_outlined,
      'subtitle': 'أوشية المرضى • اشفهم يا رب وعزِّ قلوبهم',
    },
    {
      'id': 'travelers',
      'title': 'المسافرون والمغتربون',
      'iconData': Icons.flight_outlined,
      'subtitle': 'أوشية المسافرين • احفظهم وردهم سالمين',
    },
    {
      'id': 'departed',
      'title': 'الراقدون في الرب',
      'iconData': Icons.local_fire_department_outlined,
      'subtitle': 'أوشية الراقدين • نيح نفوسهم في فردوس النعيم',
    },
  ];

  final Map<String, List<String>> _namesByCat = {
    'family': [],
    'sick': [],
    'travelers': [],
    'departed': [],
  };

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  @override
  void dispose() {
    _speech.stop();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNames() async {
    final storage = StorageService();
    await storage.init();
    final raw = storage.getEncryptedDiptychJson();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          for (final k in _namesByCat.keys) {
            _namesByCat[k] = List<String>.from(decoded[k] ?? []);
          }
        });
      } catch (_) {}
    }
  }

  Future<void> _saveNames() async {
    final storage = StorageService();
    await storage.init();
    await storage.saveEncryptedDiptychJson(jsonEncode(_namesByCat));
  }

  void _addName() {
    final txt = SecurityGuardService.sanitizeText(
      _nameCtrl.text,
      maxLength: 50,
      allowNewlines: false,
    );
    if (txt.isEmpty) return;
    HapticFeedback.lightImpact();
    final catId = _categories[_activeCatIndex]['id'] as String;
    setState(() {
      if (!_namesByCat[catId]!.contains(txt)) {
        _namesByCat[catId]!.add(txt);
      }
      _nameCtrl.clear();
    });
    _saveNames();
  }

  void _removeName(String catId, String name) {
    HapticFeedback.selectionClick();
    setState(() {
      _namesByCat[catId]!.remove(name);
    });
    _saveNames();
  }

  String _buildPersonalizedPrayer() {
    final fam = _namesByCat['family']!;
    final sick = _namesByCat['sick']!;
    final trav = _namesByCat['travelers']!;
    final dep = _namesByCat['departed']!;

    final buf = StringBuffer();
    buf.writeln(
        'أيها السيد الرب يسوع المسيح إلهنا الصالح، نرفع إليك قلوبنا وصلواتنا من أجل أحبائنا:');
    if (fam.isNotEmpty) {
      buf.writeln(
          '• اذكر يا رب عبيدك وأحباءنا: (${fam.join("، ")})، بارك حياتهم واحفظهم في سلامك ومخافتك.');
    }
    if (sick.isNotEmpty) {
      buf.writeln(
          '• اذكر يا رب المرضى والمتضايقين: (${sick.join("، ")})، مد يدك الشافية إليهم وهبهم عافية وتعزية سماوية.');
    }
    if (trav.isNotEmpty) {
      buf.writeln(
          '• اذكر يا رب المسافرين والمغتربين: (${trav.join("، ")})، رافقهم بملائكتك الأطهار واحفظهم في كل طرقهم.');
    }
    if (dep.isNotEmpty) {
      buf.writeln(
          '• اذكر يا رب نفوس عبيدك المنتقلين على رجاء القيامة: (${dep.join("، ")})، نيح نفوسهم في فردوس النعيم في أحضان آبائنا إبراهيم وإسحق ويعقوب.');
    }
    if (fam.isEmpty && sick.isEmpty && trav.isEmpty && dep.isEmpty) {
      buf.writeln(
          '• اذكر يا رب أسرتنا وكنيستنا وكل المحتاجين إلى مراحمك السماوية، واشملنا جميعاً بنعمتك وسلامك. آمين.');
    } else {
      buf.writeln('بشفاعة والدة الإله القديسة الطاهرة مريم وجميع قديسيك. آمين.');
    }
    return buf.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final activeCat = _categories[_activeCatIndex];
    final activeCatId = activeCat['id'] as String;
    final activeList = _namesByCat[activeCatId] ?? [];
    final prayerText = _buildPersonalizedPrayer();

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'دفتر «اذكرهم يا رب» في صلاتي',
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.w700,
            fontSize: 21,
            color: p.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSel = idx == _activeCatIndex;
                final count = (_namesByCat[cat['id'] as String] ?? []).length;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeCatIndex = idx);
                  },
                  child: Container(
                    width: 145,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSel ? p.accentSoft : p.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSel ? p.accent : p.border,
                        width: isSel ? 1.4 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat['iconData'] as IconData,
                                color: p.accent, size: 19),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: p.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.cairo(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: p.onAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat['title'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSel ? p.accent : p.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
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
                    Icon(activeCat['iconData'] as IconData,
                        color: p.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${activeCat['subtitle']}',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        onSubmitted: (_) => _addName(),
                        style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText:
                              'اكتب الاسم لإضافته إلى ${activeCat['title']}...',
                          hintStyle: GoogleFonts.cairo(
                              color: p.inkSubtle, fontSize: 12),
                          filled: true,
                          fillColor: p.surfaceMuted,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _addName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.accent,
                        foregroundColor: p.onAccent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text('إضافة',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (activeList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'لم تضف أسماء في هذه الخانة بعد. أضف أسماء أحبائك ليُذكروا في صلاتك اليومية.',
                      textAlign: TextAlign.center,
                      style:
                          GoogleFonts.cairo(fontSize: 12, color: p.inkMuted),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: activeList.map((name) {
                      return Chip(
                        backgroundColor: p.accentSoft,
                        side: BorderSide(color: p.accent.withValues(alpha: 0.4)),
                        label: Text(
                          name,
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                          ),
                        ),
                        deleteIcon:
                            Icon(Icons.close_rounded, size: 16, color: p.inkMuted),
                        onDeleted: () => _removeName(activeCatId, name),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: p.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.accent.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CopticCross(size: 20, color: p.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'صلاتك وأوشيتك الخاصة بأسمائهم الآن',
                        style: GoogleFonts.cairo(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: p.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(
                  prayerText,
                  style: GoogleFonts.amiri(
                    fontSize: 19,
                    height: 1.8,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 14),
                ValueListenableBuilder<bool>(
                  valueListenable: _speech.isSpeakingNotifier,
                  builder: (context, speaking, _) {
                    return ElevatedButton.icon(
                      onPressed: () {
                        if (speaking) {
                          _speech.stop();
                        } else {
                          _speech.speakText(prayerText,
                              label: 'أوشية اذكرهم يا رب');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: speaking ? p.crimson : p.accent,
                        foregroundColor: speaking ? Colors.white : p.onAccent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(
                          speaking ? Icons.stop_rounded : Icons.volume_up_rounded),
                      label: Text(
                        speaking
                            ? 'إيقاف القراءة الصوتية'
                            : 'استمع للصلاة بأسمائهم صوتياً',
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
