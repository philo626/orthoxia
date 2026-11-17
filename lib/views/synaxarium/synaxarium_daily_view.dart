import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../providers/theme_provider.dart';

class SynaxariumDailyView extends StatefulWidget {
  final int? initialMonth;
  final int? initialDay;

  const SynaxariumDailyView({
    super.key,
    this.initialMonth,
    this.initialDay,
  });

  @override
  State<SynaxariumDailyView> createState() => _SynaxariumDailyViewState();
}

class _SynaxariumDailyViewState extends State<SynaxariumDailyView> {
  late int _selectedMonth;
  late int _selectedDay;
  String _selectedCategory = 'today';
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<int> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    final today = CopticCalendarService.fromGregorian(DateTime.now());
    _selectedMonth = widget.initialMonth ?? today.month.clamp(1, 13);
    _selectedDay = widget.initialDay ?? today.day.clamp(1, 30);
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await CopticCalendarService.ensureLectionaryLoaded();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _resetToToday() {
    HapticFeedback.mediumImpact();
    final today = CopticCalendarService.fromGregorian(DateTime.now());
    setState(() {
      _selectedMonth = today.month.clamp(1, 13);
      _selectedDay = today.day.clamp(1, 30);
      _selectedCategory = 'today';
      _searchQuery = '';
      _searchCtrl.clear();
      _expandedItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = context.watch<ThemeProvider>().fontScale;
    final today = CopticCalendarService.fromGregorian(DateTime.now());
    final isToday = _selectedMonth == today.month && _selectedDay == today.day;
    final monthName = CopticCalendarService.copticMonths[(_selectedMonth - 1).clamp(0, 12)];
    final maxDays = _selectedMonth == 13 ? 6 : 30;

    List<Map<String, String>> items;
    if (_searchQuery.trim().isNotEmpty) {
      items = CopticCalendarService.searchSynaxarium(_searchQuery);
    } else {
      items = CopticCalendarService.getCategorizedSynaxariumItems(
        month: _selectedMonth,
        day: _selectedDay,
        category: _selectedCategory,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        title: Text(
          'السنكسار القبطي اليومي والجامع',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        actions: [
          if (!isToday || _searchQuery.isNotEmpty)
            TextButton.icon(
              onPressed: _resetToToday,
              icon: const Icon(Icons.today_rounded, color: AppColors.primaryGold, size: 18),
              label: Text(
                'اليوم',
                style: GoogleFonts.cairo(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
          : Column(
              children: [
                // 1. Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _searchQuery.isNotEmpty
                            ? AppColors.primaryGold
                            : AppColors.primaryGold.withValues(alpha: 0.25),
                      ),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن اسم قديس أو شهيد أو عيد كنسي...',
                        hintStyle: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryGold, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),

                // 2. Active Coptic Date Banner
                if (_searchQuery.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF281E12), Color(0xFF161514)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.primaryGold, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withValues(alpha: 0.12),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const CopticCross(size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '$_selectedDay $monthName ${today.year} ش',
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGoldLight,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isToday)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGold.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'تذكار اليوم',
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGoldLight,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${today.seasonName} • ${today.fastingNote}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: AppColors.primaryGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Month & Day Picker (Coptic Calendar Selector)
                if (_searchQuery.isEmpty) ...[
                  // Months Horizontal Selector
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: CopticCalendarService.copticMonths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, idx) {
                          final mIdx = idx + 1;
                          final isSel = mIdx == _selectedMonth;
                          return ChoiceChip(
                            label: Text(
                              CopticCalendarService.copticMonths[idx],
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSel ? Colors.black : AppColors.textLight,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: AppColors.primaryGold,
                            backgroundColor: AppColors.cardNavy,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedMonth = mIdx;
                                if (_selectedDay > (mIdx == 13 ? 6 : 30)) {
                                  _selectedDay = 1;
                                }
                                _expandedItems.clear();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // Days Horizontal Selector
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: maxDays,
                      separatorBuilder: (_, __) => const SizedBox(width: 5),
                      itemBuilder: (context, idx) {
                        final d = idx + 1;
                        final isSel = d == _selectedDay;
                        return ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            '$d',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.black : AppColors.primaryGoldLight,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.primaryGold,
                          backgroundColor: AppColors.cardNavy,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedDay = d;
                              _expandedItems.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Categories Filter Chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: CopticCalendarService.synaxariumCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, idx) {
                        final cat = CopticCalendarService.synaxariumCategories[idx];
                        final isSel = _selectedCategory == cat['id'];
                        return FilterChip(
                          label: Text(
                            cat['name']!,
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.black : AppColors.textLight,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.primaryGoldLight,
                          backgroundColor: AppColors.cardNavy,
                          checkmarkColor: Colors.black,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedCategory = cat['id']!;
                              _expandedItems.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // 4. Commemorations List
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.menu_book_rounded, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'لم يتم العثور على نتائج للبحث «$_searchQuery»'
                                    : 'لا توجد تذكارات مسجلة لهذا القسم في هذا اليوم',
                                style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final title = item['title'] ?? '';
                            final text = item['text'] ?? item['summary'] ?? '';
                            final dateLabel = item['date'] ?? '$_selectedDay $monthName';
                            final catName = item['category_name'] ?? 'تذكار كنسي';
                            final isExpanded = _expandedItems.contains(index);

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardNavy,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.primaryGold.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Header with Category Badge and Title
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        if (isExpanded) {
                                          _expandedItems.remove(index);
                                        } else {
                                          _expandedItems.add(index);
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(18),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryGold.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const CopticCross(size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primaryGold.withValues(alpha: 0.2),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        catName,
                                                        style: GoogleFonts.cairo(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.primaryGoldLight,
                                                        ),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      dateLabel,
                                                      style: GoogleFonts.cairo(
                                                        fontSize: 11,
                                                        color: AppColors.primaryGold,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  title,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 15 * fontScale,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            isExpanded
                                                ? Icons.keyboard_arrow_up_rounded
                                                : Icons.keyboard_arrow_down_rounded,
                                            color: AppColors.primaryGold,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Expanded Biography Text
                                  if (isExpanded) ...[
                                    const Divider(color: Color(0xFF2C2E3E), height: 1),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          SelectableText(
                                            text,
                                            style: GoogleFonts.cairo(
                                              fontSize: 13.5 * fontScale,
                                              height: 1.75,
                                              color: const Color(0xFFECEFF1),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          // Blessing Note
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E1C18),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppColors.primaryGold.withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const CopticCross(size: 16),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'بركة صلواتهم وشفاعتهم فلتكن معنا جميعاً. ولربنا المجد دائماً أبدياً آمين.',
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.primaryGoldLight,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Share & Copy Actions
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: () {
                                                  Clipboard.setData(ClipboardData(text: '$title\n\n$text'));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'تم نسخ سيرة القديس إلى الحافظة',
                                                        style: GoogleFonts.cairo(),
                                                      ),
                                                      backgroundColor: AppColors.cardNavy,
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primaryGold),
                                                label: Text(
                                                  'نسخ',
                                                  style: GoogleFonts.cairo(
                                                    color: AppColors.primaryGold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  Share.share(
                                                    '✝ سنكسار الكنيسة القبطية الأرثوذكسية ($dateLabel)\n\n$title\n\n$text\n\nبركة صلواتهم فلتكن معنا. آمين.\nمن تطبيق أرثوذكسيا',
                                                  );
                                                },
                                                icon: const Icon(Icons.share_rounded, size: 16, color: Colors.black),
                                                label: Text(
                                                  'مشاركة',
                                                  style: GoogleFonts.cairo(
                                                    color: Colors.black,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primaryGold,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    // Collapsed summary preview
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                      child: Text(
                                        text.replaceAll('\n', ' ').trim(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 12.5,
                                          height: 1.5,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ).animate().fadeIn(duration: 250.ms, delay: (index * 40).ms);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
