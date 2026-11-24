import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/luxe_widgets.dart';

class ServiceLessonNote {
  final String id;
  final String title;
  final String stage; // ابتدائي، إعدادي، ثانوي، شباب، اجتماع عام
  final bool isChecklist;
  final String content;
  final List<Map<String, dynamic>> checklistItems; // [{'text': ..., 'done': false}]
  final String verseRef;
  final bool starred;
  final DateTime updatedAt;

  ServiceLessonNote({
    required this.id,
    required this.title,
    required this.stage,
    required this.isChecklist,
    required this.content,
    required this.checklistItems,
    required this.verseRef,
    required this.starred,
    required this.updatedAt,
  });

  factory ServiceLessonNote.fromJson(Map<String, dynamic> j) => ServiceLessonNote(
        id: '${j['id'] ?? ''}',
        title: '${j['title'] ?? ''}',
        stage: '${j['stage'] ?? 'اجتماع عام'}',
        isChecklist: j['isChecklist'] == true,
        content: '${j['content'] ?? ''}',
        checklistItems: (j['checklistItems'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        verseRef: '${j['verseRef'] ?? ''}',
        starred: j['starred'] == true,
        updatedAt: DateTime.tryParse('${j['updatedAt'] ?? ''}') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'stage': stage,
        'isChecklist': isChecklist,
        'content': content,
        'checklistItems': checklistItems,
        'verseRef': verseRef,
        'starred': starred,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// Servant Preparation Notebook («كشكول الخدمة — تحضير الدروس والاجتماعات»):
/// Supports both Rich Text Lesson Prep (تحضير كتابي) and Interactive Points Checklist (تحضير نقاط),
/// stage tags, star favorites, search, and 1-tap Share.
class ServiceNotebookView extends StatefulWidget {
  const ServiceNotebookView({super.key});

  @override
  State<ServiceNotebookView> createState() => _ServiceNotebookViewState();
}

class _ServiceNotebookViewState extends State<ServiceNotebookView> {
  static const _prefsKey = 'kashkool_service_notes_v1';
  static const List<String> _stages = [
    'مدارس أحد (ابتدائي)',
    'إعدادي',
    'ثانوي',
    'شباب وجامعيين',
    'اجتماع عام',
  ];

  List<ServiceLessonNote> _notes = [];
  bool _loading = true;
  String _query = '';
  bool _onlyStarred = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        _notes = (jsonDecode(raw) as List)
            .map((e) => ServiceLessonNote.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_notes.map((n) => n.toJson()).toList()));
    } catch (_) {}
  }

  void _openEditor({ServiceLessonNote? existing, required bool isChecklist}) {
    final p = context.palette;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final verseCtrl = TextEditingController(text: existing?.verseRef ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    final newPointCtrl = TextEditingController();
    String stage = existing?.stage ?? _stages.first;
    final points = existing != null
        ? existing.checklistItems.map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.86,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: p.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        existing == null
                            ? (isChecklist ? 'تحضير نقاط جديد' : 'تحضير درس كتابي جديد')
                            : 'تعديل التحضير',
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final t = titleCtrl.text.trim();
                        if (t.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('من فضلك اكتب عنوان الدرس أولاً',
                                  style: GoogleFonts.cairo()),
                            ),
                          );
                          return;
                        }
                        final updated = ServiceLessonNote(
                          id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                          title: t,
                          stage: stage,
                          isChecklist: isChecklist,
                          content: contentCtrl.text.trim(),
                          checklistItems: points,
                          verseRef: verseCtrl.text.trim(),
                          starred: existing?.starred ?? false,
                          updatedAt: DateTime.now(),
                        );
                        setState(() {
                          _notes.removeWhere((n) => n.id == updated.id);
                          _notes.insert(0, updated);
                        });
                        await _persist();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text('حفظ', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      TextField(
                        controller: titleCtrl,
                        style: GoogleFonts.cairo(color: p.ink, fontSize: 14.5, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: 'عنوان الدرس أو الاجتماع',
                          prefixIcon: Icon(Icons.title_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: verseCtrl,
                        style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                        decoration: const InputDecoration(
                          hintText: 'آية الدرس أو الشاهد الكتابي (اختياري)',
                          prefixIcon: Icon(Icons.menu_book_outlined, size: 19),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _stages.map((st) {
                          final sel = st == stage;
                          return ChoiceChip(
                            showCheckmark: false,
                            selected: sel,
                            selectedColor: p.accent,
                            backgroundColor: p.surfaceSubtle,
                            label: Text(
                              st,
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: sel ? p.onAccent : p.ink,
                              ),
                            ),
                            onSelected: (_) => setSheet(() => stage = st),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      if (!isChecklist)
                        TextField(
                          controller: contentCtrl,
                          minLines: 8,
                          maxLines: 16,
                          style: GoogleFonts.cairo(color: p.ink, fontSize: 14, height: 1.65),
                          decoration: const InputDecoration(
                            hintText: 'اكتب عناصر الدرس، الهدف الروحي، التطبيق العملي، والأنشطة...',
                            alignLabelWithHint: true,
                          ),
                        )
                      else ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: newPointCtrl,
                                style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                                decoration: const InputDecoration(
                                  hintText: 'أضف نقطة للتحضير...',
                                ),
                                onSubmitted: (_) {
                                  if (newPointCtrl.text.trim().isNotEmpty) {
                                    setSheet(() {
                                      points.add({'text': newPointCtrl.text.trim(), 'done': false});
                                      newPointCtrl.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (newPointCtrl.text.trim().isNotEmpty) {
                                  setSheet(() {
                                    points.add({'text': newPointCtrl.text.trim(), 'done': false});
                                    newPointCtrl.clear();
                                  });
                                }
                              },
                              child: const Icon(Icons.add_rounded, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(points.length, (i) {
                          final pt = points[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: p.surfaceSubtle,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: p.border),
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: CheckboxListTile(
                                dense: true,
                                activeColor: p.accent,
                                value: pt['done'] == true,
                                onChanged: (v) => setSheet(() => pt['done'] = v ?? false),
                                title: Text(
                                  '${pt['text']}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: p.ink,
                                    decoration: pt['done'] == true
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                secondary: IconButton(
                                  icon: Icon(Icons.close_rounded, size: 17, color: p.inkMuted),
                                  onPressed: () => setSheet(() => points.removeAt(i)),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareNote(ServiceLessonNote n) {
    final buf = StringBuffer()
      ..writeln('تحضير خدمة: ${n.title}')
      ..writeln('المرحلة: ${n.stage}');
    if (n.verseRef.isNotEmpty) buf.writeln('الشاهد الكتابي: ${n.verseRef}');
    buf.writeln();
    if (n.isChecklist) {
      for (final pt in n.checklistItems) {
        buf.writeln('${pt['done'] == true ? '✓' : '•'} ${pt['text']}');
      }
    } else {
      buf.writeln(n.content);
    }
    SharePlus.instance.share(ShareParams(text: buf.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final filtered = _notes.where((n) {
      if (_onlyStarred && !n.starred) return false;
      final q = _query.trim();
      if (q.isEmpty) return true;
      return n.title.contains(q) || n.content.contains(q) || n.stage.contains(q) || n.verseRef.contains(q);
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
              'كشكول الخدمة والتحضير',
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: p.ink,
                height: 1.15,
              ),
            ),
            Text(
              'تحضير دروس مدارس الأحد والاجتماعات بسهولة',
              style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _onlyStarred ? 'عرض كل التحضيرات' : 'المميزة بنجمة فقط',
            icon: Icon(
              _onlyStarred ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _onlyStarred ? p.gold : p.inkMuted,
            ),
            onPressed: () => setState(() => _onlyStarred = !_onlyStarred),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        icon: const Icon(Icons.add_rounded),
        label: Text('تحضير جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: p.surface,
            builder: (ctx) => Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'اختر نوع التحضير',
                    style: GoogleFonts.amiri(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: Icon(Icons.article_outlined, color: p.accent),
                    title: Text('تحضير كتابي (مقال وعناصر الدرس)',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: p.ink)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openEditor(isChecklist: false);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.checklist_rounded, color: p.accent),
                    title: Text('تحضير نقاط (قائمة مهام ونقاط سريعة)',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: p.ink)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openEditor(isChecklist: true);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: p.accent, strokeWidth: 2))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                        decoration: const InputDecoration(
                          hintText: 'ابحث في تحضيراتك...',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.menu_book_outlined,
                                        size: 48, color: p.inkMuted.withValues(alpha: 0.45)),
                                    const SizedBox(height: 12),
                                    Text(
                                      'لا توجد تحضيرات بعد',
                                      style: GoogleFonts.amiri(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: p.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'اضغط «تحضير جديد» بالأسفل لكتابة درس مدارس الأحد أو نقاط اجتماعك وحفظها بسهولة.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(fontSize: 13, color: p.inkMuted),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (_, idx) {
                                final n = filtered[idx];
                                return PressScale(
                                  scale: 0.985,
                                  onTap: () => _openEditor(existing: n, isChecklist: n.isChecklist),
                                  child: Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: p.surface,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: p.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              n.isChecklist
                                                  ? Icons.checklist_rounded
                                                  : Icons.article_outlined,
                                              size: 18,
                                              color: p.accent,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                style: GoogleFonts.amiri(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.bold,
                                                  color: p.ink,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                n.starred
                                                    ? Icons.star_rounded
                                                    : Icons.star_outline_rounded,
                                                size: 20,
                                                color: n.starred ? p.gold : p.inkMuted,
                                              ),
                                              onPressed: () async {
                                                HapticFeedback.selectionClick();
                                                final toggled = ServiceLessonNote(
                                                  id: n.id,
                                                  title: n.title,
                                                  stage: n.stage,
                                                  isChecklist: n.isChecklist,
                                                  content: n.content,
                                                  checklistItems: n.checklistItems,
                                                  verseRef: n.verseRef,
                                                  starred: !n.starred,
                                                  updatedAt: n.updatedAt,
                                                );
                                                setState(() {
                                                  final pos = _notes.indexWhere((x) => x.id == n.id);
                                                  if (pos != -1) _notes[pos] = toggled;
                                                });
                                                await _persist();
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.share_outlined,
                                                  size: 18, color: p.inkSecondary),
                                              onPressed: () => _shareNote(n),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline_rounded,
                                                  size: 18, color: p.inkMuted),
                                              onPressed: () async {
                                                setState(() => _notes.removeWhere((x) => x.id == n.id));
                                                await _persist();
                                              },
                                            ),
                                          ],
                                        ),
                                        Wrap(
                                          spacing: 6,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: p.goldSoft,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                n.stage,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: p.accent,
                                                ),
                                              ),
                                            ),
                                            if (n.verseRef.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: p.surfaceSubtle,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  n.verseRef,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 10.5,
                                                    color: p.inkSecondary,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (n.isChecklist)
                                          Text(
                                            '${n.checklistItems.where((x) => x['done'] == true).length} / ${n.checklistItems.length} نقطة مكتملة',
                                            style: GoogleFonts.cairo(
                                                fontSize: 12, color: p.inkSecondary),
                                          )
                                        else if (n.content.isNotEmpty)
                                          Text(
                                            n.content,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.cairo(
                                                fontSize: 12.5, color: p.inkSecondary, height: 1.5),
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
