import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../bible/bible_explorer_view.dart';
import '../search/global_search_view.dart';
import 'books_library_view.dart';

/// Unified «الكتاب والمكتبة» Hub — puts Bible (73 books), Patristic Tafsir (73 books),
/// 98 Complete Full-Chapter Books, and 420+ Comprehensive Internet Archive Library
/// all within 1 tap at the top bar, with zero nested TabBars.
class ScriptureLibraryHubView extends StatefulWidget {
  final ValueNotifier<int>? externalTabNotifier;

  const ScriptureLibraryHubView({super.key, this.externalTabNotifier});

  @override
  State<ScriptureLibraryHubView> createState() => _ScriptureLibraryHubViewState();
}

class _ScriptureLibraryHubViewState extends State<ScriptureLibraryHubView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initial = (widget.externalTabNotifier?.value ?? 0).clamp(0, 3);
    _tabController = TabController(length: 4, vsync: this, initialIndex: initial);
    widget.externalTabNotifier?.addListener(_onExternalTabRequest);
  }

  void _onExternalTabRequest() {
    final target = (widget.externalTabNotifier?.value ?? 0).clamp(0, 3);
    if (_tabController.index != target) {
      _tabController.animateTo(target);
    }
  }

  @override
  void dispose() {
    widget.externalTabNotifier?.removeListener(_onExternalTabRequest);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Clean Masthead
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الكتاب والمكتبة',
                          style: GoogleFonts.amiri(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            color: p.ink,
                            height: 1.15,
                          ),
                        ),
                        Text(
                          '٧٣ سفراً • تفاسير الآباء • كتب مصوّرة بصفحاتها',
                          style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary),
                        ),
                      ],
                    ),
                  ),
                  LuxeCircleButton(
                    icon: Icons.search_rounded,
                    size: 38,
                    tooltip: 'بحث شامل',
                    onTap: () => Navigator.push(context, luxeRoute(const GlobalSearchView())),
                  ),
                ],
              ),
            ),

            // Single Crisp 4-Tab Bar (Zero nested TabBars!)
            Container(
              decoration: BoxDecoration(
                color: p.canvas,
                border: Border(bottom: BorderSide(color: p.border, width: 0.9)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: p.accent,
                indicatorWeight: 2.5,
                labelColor: p.accent,
                unselectedLabelColor: p.inkMuted,
                labelStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                tabs: const [
                  Tab(text: 'الكتاب المقدس'),
                  Tab(text: 'التفاسير (٧٣)'),
                  Tab(text: 'الكتب المصوّرة'),
                  Tab(text: 'المكتبة الشاملة'),
                ],
              ),
            ),

            // Direct Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  BibleExplorerView(embedded: true),
                  BooksLibraryView(embedded: true, singleTabIndex: 1),
                  BooksLibraryView(embedded: true, singleTabIndex: 0),
                  BooksLibraryView(embedded: true, singleTabIndex: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
