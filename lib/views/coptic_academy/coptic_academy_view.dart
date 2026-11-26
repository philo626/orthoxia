import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../core/widgets/sacred_section_banner.dart';

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

class CopticFlashcardItem {
  final String coptic;
  final String arabized;
  final String meaning;
  final String liturgicalUsage;

  const CopticFlashcardItem({
    required this.coptic,
    required this.arabized,
    required this.meaning,
    required this.liturgicalUsage,
  });
}

/// Handcrafted Coptic Language Academy («أكاديمية اللغة القبطية»):
/// - Pure written Bahairi Coptic alphabet rules (32 letters) with exact Arabized examples
/// - ZERO synthesized TTS audio (prevents mispronunciation confusion!)
/// - Adaptive Warm Parchment / Charcoal editorial design with illuminated manuscript header
class CopticAcademyView extends StatefulWidget {
  const CopticAcademyView({super.key});

  static const List<CopticLetterInfo> alphabet = [
    CopticLetterInfo(symbol: 'Ⲁ ⲁ', name: 'ألفا', sound: 'آ / ا', rule: 'يُنطق دائماً مثل الألف الممدودة المفتوحة (ا).', exampleCoptic: 'Ⲁⲅⲁⲡⲏ', exampleArabized: 'أغابي', exampleMeaning: 'محبة'),
    CopticLetterInfo(symbol: 'Ⲃ ⲃ', name: 'فيتا', sound: 'ف / ب', rule: 'يُنطق (ف) إذا جاء بعده حرف متحرك، ويُنطق (ب) في آخر الكلمة أو قبل السواكن.', exampleCoptic: 'Ⲃⲏⲑⲗⲉⲉⲙ', exampleArabized: 'فيثلئيم', exampleMeaning: 'بيت لحم'),
    CopticLetterInfo(symbol: 'Ⲅ ⲅ', name: 'غاما', sound: 'ج / غ / ن', rule: 'يُنطق (ج صلبة) قبل الكسرات (ⲉ, ⲏ, ⲓ, ⲩ)، و(ن) قبل الحروف الحلقية، و(غ) فيما عدا ذلك.', exampleCoptic: 'Ⲁⲅⲓⲟⲥ', exampleArabized: 'أجيوس', exampleMeaning: 'قدوس'),
    CopticLetterInfo(symbol: 'Ⲇ ⲇ', name: 'دلتا', sound: 'د / ذ', rule: 'يُنطق (د) في الأسماء الأعلام، و(ذ) في الكلمات القبطية واليونانية العادية.', exampleCoptic: 'Ⲇⲁⲩⲓⲇ', exampleArabized: 'دافيد', exampleMeaning: 'داود'),
    CopticLetterInfo(symbol: 'Ⲉ ⲉ', name: 'إي', sound: 'إِ خفيفة', rule: 'حرف متحرك للكسر الخفيف مثل (إِ).', exampleCoptic: 'Ⲉ̀ⲕⲕⲗⲏⲥⲓⲁ', exampleArabized: 'إكليسيا', exampleMeaning: 'كنيسة'),
    CopticLetterInfo(symbol: 'Ⲋ ⲋ', name: 'سو', sound: 'رقم ستة', rule: 'يُستخدم كرقم (٦) في حساب الأبجدية القبطية وأرباع التسبحة.', exampleCoptic: 'ⲋ̅', exampleArabized: 'سو', exampleMeaning: 'العدد ستة'),
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
    CopticLetterInfo(symbol: 'Ⲡ ⲡ', name: 'بي', sound: 'ب ثقيلة', rule: 'يُنطق دائماً مثل حرف الباء (ب).', exampleCoptic: 'Ⲡⲁⲧⲏⲣ', exampleArabized: 'باتير', exampleMeaning: 'آب'),
    CopticLetterInfo(symbol: 'Ⲣ ⲣ', name: 'رو', sound: 'ر', rule: 'يُنطق دائماً مثل حرف الراء (ر).', exampleCoptic: 'Ⲣⲁϣⲓ', exampleArabized: 'راشي', exampleMeaning: 'فرح'),
    CopticLetterInfo(symbol: 'Ⲥ ⲥ', name: 'سيما', sound: 'س / ز', rule: 'يُنطق (س)، ويُنطق (ز) في الكلمات اليونانية إذا وقع بين حرفين متحركين.', exampleCoptic: 'Ⲥⲱⲧⲏⲣ', exampleArabized: 'سوتير', exampleMeaning: 'مخلص'),
    CopticLetterInfo(symbol: 'Ⲧ ⲧ', name: 'تاف', sound: 'ت / د / ط', rule: 'يُنطق (د) بعد (ⲛ)، و(ط) مع الحروف المفخمة، و(ت) فيما عدا ذلك.', exampleCoptic: 'Ⲧ̀ⲣⲓⲁⲥ', exampleArabized: 'إترياس', exampleMeaning: 'الثالوث'),
    CopticLetterInfo(symbol: 'Ⲩ ⲩ', name: 'إبسلون', sound: 'ف / و / ي', rule: 'يُنطق (ف) بعد (ⲁ, ⲉ)، و(أو) بعد (ⲟ)، و(ي) فيما عدا ذلك.', exampleCoptic: 'Ⲉⲩⲁⲅⲅⲉⲗⲓⲟⲛ', exampleArabized: 'إيف أنجيليون', exampleMeaning: 'الإنجيل (البشارة)'),
    CopticLetterInfo(symbol: 'Ⲫ ⲫ', name: 'في', sound: 'ف', rule: 'يُنطق دائماً مثل حرف الفاء (ف).', exampleCoptic: 'Ⲫ̀ⲛⲟⲩϯ', exampleArabized: 'إفنوتي', exampleMeaning: 'الله'),
    CopticLetterInfo(symbol: 'Ⲭ ⲭ', name: 'كي', sound: 'ك / ش / خ', rule: 'يُنطق (ك) في الكلمات القبطية، وفي اليونانية يُنطق (ش) قبل الكسر و(خ) قبل غيره.', exampleCoptic: 'Ⲡⲓⲭ̀ⲣⲓⲥⲧⲟⲥ', exampleArabized: 'بي إخريستوس', exampleMeaning: 'المسيح'),
    CopticLetterInfo(symbol: 'Ⲯ ⲯ', name: 'إبسي', sound: 'بس', rule: 'حرف مزدوج يُنطق (ب + س) معاً.', exampleCoptic: 'Ⲯⲁⲗⲙⲟⲥ', exampleArabized: 'إبسالموس', exampleMeaning: 'مزمور'),
    CopticLetterInfo(symbol: 'Ⲱ ⲱ', name: 'أوميجا', sound: 'أو طويلة', rule: 'حرف متحرك للضم الطويل الممدود (واو مد: أو).', exampleCoptic: 'Ⲱ̀ⲥⲁⲛⲛⲁ', exampleArabized: 'أوصنا', exampleMeaning: 'خلصنا (أوصنا)'),
    CopticLetterInfo(symbol: 'Ϣ ϣ', name: 'شاي', sound: 'ش', rule: 'حرف قبطي أصيل من الديموطيقية يُنطق دائماً (ش).', exampleCoptic: 'Ϣⲏⲣⲓ', exampleArabized: 'شيري', exampleMeaning: 'ابن'),
    CopticLetterInfo(symbol: 'Ϥ ϥ', name: 'فاي', sound: 'ف', rule: 'حرف قبطي أصيل يُنطق دائماً (ف).', exampleCoptic: 'Ϥⲁⲓ', exampleArabized: 'فاي', exampleMeaning: 'هذا / حامل'),
    CopticLetterInfo(symbol: 'Ϧ ϧ', name: 'خاي', sound: 'خ', rule: 'حرف قبطي أصيل يُنطق دائماً مثل الخاء العربية (خ).', exampleCoptic: 'Ϧⲉⲛ', exampleArabized: 'خين', exampleMeaning: 'في / باسم'),
    CopticLetterInfo(symbol: 'Ϩ ϩ', name: 'هوري', sound: 'هـ', rule: 'حرف قبطي أصيل يُنطق دائماً مثل الهاء (هـ).', exampleCoptic: 'Ϩⲓⲣⲏⲛⲏ', exampleArabized: 'هيريني', exampleMeaning: 'سلام'),
    CopticLetterInfo(symbol: 'Ϫ ϫ', name: 'جنجا', sound: 'ج / چ', rule: 'يُنطق (چ تعطيش) قبل حروف الكسر، و(ج قاهرية صلبة) قبل غيرها.', exampleCoptic: 'Ⲡ̀ϭⲟⲓⲥ', exampleArabized: 'إبشويس', exampleMeaning: 'الرب / السيد'),
    CopticLetterInfo(symbol: 'Ϭ ϭ', name: 'تشيما', sound: 'تش', rule: 'حرف قبطي أصيل يُنطق دائماً (تش).', exampleCoptic: 'Ⲡⲁϭⲟⲓⲥ', exampleArabized: 'باشويس', exampleMeaning: 'سيدي / ربي'),
    CopticLetterInfo(symbol: 'Ϯ ϯ', name: 'تي', sound: 'تي', rule: 'مقطع كامل يُنطق (ت + ي = تي)، ويعني أيضاً «يعطي» أو أداة تعريف مؤنثة.', exampleCoptic: 'Ϯϣⲟⲩⲣⲏ', exampleArabized: 'تي شوري', exampleMeaning: 'المجمرة'),
  ];

  static const List<CopticFlashcardItem> flashcards = [
    CopticFlashcardItem(coptic: 'Ⲫ̀ⲛⲟⲩϯ', arabized: 'إفنوتي', meaning: 'الله', liturgicalUsage: 'تتكرر في صلاة الشكر وأرباع الناقوس'),
    CopticFlashcardItem(coptic: 'Ⲡ̀ϭⲟⲓⲥ', arabized: 'إبشويس', meaning: 'الرب / السيد', liturgicalUsage: 'تتكرر في المزامير والأواشي (آري إفميفئي إبشويس)'),
    CopticFlashcardItem(coptic: 'Ⲡⲓⲭ̀ⲣⲓⲥⲧⲟⲥ', arabized: 'بي إخريستوس', meaning: 'المسيح', liturgicalUsage: 'إخرستوس آنستي (المسيح قام)'),
    CopticFlashcardItem(coptic: 'Ϣ̀ⲗⲏⲗ', arabized: 'إشليل', meaning: 'صلِّ / للصلاة', liturgicalUsage: 'نداء الكاهن قبل كل أوشية وصلاة في القداس'),
    CopticFlashcardItem(coptic: 'Ⲓⲣⲏⲛⲏ ⲡⲁⲥⲓ', arabized: 'إيريني باسي', meaning: 'السلام لجميعكم', liturgicalUsage: 'بركة السلام التي يمنحها الكاهن للشعب'),
    CopticFlashcardItem(coptic: 'Ⲕⲉ ⲧⲱ ⲡ̀ⲛⲉⲩⲙⲁⲧⲓ ⲥⲟⲩ', arabized: 'كي طو إبنيفماتي سو', meaning: 'ولروحك أيضاً', liturgicalUsage: 'مرد الشعب على الكاهن بعد إيريني باسي'),
    CopticFlashcardItem(coptic: 'Ⲙⲁⲣⲉⲛϣⲉⲡϩ̀ⲙⲟⲧ', arabized: 'مارين شيب إهموت', meaning: 'فلنشكر', liturgicalUsage: 'بداية صلاة الشكر في القداس ورفع البخور'),
    CopticFlashcardItem(coptic: 'Ⲧⲉⲛⲟⲩⲱϣⲧ', arabized: 'تين أوأوشت', meaning: 'نسجد', liturgicalUsage: 'لحن البركة (نسجد لآب النور) وأرباع الناقوس'),
    CopticFlashcardItem(coptic: 'Ⲁ̀ⲅⲓⲟⲥ ⲟ̀ Ⲑⲉⲟⲥ', arabized: 'أجيوس أو ثيؤس', meaning: 'قدوس الله', liturgicalUsage: 'لحن الثلاث تقديسات قبل أوشية الإنجيل'),
    CopticFlashcardItem(coptic: 'Ⲕⲩⲣⲓⲉ ⲉ̀ⲗⲉⲏ̀ⲥⲟⲛ', arabized: 'كيرياليسون', meaning: 'يا رب ارحم', liturgicalUsage: 'أشهر مرد في الكنيسة القبطية في كل الصلوات'),
    CopticFlashcardItem(coptic: 'Ⲡ̀ⲟⲩⲣⲟ', arabized: 'إبؤرو', meaning: 'يا ملك (السلام)', liturgicalUsage: 'لحن إبؤرو الفرايحي ومردات الأعياد'),
    CopticFlashcardItem(coptic: 'Ⲭⲉⲣⲉ Ⲙⲁⲣⲓⲁ', arabized: 'شيري ماريا', meaning: 'السلام لكِ يا مريم', liturgicalUsage: 'الهيتينيات وتسبحة كيهك والثيؤطوكيات'),
    CopticFlashcardItem(coptic: 'Ⲑⲉⲟ̀ⲧⲟⲕⲟⲥ', arabized: 'ثيؤطوكوس', meaning: 'والدة الإله', liturgicalUsage: 'لقب السيدة العذراء مريم العقيدي'),
    CopticFlashcardItem(coptic: 'Ⲉ̀ⲕⲕⲗⲏⲥⲓⲁ', arabized: 'إكليسيا', meaning: 'الكنيسة', liturgicalUsage: 'أوشية سلام الكنيسة الواحدة الوحيدة المقدسة'),
    CopticFlashcardItem(coptic: 'Ⲥ̀ⲙⲟⲩ ⲉ̀ⲣⲟϥ', arabized: 'إسمو إيروف', meaning: 'سبحوه / باركوه', liturgicalUsage: 'الهوس الثالث والمزمور ١٥٠ في التوزيع'),
    CopticFlashcardItem(coptic: 'Ⲁ̀ⲝⲓⲟⲥ', arabized: 'أكسيوس', meaning: 'مستحق', liturgicalUsage: 'تُرتل للآباء البطاركة والأساقفة والقديسين'),
  ];

  @override
  State<CopticAcademyView> createState() => _CopticAcademyViewState();
}

class _CopticAcademyViewState extends State<CopticAcademyView> {
  int _activeTab = 0; // 0: الأبجدية الـ 32, 1: بطاقات الكلمات, 2: اختبار سريع
  int _selectedLetterIdx = 0;

  // Flashcards state
  int _flashcardIdx = 0;
  bool _flashcardFlipped = false;

  // Mini Quiz state
  int _quizIdx = 0;
  int _quizScore = 0;
  int? _selectedOptionIdx;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final letter = CopticAcademyView.alphabet[_selectedLetterIdx];

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        elevation: 0,
        title: Text(
          'أكاديمية اللغة القبطية',
          style: GoogleFonts.amiri(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: p.ink,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              // Handcrafted Illuminated Manuscript Banner
              const SacredSectionBanner(
                imageAsset: 'assets/images/banner_coptic_academy.jpg',
                title: 'الأبجدية القبطية البحيرية',
                subtitle: '٣٢ حرفاً بقواعد النطق الدقيقة وأشهر كلمات القداس',
                badge: 'تراث الكنيسة القبطية',
                height: 112,
                margin: EdgeInsets.fromLTRB(16, 4, 16, 10),
              ),

              // 3 Interactive Tabs Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  children: [
                    _buildTabChip(p, 0, 'الأبجدية (٣٢ حرفاً)'),
                    const SizedBox(width: 6),
                    _buildTabChip(p, 1, 'بطاقات الكلمات'),
                    const SizedBox(width: 6),
                    _buildTabChip(p, 2, 'اختبار سريع'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: _activeTab == 0
                    ? _buildAlphabetTab(p, letter)
                    : (_activeTab == 1 ? _buildFlashcardsTab(p) : _buildQuizTab(p)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabChip(AppPalette p, int idx, String label) {
    final sel = _activeTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeTab = idx);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? p.accent : p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? p.accent : p.border),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: sel ? p.onAccent : p.ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlphabetTab(AppPalette p, CopticLetterInfo letter) {
    return Column(
      children: [
        // Active Letter Rule Showcase Card (Pure written rules — zero synthetic TTS)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.goldBorder, width: 1.3),
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
            children: [
              Row(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.goldSoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: p.goldBorder),
                    ),
                    child: Text(
                      letter.symbol,
                      style: TextStyle(
                        fontFamily: 'Coptic',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: p.isDark ? p.gold : p.accent,
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
                              style: GoogleFonts.amiri(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: p.ink,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: p.accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'النطق: ${letter.sound}',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: p.onAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          letter.rule,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: p.inkSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('الكلمة بالقبطي',
                          style: GoogleFonts.cairo(fontSize: 10.5, color: p.inkMuted)),
                      const SizedBox(height: 2),
                      Text(
                        letter.exampleCoptic,
                        style: TextStyle(
                          fontFamily: 'Coptic',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: p.isDark ? p.gold : p.accent,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text('النطق المعرّب',
                          style: GoogleFonts.cairo(fontSize: 10.5, color: p.crimson)),
                      const SizedBox(height: 2),
                      Text(
                        letter.exampleArabized,
                        style: GoogleFonts.cairo(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: p.crimson,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text('المعنى العربي',
                          style: GoogleFonts.cairo(fontSize: 10.5, color: p.inkMuted)),
                      const SizedBox(height: 2),
                      Text(
                        letter.exampleMeaning,
                        style: GoogleFonts.cairo(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ).animate(key: ValueKey(_selectedLetterIdx)).fadeIn(duration: 200.ms),

        // 32 Coptic Letters Clean Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.04,
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
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: sel ? p.accent : p.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? p.accent : p.border,
                      width: sel ? 1.5 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.symbol,
                          style: TextStyle(
                            fontFamily: 'Coptic',
                            fontSize: 18.5,
                            fontWeight: FontWeight.bold,
                            color: sel ? p.onAccent : (p.isDark ? p.gold : p.accent),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.name,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: sel ? p.onAccent : p.ink,
                          ),
                        ),
                        Text(
                          item.sound,
                          style: GoogleFonts.cairo(
                            fontSize: 9.5,
                            color: sel ? p.onAccent.withValues(alpha: 0.85) : p.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFlashcardsTab(AppPalette p) {
    final cards = CopticAcademyView.flashcards;
    final card = cards[_flashcardIdx % cards.length];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'بطاقة ${_flashcardIdx + 1} من ${cards.length} • اضغط على البطاقة لإظهار المعنى',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _flashcardFlipped = !_flashcardFlipped);
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: p.goldBorder, width: 1.5),
                  boxShadow: p.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: p.shadow,
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.goldSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: p.goldBorder),
                      ),
                      child: Text(
                        _flashcardFlipped ? 'المعنى والاستخدام الطقسي' : 'الكلمة القبطية ونطقها',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: p.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      card.coptic,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Coptic',
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: p.isDark ? p.gold : p.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'النطق المعرّب: ${card.arabized}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: p.crimson,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_flashcardFlipped)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: p.surfaceSubtle,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: p.border),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'المعنى: «${card.meaning}»',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.amiri(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: p.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'في القداس: ${card.liturgicalUsage}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 12.5,
                                color: p.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'اضغط هنا لكشف المعنى والاستخدام في القداس',
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: p.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _flashcardIdx = (_flashcardIdx - 1 + cards.length) % cards.length;
                    _flashcardFlipped = false;
                  });
                },
                icon: Icon(Icons.arrow_back_rounded, size: 16, color: p.accent),
                label: Text('السابقة', style: GoogleFonts.cairo(color: p.ink)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _flashcardIdx = (_flashcardIdx + 1) % cards.length;
                    _flashcardFlipped = false;
                  });
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text('الكلمة التالية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizTab(AppPalette p) {
    final cards = CopticAcademyView.flashcards;
    final current = cards[_quizIdx % cards.length];
    final options = <CopticFlashcardItem>[
      current,
      cards[(_quizIdx + 3) % cards.length],
      cards[(_quizIdx + 7) % cards.length],
      cards[(_quizIdx + 11) % cards.length],
    ];
    final shift = _quizIdx % 4;
    final rotated = [
      ...options.sublist(shift),
      ...options.sublist(0, shift),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'السؤال ${_quizIdx + 1}',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: p.ink,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: p.goldSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.goldBorder),
              ),
              child: Text(
                'النتيجة: $_quizScore',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: p.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.goldBorder),
          ),
          child: Column(
            children: [
              Text(
                'ما هو معنى الكلمة القبطية الكنسية التالية؟',
                style: GoogleFonts.cairo(fontSize: 13, color: p.inkSecondary),
              ),
              const SizedBox(height: 10),
              Text(
                current.coptic,
                style: TextStyle(
                  fontFamily: 'Coptic',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: p.isDark ? p.gold : p.accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '(${current.arabized})',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: p.crimson,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(rotated.length, (i) {
          final opt = rotated[i];
          final isCorrect = opt.coptic == current.coptic;
          final isPicked = _selectedOptionIdx == i;
          Color borderCol = p.border;
          Color bgCol = p.surface;
          if (_selectedOptionIdx != null) {
            if (isCorrect) {
              borderCol = p.sage;
              bgCol = p.sage.withValues(alpha: 0.14);
            } else if (isPicked) {
              borderCol = p.danger;
              bgCol = p.danger.withValues(alpha: 0.14);
            }
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _selectedOptionIdx != null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedOptionIdx = i;
                        if (isCorrect) _quizScore++;
                      });
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: bgCol,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderCol, width: 1.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      opt.meaning,
                      style: GoogleFonts.cairo(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                    if (_selectedOptionIdx != null && isCorrect)
                      Icon(Icons.check_circle_rounded, color: p.sage, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
        if (_selectedOptionIdx != null)
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _quizIdx++;
                _selectedOptionIdx = null;
              });
            },
            icon: const Icon(Icons.navigate_next_rounded),
            label: Text(
              'السؤال التالي',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
      ],
    );
  }
}
