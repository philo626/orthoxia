import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/security_guard_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/coptic_cross.dart';

/// Personal Liturgical Diptych ("دفتر اذكرهم يا رب على مذبح صلاتي")
/// Saves names of family, sick, travelers, and departed encrypted locally via AES-256-GCM
/// and generates a live personalized Orthodox intercession prayer with audio reading.
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

  Map<String, List<String>> _namesByCat = {
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
    final catId = _categories[_activeCatIndex]['id']!;
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
    buf.writeln('أيها السيد الرب يسوع المسيح إلهنا الصالح، نرفع إليك قلوبنا وصلواتنا من أجل أحبائنا:');
    if (fam.isNotEmpty) {
      buf.writeln('• اذكر يا رب عبيدك وأحباءنا: (${fam.join("، ")})، بارك حياتهم واحفظهم في سلامك ومخافتك.');
    }
    if (sick.isNotEmpty) {
      buf.writeln('• اذكر يا رب المرضى والمتضايقين: (${sick.join("، ")})، مد يدك الشافية إليهم وهبهم عافية وتعزية سماوية.');
    }
    if (trav.isNotEmpty) {
      buf.writeln('• اذكر يا رب المسافرين والمغتربين: (${trav.join("، ")})، رافقهم بملائكتك الأطهار واحفظهم في كل طرقهم.');
    }
    if (dep.isNotEmpty) {
      buf.writeln('• اذكر يا رب نفوس عبيدك المنتقلين على رجاء القيامة: (${dep.join("، ")})، نيح نفوسهم في فردوس النعيم في أحضان آبائنا إبراهيم وإسحق ويعقوب.');
    }
    if (fam.isEmpty && sick.isEmpty && trav.isEmpty && dep.isEmpty) {
      buf.writeln('• اذكر يا رب أسرتنا وكنيستنا وكل المحتاجين إلى مراحمك السماوية، واشملنا جميعاً بنعمتك وسلامك. آمين.');
    } else {
      buf.writeln('بشفاعة والدة الإله القديسة الطاهرة مريم وجميع قديسيك. آمين.');
    }
    return buf.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final activeCat = _categories[_activeCatIndex];
    final activeCatId = activeCat['id']!;
    final activeList = _namesByCat[activeCatId] ?? [];
    final prayerText = _buildPersonalizedPrayer();

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        centerTitle: true,
        title: Text(
          'دفتر «اذكرهم يا رب» في صلاتي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          // 1. Category Selector Tabs
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSel = idx == _activeCatIndex;
                final count = (_namesByCat[cat['id']!] ?? []).length;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeCatIndex = idx);
                  },
                  child: Container(
                    width: 145,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.primaryGold.withValues(alpha: 0.18)
                          : AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSel ? AppColors.primaryGold : Colors.white12,
                        width: isSel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat['iconData'] as IconData, color: AppColors.primaryGold, size: 19),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.cairo(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat['title']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? AppColors.primaryGoldLight : Colors.white,
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

          // 2. Add Name Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardNavy,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(activeCat['iconData'] as IconData, color: AppColors.primaryGold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${activeCat['subtitle']}',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGoldLight,
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
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'اكتب الاسم لإضافته إلى ${activeCat['title']}...',
                          hintStyle: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF14161F),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text('إضافة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: activeList.map((name) {
                      return Chip(
                        backgroundColor: const Color(0xFF231D14),
                        side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.45)),
                        label: Text(
                          name,
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                        onDeleted: () => _removeName(activeCatId, name),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 3. Generated Personalized Liturgical Prayer Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2B2012), Color(0xFF14151C)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primaryGold, width: 1.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CopticCross(size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'صلاتك وأوشيتك الخاصة بأسمائهم الآن',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGoldLight,
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
                    color: Colors.white,
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
                          _speech.speakText(prayerText, label: 'أوشية اذكرهم يا رب');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: speaking ? AppColors.sacredBurgundy : AppColors.primaryGold,
                        foregroundColor: speaking ? Colors.white : Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(speaking ? Icons.stop_rounded : Icons.volume_up_rounded),
                      label: Text(
                        speaking ? 'إيقاف القراءة الصوتية' : 'استمع للصلاة بأسمائهم صوتياً',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
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
