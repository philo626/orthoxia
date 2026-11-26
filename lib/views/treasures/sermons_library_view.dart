import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/sacred_section_banner.dart';
import '../../models/hymn_model.dart';
import '../../providers/audio_provider.dart';
import '../hymns/widgets/full_audio_player_sheet.dart';

class SermonAudioItem {
  final String id;
  final String title;
  final String speaker;
  final String category;
  final String duration;
  final String audioUrl;

  const SermonAudioItem({
    required this.id,
    required this.title,
    required this.speaker,
    required this.category,
    required this.duration,
    required this.audioUrl,
  });

  factory SermonAudioItem.fromJson(Map<String, dynamic> j) => SermonAudioItem(
        id: '${j['id'] ?? ''}',
        title: '${j['title'] ?? ''}',
        speaker: '${j['speaker'] ?? ''}',
        category: '${j['category'] ?? 'حياة روحية'}',
        duration: '${j['duration'] ?? ''}',
        audioUrl: '${j['audio_url'] ?? ''}',
      );

  /// Wraps this sermon into a playable AudioProvider track so it automatically gets
  /// background playback, Lock Screen, Notification Shade & Xiaomi Dynamic Island controls!
  Hymn toPlayableTrack() => Hymn(
        id: id,
        title: title,
        categoryId: 'sermons',
        categoryName: category,
        cantor: speaker,
        audioUrl: audioUrl,
        versesCount: 0,
        verses: const [],
      );
}

/// Feature #4: Coptic Fathers Audio Sermons Library («مكتبة العظات الصوتية»)
/// Plays seamlessly in background + Lock Screen + Dynamic Island via native HymnMediaService!
class SermonsLibraryView extends StatefulWidget {
  const SermonsLibraryView({super.key});

  @override
  State<SermonsLibraryView> createState() => _SermonsLibraryViewState();
}

class _SermonsLibraryViewState extends State<SermonsLibraryView> {
  List<SermonAudioItem> _allSermons = [];
  List<String> _speakers = ['الكل'];
  String _selectedSpeaker = 'الكل';
  String _selectedCategory = 'الكل';
  String _query = '';
  bool _loading = true;

  static const List<String> _categories = [
    'الكل',
    'حياة روحية',
    'تفسير الكتاب والصلاة',
    'التوبة والاعتراف',
    'الأصوام والأعياد والقداس',
    'الشباب والأسرة',
    'التعزية والسلام',
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final raw = await rootBundle.loadString('assets/data/sermons_library.json');
      final list = (jsonDecode(raw) as List)
          .map((e) => SermonAudioItem.fromJson(e as Map<String, dynamic>))
          .where((s) => s.audioUrl.startsWith('https://'))
          .toList();
      final spSet = <String>{};
      for (final s in list) {
        if (s.speaker.isNotEmpty) spSet.add(s.speaker);
      }
      if (mounted) {
        setState(() {
          _allSermons = list;
          _speakers = ['الكل', ...spSet];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<SermonAudioItem> get _filtered {
    final q = _query.trim();
    return _allSermons.where((s) {
      if (_selectedSpeaker != 'الكل' && s.speaker != _selectedSpeaker) return false;
      if (_selectedCategory != 'الكل' && s.category != _selectedCategory) return false;
      if (q.isNotEmpty && !s.title.contains(q) && !s.speaker.contains(q)) return false;
      return true;
    }).toList();
  }

  Future<void> _playSermon(SermonAudioItem item, List<SermonAudioItem> currentList) async {
    HapticFeedback.lightImpact();
    final audio = context.read<AudioProvider>();
    final tracks = currentList.map((e) => e.toPlayableTrack()).toList();
    await audio.play(item.toPlayableTrack(), playlist: tracks);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final audio = context.watch<AudioProvider>();
    final list = _filtered;

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
              'مكتبة العظات الصوتية',
              style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 23, color: p.ink, height: 1.15),
            ),
            Text(
              'بتشتغل في الخلفية وفي الإشعارات والـ Dynamic Island',
              style: GoogleFonts.cairo(fontSize: 10.5, color: p.inkMuted),
            ),
          ],
        ),
        actions: [
          if (audio.currentHymn != null)
            IconButton(
              tooltip: 'فتح المشغل الكامل',
              icon: Icon(Icons.graphic_eq_rounded, color: p.gold),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => FullAudioPlayerSheet(hymn: audio.currentHymn!),
                );
              },
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: p.gold, strokeWidth: 2))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: Column(
                  children: [
                    SacredSectionBanner(
                      imageAsset: 'assets/images/banner_sermons.jpg',
                      title: 'مكتبة العظات الصوتية',
                      subtitle: '${_allSermons.length} عظة صوتية لآباء الكنيسة — تعمل بالخلفية وشاشة القفل',
                      badge: 'صوتيات الكنيسة',
                      height: 102,
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    ),
                    // 1. Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'ابحث في العظات أو باسم الأب...',
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.inkMuted),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),

                    // 2. Speaker Filter Pills
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _speakers.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 7),
                        itemBuilder: (_, i) {
                          final sp = _speakers[i];
                          final sel = _selectedSpeaker == sp;
                          return ChoiceChip(
                            selected: sel,
                            selectedColor: p.gold,
                            backgroundColor: p.surface,
                            side: BorderSide(color: sel ? p.gold : p.border),
                            label: Text(
                              sp,
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: sel ? const Color(0xFF19130A) : p.ink,
                              ),
                            ),
                            onSelected: (_) => setState(() => _selectedSpeaker = sp),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 3. Topic Category Pills
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          final cat = _categories[i];
                          final sel = _selectedCategory == cat;
                          return ChoiceChip(
                            visualDensity: VisualDensity.compact,
                            selected: sel,
                            selectedColor: p.accent,
                            backgroundColor: p.surfaceSubtle,
                            label: Text(
                              cat,
                              style: GoogleFonts.cairo(
                                fontSize: 10.8,
                                fontWeight: FontWeight.bold,
                                color: sel ? p.onAccent : p.inkSecondary,
                              ),
                            ),
                            onSelected: (_) => setState(() => _selectedCategory = cat),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 4. Sermons List
                    Expanded(
                      child: list.isEmpty
                          ? Center(
                              child: Text(
                                'مفيش عظات مطابقة للبحث ده دلوقتي.',
                                style: GoogleFonts.cairo(color: p.inkMuted),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                              itemCount: list.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (_, idx) {
                                final s = list[idx];
                                final isCurrent = audio.currentHymn?.id == s.id;
                                final isPlayingThis = isCurrent && audio.isPlaying;

                                return InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    if (isCurrent) {
                                      if (audio.isPlaying) {
                                        audio.pause();
                                      } else {
                                        audio.resume();
                                      }
                                    } else {
                                      _playSermon(s, list);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      color: isCurrent ? p.goldSoft : p.surface,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isCurrent ? p.gold : p.border,
                                        width: isCurrent ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isCurrent ? p.gold : p.goldSoft,
                                            border: Border.all(color: p.goldBorder),
                                          ),
                                          child: isCurrent && audio.isLoading
                                              ? const Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Color(0xFF19130A),
                                                  ),
                                                )
                                              : Icon(
                                                  isPlayingThis
                                                      ? Icons.pause_rounded
                                                      : Icons.play_arrow_rounded,
                                                  size: 24,
                                                  color: isCurrent
                                                      ? const Color(0xFF19130A)
                                                      : p.gold,
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                s.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: p.ink,
                                                  height: 1.35,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  CopticCross(size: 11, color: p.gold),
                                                  const SizedBox(width: 5),
                                                  Expanded(
                                                    child: Text(
                                                      s.speaker,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.cairo(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: p.accent,
                                                      ),
                                                    ),
                                                  ),
                                                  if (s.duration.isNotEmpty)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 7, vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: p.surfaceSubtle,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        s.duration,
                                                        style: GoogleFonts.cairo(
                                                          fontSize: 10.5,
                                                          color: p.inkMuted,
                                                        ),
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
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
