import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/book_model.dart';
import '../../models/commentary_model.dart';
import '../../providers/books_provider.dart';
import 'book_reader_view.dart';
import 'commentary_reader_view.dart';

class BooksLibraryView extends StatelessWidget {
  const BooksLibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BooksProvider>(
      builder: (context, booksProv, _) {
        if (booksProv.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.deepNavy,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold),
            ),
          );
        }

        final books = booksProv.filteredBooks;
        final commentaries = booksProv.filteredCommentaries;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'مكتبة الكتب والتفاسير الكنسية',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          body: Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (val) => booksProv.setSearchQuery(val),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryGold),
                    hintText: 'ابحث عن كتاب، سفر، مؤلف، أو تفسير...',
                    hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.7)),
                    filled: true,
                    fillColor: AppColors.cardNavy,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Categories Chips
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: booksProv.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = booksProv.categories[index];
                    final isSelected = booksProv.selectedCategory == cat['id'];
                    return ChoiceChip(
                      label: Text(
                        cat['name']!,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : AppColors.textLight,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryGold,
                      backgroundColor: AppColors.cardNavy,
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryGold : Colors.white.withValues(alpha: 0.1),
                      ),
                      onSelected: (_) => booksProv.selectCategory(cat['id']!),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Content List
              Expanded(
                child: (books.isEmpty && commentaries.isEmpty)
                    ? Center(
                        child: Text(
                          'لا توجد كتب أو تفاسير مطابقة للبحث',
                          style: GoogleFonts.cairo(color: AppColors.textMuted),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        children: [
                          // 1. Commentaries Section
                          if (commentaries.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.auto_stories_rounded, color: AppColors.primaryGold, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'تفاسير أسفار العهدين القديم والجديد',
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            for (var comm in commentaries) ...[
                              _buildCommentaryCard(context, comm),
                              const SizedBox(height: 10),
                            ],
                            const SizedBox(height: 20),
                          ],

                          // 2. Patristic & Spiritual Books Section
                          if (books.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.library_books_rounded, color: AppColors.primaryGold, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'أمهات الكتب الآبائية والروحية',
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            for (var book in books) ...[
                              _buildBookCard(context, book),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentaryCard(BuildContext context, BibleBookCommentary comm) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CommentaryReaderView(commentary: comm)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.sacredBurgundy.withValues(alpha: 0.3),
                    border: Border.all(color: AppColors.primaryGold, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.menu_book_rounded, color: AppColors.primaryGold, size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comm.bibleBookName,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        comm.commentator,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.primaryGoldLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comm.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primaryGold),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, Book book) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: book.isFeatured ? AppColors.primaryGold : Colors.white.withValues(alpha: 0.08),
          width: book.isFeatured ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookReaderView(book: book)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surfaceNavy,
                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(book.coverIcon, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              book.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceNavy,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              book.categoryName,
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: AppColors.primaryGoldLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.author,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.primaryGoldLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${book.chaptersCount} فصول للقراءة والتأمل',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: AppColors.primaryGold.withValues(alpha: 0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primaryGold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
