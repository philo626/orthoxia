import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/luxe_widgets.dart';

class CopticLetterInfo {
  final String symbol;
  final String name;
  final String sound;
  final String rule;
  final String exampleCoptic;
  final String exampleArabized;
  final String exampleMeaning;

  const CopticLetterInfo({
    required this.symbol,
    required this.name,
    required this.sound,
    required this.rule,
    required this.exampleCoptic,
    required this.exampleArabized,
    required this.exampleMeaning,
  });
}

class CopticAcademyView extends StatefulWidget {
  const CopticAcademyView({super.key});

  static const List<CopticLetterInfo> alphabet = [
    CopticLetterInfo(symbol: 'Ⲁ ⲁ', name: 'ألفا', sound: 'ا / آ', rule: 'يُنطق دائماً مثل الألف الممدودة المفتوحة (ا).', exampleCoptic: 'Ⲁⲅⲁⲡⲏ', exampleArabized: 'أغابي', exampleMeaning: 'محبة'),
    CopticLetterInfo(symbol: 'Ⲃ ⲃ', name: 'فيتا', sound: 'ف / ب', rule: 'يُنطق (ف / V) إذا جاء بعده حرف متحرك، ويُنطق (ب) في آخر الكلمة أو قبل السواكن.', exampleCoptic: 'Ⲃⲏⲑⲗⲉⲉⲙ', exampleArabized: 'فيثلئيم', exampleMeaning: 'بيت لحم'),
    CopticLetterInfo(symbol: 'Ⲅ ⲅ', name: 'غاما', sound: 'غ / ج / ن', rule: 'يُنطق (ج صلبة) قبل الكسرات (ⲉ, ⲏ, ⲓ, ⲩ)، و(ن) قبل الحروف الحلقية، و(غ) فيما عدا ذلك.', exampleCoptic: 'Ⲁⲅⲓⲟⲥ', exampleArabized: 'أجيوس', exampleMeaning: 'قدوس'),
    CopticLetterInfo(symbol: 'Ⲇ ⲇ', name: 'دلتا', sound: 'د / ذ', rule: 'يُنطق (د) في الأسماء الأعلام، و(ذ) في الكلمات القبطية واليونانية العادية.', exampleCoptic: 'Ⲇⲁⲩⲓⲇ', exampleArabized: 'دافيد', exampleMeaning: 'داود'),
    CopticLetterInfo(symbol: 'Ⲉ ⲉ', name: 'إي', sound: 'إِ خفيفة', rule: 'حرف متحرك للكسر الخفيف مثل (إِ).', exampleCoptic: 'Ⲉ̀ⲕⲕⲗⲏⲥⲓⲁ', exampleArabized: 'إكليسيا', exampleMeaning: 'كنيسة'),
    CopticLetterInfo(symbol: 'Ⲋ ⲋ', name: 'سو', sound: 'رقم ٦', rule: 'يُستخدم كرقم (٦) في حساب الأبجدية القبطية وأرباع التسبحة.', exampleCoptic: 'ⲋ̅', exampleArabized: 'سو (٦)', exampleMeaning: 'العدد ستة'),
    CopticLetterInfo(symbol: 'Ⲍ ⲍ', name: 'زيتا', sound: 'ز', rule: 'يُنطق دائماً مثل حرف الزاي (ز).', exampleCoptic: 'Ⲍⲱⲏ', exampleArabized: 'زؤي', exampleMeaning: 'حياة'),
    CopticLetterInfo(symbol: 'Ⲏ ⲏ', name: 'إيتا', sound: 'إي طويلة', rule: 'حرف متحرك للكسر الطويل (ياء ممدودة: إي).', exampleCoptic: 'Ⲏⲗⲓⲁⲥ', exampleArabized: 'إيلياس', exampleMeaning: 'إيليا النبي'),
    CopticLetterInfo(symbol: 'Ⲑ ⲑ', name: 'ثيتا', sound: 'ث / ت', rule: 'يُنطق (ت) إذا سبقه (ⲥ أو ϣ)، ويُنطق (ث) فيما عدا ذلك.', exampleCoptic: 'Ⲑⲉⲟ̀ⲧⲟⲕⲟⲥ', exampleArabized: 'ثيؤطوكوس', exampleMeaning: 'والدة الإله'),
    CopticLetterInfo(symbol: 'Ⲓ ⲓ', name: 'يوتا', sound: 'ي / إِ', rule: 'حرف متحرك للكسر المتوسط أو ياء قصيرة.', exampleCoptic: 'Ⲓⲏⲥⲟⲩⲥ', exampleArabized: 'إيسوس', exampleMeaning: 'يسوع'),
    CopticLetterInfo(symbol: 'Ⲕ ⲕ', name: 'كابا', sound: 'ك', rule: 'يُنطق دائماً مثل حرف الكاف (ك).', exampleCoptic: 'Ⲕⲩⲣⲓⲉ', exampleArabized: 'كيريـي', exampleMeaning: 'يا رب'),
    CopticLetterInfo(symbol: 'Ⲗ ⲗ', name: 'لافلا', sound: 'ل', rule: 'يُنطق دائماً مثل حرف اللام (ل).', exampleCoptic: 'Ⲗⲁⲟⲥ', exampleArabized: 'لاؤس', exampleMeaning: 'شعب'),
    CopticLetterInfo(symbol: 'Ⲙ ⲙ', name: 'مي', sound: 'م', rule: 'يُنطق دائماً مثل حرف الميم (م).', exampleCoptic: 'Ⲙⲁⲣⲓⲁ', exampleArabized: 'ماريا', exampleMeaning: 'مريم'),
    CopticLetterInfo(symbol: 'Ⲛ ⲛ', name: 'ني', sound: 'ن', rule: 'يُنطق دائماً مثل حرف النون (ن).', exampleCoptic: 'Ⲛⲟⲩϯ', exampleArabized: 'نوتي', exampleMeaning: 'الله'),
    CopticLetterInfo(symbol: 'Ⲝ ⲝ', name: 'إكسي', sound: 'كس', rule: 'حرف مزدوج يُنطق (ك + س) معاً.', exampleCoptic: 'Ⲇⲟⲝⲁ', exampleArabized: 'ذوكسا', exampleMeaning: 'مجد'),
    CopticLetterInfo(symbol: 'Ⲟ ⲟ', name: 'أوميكرون', sound: 'أُ قصيرة', rule: 'حرف متحرك للضم القصير (أُ).', exampleCoptic: 'Ⲟⲩⲣⲟ', exampleArabized: 'أورو', exampleMeaning: 'ملك'),
    CopticLetterInfo(symbol: 'Ⲡ ⲡ', name: 'بي', sound: 'ب ثقيلة', rule: 'يُنطق دائماً مثل حرف الباء (ب / P).', exampleCoptic: 'Ⲡⲁⲧⲏⲣ', exampleArabized: 'باتير', exampleMeaning: 'آب'),
    CopticLetterInfo(symbol: 'Ⲣ ⲣ', name: 'رو', sound: 'ر', rule: 'يُنطق دائماً مثل حرف الراء (ر).', exampleCoptic: 'Ⲣⲁϣⲓ', exampleArabized: 'راشي', exampleMeaning: 'فرح'),
    CopticLetterInfo(symbol: 'Ⲥ ⲥ', name: 'سيما', sound: 'س / ز', rule: 'يُنطق (س)، ويُنطق (ز) في الكلمات اليونانية إذا وقع بين حرفين متحركين.', exampleCoptic: 'Ⲥⲱⲧⲏⲣ', exampleArabized: 'سوتير', exampleMeaning: 'مخلص'),
    CopticLetterInfo(symbol: 'Ⲧ ⲧ', name: 'تاف', sound: 'ت / د / ط', rule: 'يُنطق (د) بعد (ⲛ)، و(ط) مع الحروف المفخمة، و(ت) فيما عدا ذلك.', exampleCoptic: 'Ⲧ̀ⲣⲓⲁⲥ', exampleArabized: 'إترياس', exampleMeaning: 'الثالوث'),
    CopticLetterInfo(symbol: 'Ⲩ ⲩ', name: 'إبسلون', sound: 'ف / و / ي', rule: 'يُنطق (ف) بعد (ⲁ, ⲉ)، و(أو) بعد (ⲟ)، و(ي) فيما عدا ذلك.', exampleCoptic: 'Ⲉⲩⲁⲅⲅⲉⲗⲓⲟⲛ', exampleArabized: 'إيف أنجيليون', exampleMeaning: 'الإنجيل (البشارة)'),
    CopticLetterInfo(symbol: 'Phi ⲫ', name: 'في', sound: 'ف', rule: 'يُنطق دائماً مثل حرف الفاء (ف).', exampleCoptic: 'Ⲫ̀ⲛⲟⲩϯ', exampleArabized: 'إفنوتي', exampleMeaning: 'الله'),
    CopticLetterInfo(symbol: 'Chi ⲭ', name: 'كي', sound: 'ك / ش / خ', rule: 'يُنطق (ك) في الكلمات القبطية، وفي اليونانية يُنطق (ش) قبل الكسر و(خ) قبل غيره.', exampleCoptic: 'Ⲡⲓⲭ̀ⲣⲓⲥⲧⲟⲥ', exampleArabized: 'بي إخريستوس', exampleMeaning: 'المسيح'),
    CopticLetterInfo(symbol: 'Psi psi', name: 'إبسي', sound: 'بس', rule: 'حرف مزدوج يُنطق (ب + س) معاً.', exampleCoptic: 'ⲯⲁⲗⲙⲟⲥ', exampleArabized: 'إبسالموس', exampleMeaning: 'مزمور'),
    CopticLetterInfo(symbol: 'Ⲱ ⲱ', name: 'أوميجا', sound: 'أو طويلة', rule: 'حرف متحرك للضم الطويل الممدود (واو مد: أو).', exampleCoptic: 'Ⲱ̀ⲥⲁⲛⲛⲁ', exampleArabized: 'أوصنا', exampleMeaning: 'خلصنا (أوصنا)'),
    CopticLetterInfo(symbol: 'Ϣ ϣ', name: 'شاي', sound: 'ش', rule: 'حرف قبطي أصيل من الديموطيقية يُنطق دائماً (ش).', exampleCoptic: 'Ϣⲏⲣⲓ', exampleArabized: 'شيري', exampleMeaning: 'ابن'),
    CopticLetterInfo(symbol: 'Ϥ ϥ', name: 'فاي', sound: 'ف', rule: 'حرف قبطي أصيل يُنطق دائماً (ف).', exampleCoptic: 'Ϥⲁⲓ', exampleArabized: 'فاي', exampleMeaning: 'هذا / حامل'),
    CopticLetterInfo(symbol: 'Ϧ ϧ', name: 'خاي', sound: 'خ', rule: 'حرف قبطي أصيل يُنطق دائماً مثل الخاء العربية (خ).', exampleCoptic: 'Ϧⲉⲛ', exampleArabized: 'خين', exampleMeaning: 'في / باسم'),
    CopticLetterInfo(symbol: 'Ϩ ϩ', name: 'هوري', sound: 'هـ', rule: 'حرف قبطي أصيل يُنطق دائماً مثل الهاء (هـ).', exampleCoptic: 'Ϩⲓⲣⲏⲛⲏ', exampleArabized: 'هيريني', exampleMeaning: 'سلام'),
    CopticLetterInfo(symbol: 'Ϫ ϫ', name: 'جنجا', sound: 'ج / چ', rule: 'يُنطق (چ تعطيش) قبل حروف الكسر، و(ج قاهرية صلبة) قبل غيرها.', exampleCoptic: 'Ϫⲟⲓⲥ', exampleArabized: 'شويس / چويس', exampleMeaning: 'رب / سيد'),
    CopticLetterInfo(symbol: 'Ϭ ϭ', name: 'تشيما', sound: 'تش', rule: 'حرف قبطي أصيل يُنطق دائماً (تش / Ch).', exampleCoptic: 'Ⲡⲁϭⲟⲓⲥ', exampleArabized: 'باشويس', exampleMeaning: 'سيدي / ربي'),
    CopticLetterInfo(symbol: 'Ϯ ϯ', name: 'تي', sound: 'تي', rule: 'مقطع كامل يُنطق (ت + ي = تي)، ويعني أيضاً «يعطي» أو أداة تعريف مؤنثة.', exampleCoptic: 'Ϯϣⲟⲩⲣⲏ', exampleArabized: 'تي شوري', exampleMeaning: 'المجمرة'),
  ];

  @override
  State<CopticAcademyView> createState() => _CopticAcademyViewState();
}

class _CopticAcademyViewState extends State<CopticAcademyView> {
  int _selectedLetterIdx = 0;

  @override
  Widget build(BuildContext context) {
    final letter = CopticAcademyView.alphabet[_selectedLetterIdx];

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '٣٢ حرفاً قبطياً',
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                  ),
                  Text(
                    'أكاديمية اللغة القبطية',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  LuxeCircleButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Active Letter Showcase Card (Obsidian & Champagne Gold)
            Container(
              margin: const EdgeInsets.fromLTRB(18, 6, 18, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B2215), Color(0xFF161513)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primaryGold, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withValues(alpha: 0.22),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          letter.symbol,
                          style: GoogleFonts.cairo(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'حرف ${letter.name}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGoldLight,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGold,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'النطق: ${letter.sound}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              letter.rule,
                              style: GoogleFonts.cairo(
                                fontSize: 12.5,
                                color: AppColors.textLight,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 22, color: Colors.white12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('الكلمة بالقبطي',
                              style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted)),
                          Text(
                            letter.exampleCoptic,
                            style: GoogleFonts.cairo(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGoldLight,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text('النطق المعرب',
                              style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted)),
                          Text(
                            letter.exampleArabized,
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textArabized,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text('المعنى العربي',
                              style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted)),
                          Text(
                            letter.exampleMeaning,
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ).animate(key: ValueKey(_selectedLetterIdx)).fadeIn(duration: 240.ms),

            // 32 Coptic Letters Interactive Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.05,
                ),
                itemCount: CopticAcademyView.alphabet.length,
                itemBuilder: (context, idx) {
                  final item = CopticAcademyView.alphabet[idx];
                  final sel = idx == _selectedLetterIdx;
                  return PressScale(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedLetterIdx = idx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        gradient: sel
                            ? AppColors.champagne
                            : AppColors.obsidianCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sel
                              ? AppColors.primaryGoldLight
                              : AppColors.primaryGold.withValues(alpha: 0.25),
                          width: sel ? 1.6 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.symbol,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: sel ? Colors.black : AppColors.primaryGoldLight,
                            ),
                          ),
                          Text(
                            item.name,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.black87 : AppColors.textMuted,
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
    );
  }
}
