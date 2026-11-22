import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/patron_saint_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/blessing_poster_studio_sheet.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../core/widgets/saint_icon_avatar.dart';

/// Museum-Grade Coptic Patron Saint Sanctuary («شفيعي الشخصي»):
/// Features bespoke Neo-Coptic Iconography framing, daily message & practical spiritual step,
/// Synaxarium biography, intercession prayer, and a refined 2-column Gallery picker for 850+ saints.
class MyPatronSaintView extends StatefulWidget {
  const MyPatronSaintView({super.key});

  @override
  State<MyPatronSaintView> createState() => _MyPatronSaintViewState();
}

class _MyPatronSaintViewState extends State<MyPatronSaintView> {
  final StorageService _storage = StorageService();
  late String _selectedSaintId;
  bool _loadingSynaxariumSaints = true;

  @override
  void initState() {
    super.initState();
    _selectedSaintId = _storage.getPatronSaintId();
    _initAllSaints();
  }

  Future<void> _initAllSaints() async {
    await PatronSaintService.ensureLoaded();
    if (mounted) {
      setState(() => _loadingSynaxariumSaints = false);
    }
  }

  Future<void> _chooseSaint(PatronSaintProfile saint) async {
    HapticFeedback.mediumImpact();
    setState(() => _selectedSaintId = saint.id);
    await _storage.setPatronSaintId(saint.id);
    await FirebaseService().syncPublicProfile(
      displayName: _storage.getUserName(),
      patronSaintId: saint.id,
    );
    await NotificationService().syncScheduledNotifications();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم اختيار «${saint.shortName}» شفيعاً شخصياً لك.',
          style: GoogleFonts.cairo(fontSize: 13),
        ),
      ),
    );
  }

  void _openSaintPickerSheet() {
    String searchQuery = '';
    String selectedCategory = 'الكل';
    bool galleryMode = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final p = ctx.palette;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final allSaints = PatronSaintService.saints;
            final filtered = allSaints.where((s) {
              final matchCat = selectedCategory == 'الكل' || s.category == selectedCategory;
              final q = searchQuery.trim();
              final matchSearch = q.isEmpty ||
                  s.name.contains(q) ||
                  s.shortName.contains(q) ||
                  s.title.contains(q) ||
                  s.feastDate.contains(q);
              return matchCat && matchSearch;
            }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.88,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: p.canvas,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border(top: BorderSide(color: p.border, width: 1)),
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'معرض قديسي الكنيسة (${allSaints.length})',
                              style: GoogleFonts.amiri(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: p.ink,
                              ),
                            ),
                            Text(
                              'اختر شفيعك من بين كل القديسين والشهداء وآباء البرية',
                              style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkSecondary),
                            ),
                          ],
                        ),
                      ),
                      LuxeCircleButton(
                        icon: galleryMode ? Icons.view_list_rounded : Icons.grid_view_rounded,
                        size: 38,
                        tooltip: galleryMode ? 'عرض كقائمة' : 'عرض كمعرض',
                        onTap: () => setSheetState(() => galleryMode = !galleryMode),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Clean Adaptive Search
                  TextField(
                    onChanged: (v) => setSheetState(() => searchQuery = v),
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                    decoration: const InputDecoration(
                      hintText: 'ابحث باسم القديس أو الشهيد أو تاريخ العيد...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category Pills
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: PatronSaintService.categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (_, cIdx) {
                        final cat = PatronSaintService.categories[cIdx];
                        final isSelCat = cat == selectedCategory;
                        return ChoiceChip(
                          label: Text(
                            cat,
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              fontWeight: isSelCat ? FontWeight.bold : FontWeight.w500,
                              color: isSelCat ? p.onAccent : p.ink,
                            ),
                          ),
                          selected: isSelCat,
                          selectedColor: p.accent,
                          backgroundColor: p.surface,
                          showCheckmark: false,
                          side: BorderSide(color: isSelCat ? p.accent : p.border),
                          onSelected: (_) => setSheetState(() => selectedCategory = cat),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Text(
                      '${filtered.length} قديس وشفيع',
                      style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Refined 2-Column Museum Portrait Gallery OR Detailed List
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'لا يوجد قديس مطابق لبحثك.',
                              style: GoogleFonts.cairo(color: p.inkMuted, fontSize: 13.5),
                            ),
                          )
                        : galleryMode
                            ? GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.76,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (c, idx) {
                                  final s = filtered[idx];
                                  final isSel = s.id == _selectedSaintId;
                                  final imgUrl = PatronSaintService.getImageUrlForSaint(s);
                                  return _buildGalleryPortraitTile(
                                    p: p,
                                    saint: s,
                                    imgUrl: imgUrl,
                                    isSelected: isSel,
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _chooseSaint(s);
                                    },
                                  );
                                },
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (c, idx) {
                                  final s = filtered[idx];
                                  final isSel = s.id == _selectedSaintId;
                                  final imgUrl = PatronSaintService.getImageUrlForSaint(s);
                                  return Material(
                                    type: MaterialType.transparency,
                                    child: ListTile(
                                      dense: true,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(
                                          color: isSel ? p.accent : p.border,
                                          width: isSel ? 1.4 : 1,
                                        ),
                                      ),
                                      tileColor: isSel ? p.goldSoft : p.surface,
                                      leading: SaintIconAvatar(
                                        imageUrl: imgUrl,
                                        size: 46,
                                        shape: SaintAvatarShape.circle,
                                      ),
                                      title: Text(
                                        s.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isSel ? p.accent : p.ink,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${s.category} • ${s.feastDate}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                                      ),
                                      trailing: Icon(
                                        isSel ? Icons.check_circle_rounded : Icons.chevron_left_rounded,
                                        color: isSel ? p.accent : p.inkMuted,
                                        size: 20,
                                      ),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _chooseSaint(s);
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGalleryPortraitTile({
    required AppPalette p,
    required PatronSaintProfile saint,
    required String imgUrl,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isAsset = imgUrl.startsWith('assets/');
    return PressScale(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: p.surface,
          border: Border.all(
            color: isSelected ? p.accent : p.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: p.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              isAsset
                  ? Image.asset(
                      imgUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )
                  : Image.network(
                      imgUrl,
                      headers: const {
                        'User-Agent': 'OrthodoxiaCopticApp/1.0 (https://github.com/philo626/orthoxia)',
                      },
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      cacheWidth: 320,
                      errorBuilder: (_, _, _) => Container(
                        color: p.goldSoft,
                        child: Center(child: CopticCross(size: 36, color: p.gold)),
                      ),
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.45, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'شفيعي',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: p.onAccent,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 10,
                left: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      saint.shortName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.amiri(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      saint.feastDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: const Color(0xFFEBD7AA),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final saint = PatronSaintService.getSaintById(_selectedSaintId);
    final todayQuote = PatronSaintService.getDailyQuote(saint.id);
    final totalSaintsCount = PatronSaintService.saints.length;
    final saintImageUrl = PatronSaintService.getImageUrlForSaint(saint);

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        title: Text(
          'شفيعي الشخصي',
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: p.ink,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _openSaintPickerSheet,
            icon: Icon(Icons.collections_outlined, color: p.accent, size: 18),
            label: Text(
              'المعرض ($totalSaintsCount)',
              style: GoogleFonts.cairo(
                color: p.accent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 44),
            children: [
              // 1. Museum Framed Neo-Coptic Icon Portrait Showcase
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: p.border),
                  boxShadow: p.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: p.shadow,
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    SaintIconAvatar(
                      imageUrl: saintImageUrl,
                      size: 164,
                      shape: SaintAvatarShape.museumCard,
                      saintName: saint.name,
                      saintTitle: saint.title,
                      enableFullViewer: true,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.goldSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: p.goldBorder, width: 0.8),
                      ),
                      child: Text(
                        saint.category,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: p.gold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      saint.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      saint.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        color: p.inkSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 13, color: p.gold),
                        const SizedBox(width: 6),
                        Text(
                          'تذكار العيد: ${saint.feastDate}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openSaintPickerSheet,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: p.surfaceSubtle,
                          side: BorderSide(color: p.border),
                          minimumSize: const Size(double.infinity, 46),
                        ),
                        icon: Icon(Icons.grid_view_rounded, size: 18, color: p.accent),
                        label: Text(
                          _loadingSynaxariumSaints
                              ? 'جاري تحميل المعرض...'
                              : 'تبديل شفيعي من معرض القديسين ($totalSaintsCount)',
                          style: GoogleFonts.cairo(
                            color: p.ink,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Today's Daily Message Card (Book-Printed Editorial Style)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.border),
                  boxShadow: p.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: p.shadow,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CopticCross(size: 16, color: p.isDark ? p.gold : p.accent),
                        const SizedBox(width: 8),
                        Text(
                          'رسالة شفيعك اليوم',
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: p.accent,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'تتجدد يومياً',
                          style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: p.gold, width: 2.5)),
                      ),
                      child: Text(
                        '«${todayQuote.quote}»',
                        style: GoogleFonts.amiri(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          height: 1.7,
                          color: p.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: p.surfaceSubtle,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(Icons.auto_stories_outlined, size: 16, color: p.gold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'تدريب اليوم: ${todayQuote.lesson}',
                              style: GoogleFonts.cairo(
                                fontSize: 12.5,
                                height: 1.55,
                                color: p.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      todayQuote.prayer,
                      style: GoogleFonts.amiri(
                        fontSize: 17.5,
                        height: 1.6,
                        color: p.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        SpeechPlayStopButton(
                          textToSpeak:
                              'رسالة شفيعك اليوم ${saint.name}: ${todayQuote.quote}. تدريب اليوم: ${todayQuote.lesson}. ${todayQuote.prayer}',
                          label: saint.shortName,
                          playText: 'استماع',
                          stopText: 'إيقاف',
                          compact: true,
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            BlessingPosterStudioSheet.show(
                              context,
                              title: 'من أقوال ${saint.shortName}',
                              bodyText: todayQuote.quote,
                              reference: saint.name,
                              footerPrayer: todayQuote.prayer,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          icon: Icon(Icons.photo_camera_back_outlined, size: 16, color: p.accent),
                          label: Text(
                            'بطاقة مصورة',
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                              text: '«${todayQuote.quote}»\n— ${saint.name}\n\n${todayQuote.prayer}',
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم نسخ قول شفيعك اليوم', style: GoogleFonts.cairo()),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          icon: Icon(Icons.copy_rounded, size: 15, color: p.inkSecondary),
                          label: Text('نسخ', style: GoogleFonts.cairo(fontSize: 12)),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            SharePlus.instance.share(
                              ShareParams(
                                text:
                                    'رسالة شفيعي اليوم (${saint.name}):\n\n«${todayQuote.quote}»\n\n${todayQuote.lesson}\n${todayQuote.prayer}\n\nمن تطبيق أرثوذكسيا',
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          icon: const Icon(Icons.share_outlined, size: 15),
                          label: Text(
                            'مشاركة',
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. Liturgical Intercession Prayer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.goldSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.goldBorder),
                ),
                child: Row(
                  children: [
                    CopticCross(size: 18, color: p.isDark ? p.gold : p.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        saint.intercessionPrayer,
                        style: GoogleFonts.amiri(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (saint.biography.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
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
                          Icon(Icons.menu_book_outlined, color: p.accent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'سيرة القديس من السنكسار القبطي (${saint.feastDate})',
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: p.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        saint.biography,
                        style: GoogleFonts.amiri(
                          fontSize: 18,
                          height: 1.85,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // 4. All Sayings of This Saint
              Text(
                'مختارات من أقوال ${saint.shortName}',
                style: GoogleFonts.amiri(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 10),
              ...saint.quotes.map(
                (q) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '«${q.quote}»',
                        style: GoogleFonts.amiri(
                          fontSize: 18.5,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                          height: 1.65,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        q.lesson,
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          color: p.inkSecondary,
                          height: 1.5,
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
    );
  }
}
