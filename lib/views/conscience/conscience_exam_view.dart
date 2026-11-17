import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/spiritual_tracker_provider.dart';

class ConscienceExamView extends StatefulWidget {
  const ConscienceExamView({super.key});

  @override
  State<ConscienceExamView> createState() => _ConscienceExamViewState();
}

class _ConscienceExamViewState extends State<ConscienceExamView> {
  String _selectedCategory = 'علاقتي بالله';

  final List<String> _categories = [
    'علاقتي بالله',
    'علاقتي بالقريب',
    'نقاوة القلب والجسد',
  ];

  void _confirmSelfDestruct() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'محو سجل فحص الضمير',
          style: GoogleFonts.cairo(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل قمت بالاعتراف وتريد محو جميع ملاحظاتك الشخصية من هذا الجهاز نهائياً لحفظ السرية التامة؟',
          style: GoogleFonts.cairo(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<SpiritualTrackerProvider>(context, listen: false).clearConscienceNotes();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم محو جميع ملاحظات الاعتراف بنجاح وبسرية تامة.',
                      style: GoogleFonts.cairo()),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('نعم، امح الملاحظات', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpiritualTrackerProvider>(
      builder: (context, trackerProv, _) {
        final allQuestions = trackerProv.conscienceQuestions;
        final filteredQuestions =
            allQuestions.where((q) => q.category == _selectedCategory).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'دليل فحص الضمير للاعتراف',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                tooltip: 'محو الملاحظات بعد الاعتراف',
                onPressed: _confirmSelfDestruct,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Notice banner: Zero-server storage
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.sacredBurgundy.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: AppColors.primaryGold, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'بيانات فحص الضمير مشفرة محلياً 100% ولا ترفع لأي سيرفر. يمكنك محوها بالكامل بعد الاعتراف.',
                        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.primaryGoldLight),
                      ),
                    ),
                  ],
                ),
              ),

              // Category Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _categories.map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primaryGold : AppColors.cardNavy,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? AppColors.primaryGold : Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Text(
                            cat,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.black : AppColors.textLight,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              // Questions list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredQuestions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final q = filteredQuestions[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: q.isChecked
                              ? AppColors.primaryGold
                              : Colors.white.withOpacity(0.08),
                          width: q.isChecked ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: q.isChecked,
                                activeColor: AppColors.primaryGold,
                                checkColor: Colors.black,
                                onChanged: (_) => trackerProv.toggleQuestion(q.id),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      q.title,
                                      style: GoogleFonts.cairo(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: q.isChecked
                                            ? AppColors.primaryGold
                                            : AppColors.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      q.explanation,
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        color: AppColors.textMuted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Personal Note Field if checked
                          if (q.isChecked) ...[
                            const SizedBox(height: 12),
                            TextField(
                              onChanged: (val) => trackerProv.updateQuestionNote(q.id, val),
                              controller: TextEditingController(text: q.personalNote)
                                ..selection = TextSelection.fromPosition(
                                    TextPosition(offset: q.personalNote.length)),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'ملاحظة سرية خاصة لتذكرها مع أب الاعتراف...',
                                hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.6)),
                                filled: true,
                                fillColor: AppColors.surfaceNavy,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: AppColors.primaryGold.withOpacity(0.3)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Self-Destruct / Action button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _confirmSelfDestruct,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text(
                    'إتمام الاعتراف ومحو الملاحظات',
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sacredBurgundy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
