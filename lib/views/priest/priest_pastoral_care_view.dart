import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/confession_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../models/confession_models.dart';

/// Priest Pastoral Care Sanctuary («الرعاية والافتقاد والمذبح» — Tab 3 of PriestNavigationShell):
/// 100% LOCAL & AES-256 ENCRYPTED ON ABOUNA'S DEVICE (ZERO cloud upload for absolute confidentiality!):
///   0: أسماء على المذبح (Altar Litany Commemoration: المرضى • الراقدين/الترحيم • المسافرين • ضيقات • شكر)
///   1: دفتر الافتقاد (Visitation Tracker with Area, Private Notes, 1-Tap Phone Call, Visited Check)
///   2: تحضير العظات (Sermon Preparation Notebook with Scripture Ref, Points, Patristic Quotes)
class PriestPastoralCareView extends StatefulWidget {
  final ValueNotifier<int>? externalTabNotifier;
  const PriestPastoralCareView({super.key, this.externalTabNotifier});

  @override
  State<PriestPastoralCareView> createState() => _PriestPastoralCareViewState();
}

class _PriestPastoralCareViewState extends State<PriestPastoralCareView>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final ConfessionService _confession = ConfessionService();
  late final TabController _tabCtrl;

  List<AltarNameItem> _altarNames = [];
  List<VisitationEntry> _visitations = [];
  List<SermonNote> _sermons = [];

  String _altarCategoryFilter = 'all';
  bool _altarLargeReadingMode = false;
  String _visitFilter = 'pending'; // 'pending' | 'mine' | 'visited' | 'all'

  static const _altarCategories = <({String key, String label, IconData icon})>[
    (key: 'all', label: 'الكل', icon: Icons.list_alt_rounded),
    (key: 'sick', label: 'المرضى', icon: Icons.healing_outlined),
    (key: 'departed', label: 'الراقدين (الترحيم)', icon: Icons.local_florist_outlined),
    (key: 'travelers', label: 'المسافرين', icon: Icons.flight_takeoff_rounded),
    (key: 'distressed', label: 'ضيقات وطلبات', icon: Icons.favorite_outline_rounded),
    (key: 'thanksgiving', label: 'شكر وأفراح', icon: Icons.auto_awesome_outlined),
  ];

  static const _visitTags = ['مريض', 'أسرة', 'مسن', 'شاب', 'ضيقة'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    widget.externalTabNotifier?.addListener(_syncExternal);
    _loadAllEncryptedStores();
  }

  void _syncExternal() {
    final idx = widget.externalTabNotifier?.value ?? 0;
    if (idx >= 0 && idx < 3 && _tabCtrl.index != idx) {
      _tabCtrl.animateTo(idx);
    }
  }

  @override
  void dispose() {
    widget.externalTabNotifier?.removeListener(_syncExternal);
    _tabCtrl.dispose();
    super.dispose();
  }

  void _loadAllEncryptedStores() {
    try {
      final rawAltar = _storage.getEncryptedAltarNamesJson();
      if (rawAltar != null && rawAltar.isNotEmpty) {
        final list = jsonDecode(rawAltar) as List;
        _altarNames = list.map((e) => AltarNameItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    try {
      final rawVisits = _storage.getEncryptedVisitationJson();
      if (rawVisits != null && rawVisits.isNotEmpty) {
        final list = jsonDecode(rawVisits) as List;
        _visitations = list.map((e) => VisitationEntry.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    try {
      final rawSermons = _storage.getEncryptedSermonsJson();
      if (rawSermons != null && rawSermons.isNotEmpty) {
        final list = jsonDecode(rawSermons) as List;
        _sermons = list.map((e) => SermonNote.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    if (mounted) setState(() {});
  }

  Future<void> _saveAltarNames() async {
    await _storage.saveEncryptedAltarNamesJson(
      jsonEncode(_altarNames.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveVisitations() async {
    await _storage.saveEncryptedVisitationJson(
      jsonEncode(_visitations.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveSermons() async {
    await _storage.saveEncryptedSermonsJson(
      jsonEncode(_sermons.map((e) => e.toJson()).toList()),
    );
  }

  String _categoryLabel(String key) {
    for (final c in _altarCategories) {
      if (c.key == key) return c.label;
    }
    return 'طلبة';
  }

  // ===========================================================================
  // ADD / EDIT DIALOGS
  // ===========================================================================

  void _openAddAltarNameSheet() {
    final p = context.palette;
    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String category = _altarCategoryFilter == 'all' ? 'sick' : _altarCategoryFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: p.border)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'إضافة اسم للذكر على المذبح',
                    style: GoogleFonts.amiri(fontSize: 23, fontWeight: FontWeight.bold, color: p.ink),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _altarCategories.where((c) => c.key != 'all').map((c) {
                      final sel = category == c.key;
                      return ChoiceChip(
                        selected: sel,
                        selectedColor: p.gold,
                        backgroundColor: p.surfaceSubtle,
                        label: Text(
                          c.label,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sel ? const Color(0xFF19130A) : p.ink,
                          ),
                        ),
                        onSelected: (_) => setSheet(() => category = c.key),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 14.5),
                    decoration: const InputDecoration(
                      hintText: 'الاسم (مثال: الابن مينا، أو المنتقل جرجس...)',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                    decoration: const InputDecoration(
                      hintText: 'ملاحظة قصيرة (اختياري — مثال: عملية جراحية / ذكرى الأربعين)',
                      prefixIcon: Icon(Icons.notes_rounded, size: 19),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final n = nameCtrl.text.trim();
                      if (n.isEmpty) return;
                      HapticFeedback.lightImpact();
                      final item = AltarNameItem(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: n,
                        category: category,
                        note: noteCtrl.text.trim(),
                        createdAtIso: DateTime.now().toIso8601String(),
                      );
                      setState(() => _altarNames.insert(0, item));
                      await _saveAltarNames();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: Text(
                      'حفظ في قائمة المذبح',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAddVisitationSheet({VisitationEntry? existing}) {
    final p = context.palette;
    final nameCtrl = TextEditingController(text: existing?.personName ?? '');
    final areaCtrl = TextEditingController(text: existing?.area ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    String tag = existing?.tag ?? 'أسرة';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: p.border)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    existing == null ? 'إضافة أسرة / مخدوم للافتقاد' : 'تعديل بيانات الافتقاد',
                    style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: p.ink),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _visitTags.map((t) {
                      final sel = tag == t;
                      return ChoiceChip(
                        selected: sel,
                        selectedColor: p.gold,
                        backgroundColor: p.surfaceSubtle,
                        label: Text(
                          t,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sel ? const Color(0xFF19130A) : p.ink,
                          ),
                        ),
                        onSelected: (_) => setSheet(() => tag = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'اسم الأسرة أو المخدوم',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: areaCtrl,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'المنطقة أو العنوان (اختياري)',
                      prefixIcon: Icon(Icons.place_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'رقم الهاتف للاتصال السريع (اختياري)',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                    decoration: const InputDecoration(
                      hintText: 'ملاحظة رعوية خاصة (محفوظة محلياً ومشفرة على جهاز قدسك فقط)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final n = nameCtrl.text.trim();
                      if (n.isEmpty) return;
                      HapticFeedback.lightImpact();
                      final entry = VisitationEntry(
                        id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                        personName: n,
                        area: areaCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        tag: tag,
                        note: noteCtrl.text.trim(),
                        visited: existing?.visited ?? false,
                        updatedAtIso: DateTime.now().toIso8601String(),
                      );
                      setState(() {
                        if (existing != null) {
                          final idx = _visitations.indexWhere((e) => e.id == existing.id);
                          if (idx != -1) _visitations[idx] = entry;
                        } else {
                          _visitations.insert(0, entry);
                        }
                      });
                      await _saveVisitations();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save_outlined, size: 19),
                    label: Text(
                      'حفظ في دفتر الافتقاد',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openSermonEditorSheet({SermonNote? existing}) {
    final p = context.palette;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final occCtrl = TextEditingController(text: existing?.occasion ?? '');
    final refCtrl = TextEditingController(text: existing?.scriptureRef ?? '');
    final pointsCtrl = TextEditingController(text: existing?.points ?? '');
    final quoteCtrl = TextEditingController(text: existing?.patristicQuote ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: p.border)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  existing == null ? 'تحضير عظة جديدة' : 'تعديل العظة',
                  style: GoogleFonts.amiri(fontSize: 23, fontWeight: FontWeight.bold, color: p.ink),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  style: GoogleFonts.cairo(color: p.ink, fontSize: 14.5),
                  decoration: const InputDecoration(
                    hintText: 'عنوان العظة (مثال: حياة الشكر في التجارب)',
                    prefixIcon: Icon(Icons.title_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: occCtrl,
                        style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                        decoration: const InputDecoration(hintText: 'المناسبة / الأحد'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: refCtrl,
                        style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                        decoration: const InputDecoration(hintText: 'الشاهد الكتابي'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pointsCtrl,
                  maxLines: 5,
                  style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5, height: 1.55),
                  decoration: const InputDecoration(
                    hintText: 'النقاط الرئيسية للعظة والتأملات...',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quoteCtrl,
                  maxLines: 2,
                  style: GoogleFonts.cairo(color: p.ink, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'قول آبائي داعم (اختياري)',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final t = titleCtrl.text.trim();
                    if (t.isEmpty) return;
                    HapticFeedback.lightImpact();
                    final sermon = SermonNote(
                      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                      title: t,
                      occasion: occCtrl.text.trim(),
                      scriptureRef: refCtrl.text.trim(),
                      points: pointsCtrl.text.trim(),
                      patristicQuote: quoteCtrl.text.trim(),
                      updatedAtIso: DateTime.now().toIso8601String(),
                    );
                    setState(() {
                      if (existing != null) {
                        final idx = _sermons.indexWhere((s) => s.id == existing.id);
                        if (idx != -1) _sermons[idx] = sermon;
                      } else {
                        _sermons.insert(0, sermon);
                      }
                    });
                    await _saveSermons();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.save_outlined, size: 19),
                  label: Text('حفظ العظة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // UI BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

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
              'الرعاية والافتقاد والمذبح',
              style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 22, color: p.ink, height: 1.15),
            ),
            Text(
              'محفوظ ومشفر على جهاز قدسك فقط بخصوصية تامة',
              style: GoogleFonts.cairo(fontSize: 10.5, color: p.inkMuted),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: p.gold,
          labelColor: p.ink,
          unselectedLabelColor: p.inkMuted,
          labelStyle: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
          tabs: const [
            Tab(text: 'على المذبح'),
            Tab(text: 'دفتر الافتقاد'),
            Tab(text: 'تحضير العظات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildAltarNamesTab(p),
          _buildVisitationTab(p),
          _buildSermonsTab(p),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (_, _) {
          final idx = _tabCtrl.index;
          final label = idx == 0 ? 'إضافة اسم' : (idx == 1 ? 'إضافة افتقاد' : 'عظة جديدة');
          return FloatingActionButton.extended(
            backgroundColor: p.gold,
            foregroundColor: const Color(0xFF19130A),
            icon: const Icon(Icons.add_rounded),
            label: Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () {
              if (idx == 0) {
                _openAddAltarNameSheet();
              } else if (idx == 1) {
                _openAddVisitationSheet();
              } else {
                _openSermonEditorSheet();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildAltarNamesTab(AppPalette p) {
    final filtered = _altarCategoryFilter == 'all'
        ? _altarNames
        : _altarNames.where((e) => e.category == _altarCategoryFilter).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            // Altar Reading Mode Toggle + Category Filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'أسماء الأواشي والترحيم (${filtered.length})',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                  ),
                  FilterChip(
                    selected: _altarLargeReadingMode,
                    selectedColor: p.goldSoft,
                    checkmarkColor: p.gold,
                    side: BorderSide(color: p.goldBorder),
                    label: Text(
                      'خط كبير للقراءة على المذبح',
                      style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold, color: p.ink),
                    ),
                    onSelected: (v) => setState(() => _altarLargeReadingMode = v),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _altarCategories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _altarCategories[i];
                  final sel = _altarCategoryFilter == cat.key;
                  return ChoiceChip(
                    selected: sel,
                    selectedColor: p.gold,
                    backgroundColor: p.surface,
                    label: Text(
                      cat.label,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: sel ? const Color(0xFF19130A) : p.inkSecondary,
                      ),
                    ),
                    onSelected: (_) => setState(() => _altarCategoryFilter = cat.key),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Incoming Altar Prayer Requests sent privately by Abouna's congregation children!
            StreamBuilder<List<AltarPrayerRequest>>(
              stream: _confession.watchIncomingAltarRequests(),
              builder: (context, snap) {
                final incoming = snap.data ?? [];
                if (incoming.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.goldSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.goldBorder, width: 1.3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mark_email_unread_rounded, size: 18, color: p.gold),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'طلبات صلاة جديدة للمذبح من أولاد قدسك (${incoming.length})',
                              style: GoogleFonts.cairo(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: p.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...incoming.take(5).map((req) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: p.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: p.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${req.personName} (${_categoryLabel(req.category)})',
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: p.ink,
                                        ),
                                      ),
                                      Text(
                                        'بعتها: ${req.senderName}${req.note.isNotEmpty ? ' • ${req.note}' : ''}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(fontSize: 11, color: p.inkSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                FilledButton.tonal(
                                  onPressed: () async {
                                    HapticFeedback.lightImpact();
                                    final messenger = ScaffoldMessenger.of(context);
                                    final item = AltarNameItem(
                                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                                      name: req.personName,
                                      category: req.category,
                                      note: req.note.isNotEmpty
                                          ? '${req.note} (مرسل من ${req.senderName})'
                                          : 'مرسل من ${req.senderName}',
                                      createdAtIso: DateTime.now().toIso8601String(),
                                    );
                                    setState(() => _altarNames.insert(0, item));
                                    await _saveAltarNames();
                                    await _confession.dismissOrAcceptAltarRequest(req.id, delete: true);
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'اتضاف «${req.personName}» لقايمة المذبح الخاصة بقدسك ✓',
                                            style: GoogleFonts.cairo(),
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: p.sage.withValues(alpha: 0.16),
                                    foregroundColor: p.sage,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'إضافة ✓',
                                    style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'تجاهل',
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(5),
                                  icon: Icon(Icons.close_rounded, size: 17, color: p.inkMuted),
                                  onPressed: () =>
                                      _confession.dismissOrAcceptAltarRequest(req.id, delete: true),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _emptyBox(
                      p,
                      Icons.favorite_outline_rounded,
                      'قائمة الذكر على المذبح فارغة حالياً',
                      'أضف أسماء المرضى أو المنتقلين للترحيم أو المسافرين لتقرأها قدسك بسهولة أثناء الأواشي على المذبح.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, idx) {
                        final item = filtered[idx];
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: _altarLargeReadingMode ? 16 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: p.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: p.goldSoft,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _categoryLabel(item.category),
                                            style: GoogleFonts.cairo(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: p.gold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.name,
                                      style: GoogleFonts.amiri(
                                        fontSize: _altarLargeReadingMode ? 26 : 20,
                                        fontWeight: FontWeight.bold,
                                        color: p.ink,
                                        height: 1.25,
                                      ),
                                    ),
                                    if (item.note.isNotEmpty)
                                      Text(
                                        item.note,
                                        style: GoogleFonts.cairo(
                                          fontSize: _altarLargeReadingMode ? 14 : 12,
                                          color: p.inkSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'حذف من القائمة',
                                icon: Icon(Icons.delete_outline_rounded, size: 20, color: p.inkMuted),
                                onPressed: () async {
                                  setState(() => _altarNames.removeWhere((x) => x.id == item.id));
                                  await _saveAltarNames();
                                },
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
    );
  }

  void _openPastoralMessageSheet(VisitationEntry v) {
    final p = context.palette;
    final priestName = _storage.getUserName().trim();
    final priestTitle = _storage.getPriestTitlePrefix().trim();
    final sig = priestName.isNotEmpty
        ? '\n— $priestTitle $priestName'
        : '\n— قدس أبونا';

    final templates = <({String title, String icon, String body})>[
      (
        title: 'اطمئنان على مريض',
        icon: '🙏',
        body:
            'سلام ونعمة يا ${v.personName}، ألف سلامة عليك! بنصليلك على المذبح وربنا يمد إيده بالشفاء والعافية ويقومك بالسلامة قريب إن شاء الله.$sig',
      ),
      (
        title: 'تهنئة بعيد أو مناسبة حلوة',
        icon: '✨',
        body:
            'كل سنة وأنتم طيبين وبخير دايماً يا ${v.personName}! ربنا يملا بيتكم فرح وسلام وبركة، ويجعل أيامكم كلها أعياد.$sig',
      ),
      (
        title: 'افتقاد وسؤال على الأسرة',
        icon: '🏡',
        body:
            'سلام ونعمة يا ${v.personName}، وحشتونا جداً في الكنيسة وحبيت أطمن عليكم وأسأل عن أخباركم، وإن شاء الله قريب أعدّي أفتقدكم وآخد بركتكم.$sig',
      ),
      (
        title: 'تعزية ومواساة',
        icon: '✝️',
        body:
            'المسيح يعزيكم ويقويكم يا ${v.personName}. الرب ينيح نفس المنتقل في فردوس النعيم ويملا قلوبكم بالسلام والعزاء السماوي.$sig',
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'ابعت رسالة اطمئنان أو تهنئة لـ ${v.personName}',
              style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.bold, color: p.ink),
            ),
            const SizedBox(height: 4),
            Text(
              'اختار رسالة جاهزة وهتتبعت علطول على واتساب أو أي تطبيق تواصل:',
              style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted),
            ),
            const SizedBox(height: 12),
            ...templates.map(
              (tpl) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    Navigator.pop(ctx);
                    final cleanPhone = v.phone.replaceAll(RegExp(r'[^0-9+]'), '');
                    if (cleanPhone.length >= 10) {
                      final intl = cleanPhone.startsWith('0')
                          ? '2$cleanPhone'
                          : cleanPhone.replaceFirst('+', '');
                      final waUri = Uri.parse(
                        'https://wa.me/$intl?text=${Uri.encodeComponent(tpl.body)}',
                      );
                      if (await canLaunchUrl(waUri)) {
                        await launchUrl(waUri, mode: LaunchMode.externalApplication);
                        return;
                      }
                    }
                    await SharePlus.instance.share(ShareParams(text: tpl.body));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.surfaceSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(tpl.icon, style: const TextStyle(fontSize: 15)),
                            const SizedBox(width: 6),
                            Text(
                              tpl.title,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: p.ink,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.send_rounded, size: 16, color: p.gold),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tpl.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: p.inkSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitationTab(AppPalette p) {
    final filtered = _visitations.where((v) {
      if (_visitFilter == 'pending') return !v.visited;
      if (_visitFilter == 'mine') return v.plannedByMe && !v.visited;
      if (_visitFilter == 'visited') return v.visited;
      return true;
    }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  _filterPill(p, 'محتاجين', 'pending', _visitations.where((v) => !v.visited).length),
                  const SizedBox(width: 6),
                  _filterPill(
                    p,
                    'أنا أفتقد',
                    'mine',
                    _visitations.where((v) => v.plannedByMe && !v.visited).length,
                  ),
                  const SizedBox(width: 6),
                  _filterPill(p, 'تم ✓', 'visited', _visitations.where((v) => v.visited).length),
                  const SizedBox(width: 6),
                  _filterPill(p, 'الكل', 'all', _visitations.length),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _emptyBox(
                      p,
                      Icons.home_work_outlined,
                      _visitFilter == 'mine'
                          ? 'مفيش حد في خطة افتقاد قدسك دلوقتي'
                          : 'دفتر الافتقاد فاضي هنا دلوقتي',
                      _visitFilter == 'mine'
                          ? 'اضغط على زر «أنا أفتقد» جنب أي أسرة أو مريض عشان ينزل في جدول نزول قدسك علطول.'
                          : 'سجّل أسماء الأسر والمرضى للافتقاد، وقدسك تقدر تتصل بيهم أو تبعتلهم رسالة اطمئنان بضغطة واحدة وبخصوصية تامة على موبايلك.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, idx) {
                        final v = filtered[idx];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: v.visited
                                  ? p.border
                                  : (v.plannedByMe ? p.sage : p.goldBorder),
                              width: v.plannedByMe && !v.visited ? 1.4 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      HapticFeedback.selectionClick();
                                      final i = _visitations.indexWhere((x) => x.id == v.id);
                                      if (i != -1) {
                                        setState(() {
                                          _visitations[i] = v.copyWith(
                                            visited: !v.visited,
                                            plannedByMe: !v.visited ? false : v.plannedByMe,
                                          );
                                        });
                                        await _saveVisitations();
                                      }
                                    },
                                    child: Icon(
                                      v.visited
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      color: v.visited ? p.sage : p.gold,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v.personName,
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: p.ink,
                                            decoration: v.visited ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                        if (v.area.isNotEmpty)
                                          Text(
                                            v.area,
                                            style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkSecondary),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (v.plannedByMe && !v.visited) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: p.sage.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'أنا هروح أفتقده ✓',
                                        style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: p.sage,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: p.goldSoft,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      v.tag,
                                      style: GoogleFonts.cairo(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: p.gold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (v.note.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  v.note,
                                  style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary, height: 1.45),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (!v.visited)
                                    FilledButton.tonalIcon(
                                      onPressed: () async {
                                        HapticFeedback.lightImpact();
                                        final i = _visitations.indexWhere((x) => x.id == v.id);
                                        if (i != -1) {
                                          final next = !v.plannedByMe;
                                          setState(() {
                                            _visitations[i] = v.copyWith(plannedByMe: next);
                                          });
                                          await _saveVisitations();
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  next
                                                      ? 'اتسجّل في خطة افتقاد قدسك: «أنا أفتقد ${v.personName}»'
                                                      : 'اتشال من خطة الافتقاد الحالية',
                                                  style: GoogleFonts.cairo(),
                                                ),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: v.plannedByMe
                                            ? p.sage.withValues(alpha: 0.16)
                                            : p.goldSoft,
                                        foregroundColor: v.plannedByMe ? p.sage : p.gold,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: Icon(
                                        v.plannedByMe
                                            ? Icons.directions_walk_rounded
                                            : Icons.volunteer_activism_rounded,
                                        size: 15,
                                      ),
                                      label: Text(
                                        v.plannedByMe ? 'أنا أفتقد ✓' : 'أنا أفتقد',
                                        style: GoogleFonts.cairo(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  OutlinedButton.icon(
                                    onPressed: () => _openPastoralMessageSheet(v),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: p.accent,
                                      side: BorderSide(color: p.goldBorder),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                                    label: Text(
                                      'تهنئة / اطمئنان',
                                      style: GoogleFonts.cairo(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (v.phone.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: () async {
                                        final uri = Uri(scheme: 'tel', path: v.phone);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: Icon(Icons.call_rounded, size: 15, color: p.sage),
                                      label: Text(
                                        'اتصال',
                                        style: GoogleFonts.cairo(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: p.sage,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    tooltip: 'تعديل',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                    icon: Icon(Icons.edit_outlined, size: 18, color: p.inkMuted),
                                    onPressed: () => _openAddVisitationSheet(existing: v),
                                  ),
                                  IconButton(
                                    tooltip: 'مسح',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                    icon: Icon(Icons.delete_outline_rounded, size: 18, color: p.inkMuted),
                                    onPressed: () async {
                                      setState(() => _visitations.removeWhere((x) => x.id == v.id));
                                      await _saveVisitations();
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
    );
  }

  Widget _buildSermonsTab(AppPalette p) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: _sermons.isEmpty
            ? _emptyBox(
                p,
                Icons.edit_note_rounded,
                'كشكول تحضير العظات فارغ حالياً',
                'اكتب أفكار عظات الآحاد والأعياد مع الشواهد الكتابية وأقوال الآباء — متاح دائماً بدون إنترنت.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                itemCount: _sermons.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, idx) {
                  final s = _sermons[idx];
                  return Container(
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
                            Expanded(
                              child: Text(
                                s.title,
                                style: GoogleFonts.amiri(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: p.ink,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'مشاركة العظة',
                              icon: Icon(Icons.share_outlined, size: 19, color: p.accent),
                              onPressed: () {
                                final text = [
                                  s.title,
                                  if (s.occasion.isNotEmpty) 'المناسبة: ${s.occasion}',
                                  if (s.scriptureRef.isNotEmpty) 'الشاهد: ${s.scriptureRef}',
                                  if (s.points.isNotEmpty) '\n${s.points}',
                                  if (s.patristicQuote.isNotEmpty) '\nقول آبائي: ${s.patristicQuote}',
                                ].join('\n');
                                SharePlus.instance.share(ShareParams(text: text));
                              },
                            ),
                            IconButton(
                              tooltip: 'تعديل',
                              icon: Icon(Icons.edit_outlined, size: 19, color: p.inkMuted),
                              onPressed: () => _openSermonEditorSheet(existing: s),
                            ),
                            IconButton(
                              tooltip: 'حذف',
                              icon: Icon(Icons.delete_outline_rounded, size: 19, color: p.inkMuted),
                              onPressed: () async {
                                setState(() => _sermons.removeWhere((x) => x.id == s.id));
                                await _saveSermons();
                              },
                            ),
                          ],
                        ),
                        if (s.occasion.isNotEmpty || s.scriptureRef.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (s.occasion.isNotEmpty)
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: p.goldSoft,
                                  label: Text(
                                    s.occasion,
                                    style: GoogleFonts.cairo(fontSize: 11, color: p.gold, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              if (s.scriptureRef.isNotEmpty)
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: p.surfaceSubtle,
                                  label: Text(
                                    s.scriptureRef,
                                    style: GoogleFonts.cairo(fontSize: 11, color: p.accent, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        if (s.points.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            s.points,
                            style: GoogleFonts.cairo(fontSize: 13, color: p.inkSecondary, height: 1.6),
                          ),
                        ],
                        if (s.patristicQuote.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: p.goldSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: p.goldBorder),
                            ),
                            child: Text(
                              '«${s.patristicQuote}»',
                              style: GoogleFonts.amiri(fontSize: 15.5, color: p.ink, height: 1.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _filterPill(AppPalette p, String label, String key, int count) {
    final sel = _visitFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _visitFilter = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel ? p.gold : p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? p.gold : p.border),
          ),
          child: Text(
            '$label ($count)',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: sel ? const Color(0xFF19130A) : p.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyBox(AppPalette p, IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: p.goldSoft,
                shape: BoxShape.circle,
                border: Border.all(color: p.goldBorder),
              ),
              child: Icon(icon, size: 30, color: p.gold),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.bold, color: p.ink),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkSecondary, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}
