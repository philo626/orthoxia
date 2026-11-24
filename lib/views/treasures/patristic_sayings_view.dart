import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/blessing_poster_studio_sheet.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../providers/theme_provider.dart';

/// Instant 100% Offline Patristic Sayings Encyclopedia («أقوال الآباء»):
/// Organized by 8 spiritual topics & 12 great Church Fathers — zero loading hangs!
class PatristicSayingsView extends StatefulWidget {
  const PatristicSayingsView({super.key});

  @override
  State<PatristicSayingsView> createState() => _PatristicSayingsViewState();
}

class _PatristicSayingsViewState extends State<PatristicSayingsView> {
  List<Map<String, dynamic>> _sayings = [];
  bool _loading = true;
  String _selectedTopic = 'الكل';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/patristic_sayings.json');
      _sayings = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fontScale = context.watch<ThemeProvider>().fontScale;

    final topics = <String>['الكل'];
    for (final s in _sayings) {
      final t = '${s['topic'] ?? ''}'.trim();
      if (t.isNotEmpty && !topics.contains(t)) topics.add(t);
    }

    final filtered = _sayings.where((s) {
      if (_selectedTopic != 'الكل' && '${s['topic']}' != _selectedTopic) {
        return false;
      }
      final q = _query.trim();
      if (q.isEmpty) return true;
      return '${s['text']}'.contains(q) ||
          '${s['father']}'.contains(q) ||
          '${s['topic']}'.contains(q);
    }).toList();

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
              'موسوعة أقوال الآباء',
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: p.ink,
                height: 1.15,
              ),
            ),
            Text(
              '${_sayings.length} قولاً روحياً موثقاً • يعمل بدون إنترنت',
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                        decoration: const InputDecoration(
                          hintText: 'ابحث باسم قديس أو موضوع (أنطونيوس، ذهبي الفم، البابا كيرلس، توبة...)',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: topics.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          final t = topics[i];
                          final sel = t == _selectedTopic;
                          return ChoiceChip(
                            showCheckmark: false,
                            selected: sel,
                            selectedColor: p.accent,
                            backgroundColor: p.surface,
                            side: BorderSide(color: sel ? p.accent : p.border),
                            label: Text(
                              t,
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: sel ? p.onAccent : p.ink,
                              ),
                            ),
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedTopic = t);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text('لا توجد أقوال مطابقة للبحث.',
                                  style: GoogleFonts.cairo(color: p.inkMuted)),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 2, 16, 36),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (_, idx) {
                                final s = filtered[idx];
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: p.surface,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: p.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          CopticCross(size: 13, color: p.accent),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${s['father']}',
                                              style: GoogleFonts.cairo(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: p.accent,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: p.goldSoft,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${s['topic']}',
                                              style: GoogleFonts.cairo(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: p.gold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(color: p.gold, width: 2.5),
                                          ),
                                        ),
                                        child: SelectableText(
                                          '«${s['text']}»',
                                          style: GoogleFonts.amiri(
                                            fontSize: 19.5 * fontScale,
                                            height: 1.75,
                                            color: p.ink,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            tooltip: 'نسخ القول',
                                            icon: Icon(Icons.copy_rounded,
                                                size: 18, color: p.inkMuted),
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(
                                                text: '«${s['text']}»\n— ${s['father']}',
                                              ));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('تم نسخ القول',
                                                      style: GoogleFonts.cairo()),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'مشاركة كبطاقة بركة',
                                            icon: Icon(Icons.ios_share_rounded,
                                                size: 18, color: p.accent),
                                            onPressed: () {
                                              BlessingPosterStudioSheet.show(
                                                context,
                                                title: '${s['topic']}',
                                                bodyText: '${s['text']}',
                                                reference: '${s['father']}',
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
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
