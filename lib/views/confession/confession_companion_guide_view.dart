import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../conscience/conscience_exam_view.dart';

/// 100% OFFLINE Confession Spiritual Companion («رفيق التوبة والاعتراف»):
///   Tab 0: صلاة ما قبل الاعتراف (المزمور الخمسون + صلاة توبة وخشوع)
///   Tab 1: صلاة الشكر بعد الحل (صلاة شكر + مزمور ٣٢ + حفظ السلام)
///   Tab 2: أول مرة أو راجع بعد غياب طويل؟ (دليل مطمئن بالعامية المصرية الدافية)
class ConfessionCompanionGuideView extends StatelessWidget {
  final int initialTab;
  const ConfessionCompanionGuideView({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: Scaffold(
        backgroundColor: p.canvas,
        appBar: AppBar(
          backgroundColor: p.canvas,
          foregroundColor: p.ink,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'رفيق التوبة والاعتراف',
                style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 22, color: p.ink, height: 1.15),
              ),
              Text(
                'شغّال معاك أوفلاين ١٠٠٪ في الكنيسة من غير نت',
                style: GoogleFonts.cairo(fontSize: 10.5, color: p.inkMuted),
              ),
            ],
          ),
          bottom: TabBar(
            indicatorColor: p.gold,
            labelColor: p.ink,
            unselectedLabelColor: p.inkMuted,
            labelStyle: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'قبل الاعتراف'),
              Tab(text: 'بعد الحل'),
              Tab(text: 'راجع بعد غياب؟'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBeforeConfessionTab(context, p),
            _buildAfterAbsolutionTab(p),
            _buildReturningGuideTab(context, p),
          ],
        ),
      ),
    );
  }

  Widget _buildBeforeConfessionTab(BuildContext context, AppPalette p) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
          children: [
            _prayerCard(
              p,
              badge: 'صلاة قبل ما تدخل لقدس أبونا',
              title: 'يا رب افتح شفتيّ بصدق واتضاع',
              body:
                  'يا ربي وإلهي ومخلصي يسوع المسيح، ها أنا جاي قدامك بقلبي المكشوف قدامك.\n'
                  'أنت عارف ضعفي، وعارف تعبي، ومبتستنيش مني كلام مترتب — أنت مستني قلبي الصادق.\n'
                  'اديني شجاعة إني أقول كل حاجة بوضوح ومن غير خجل ولا تبرير، وبارك قدس أبونا عشان يكون صوتك الحنين ليا، واديني روح التوبة الصادقة وحلّني من كل خطية بدمك الكريم. آمين.',
            ),
            const SizedBox(height: 12),
            _prayerCard(
              p,
              badge: 'المزمور الخمسون (صلاة التوبة)',
              title: 'ارحمني يا الله كعظيم رحمتك',
              body:
                  'ارحمني يا الله كعظيم رحمتك، ومثل كثرة رأفتك تمحو إثمي.\n'
                  'تغسلني كثيراً من إثمي، ومن خطيتي تطهرني. لأني أنا عارف بإثمي، وخطيتي أمامي في كل حين.\n'
                  'لك وحدك أخطأت، والشر قدامك صنعت...\n'
                  'قلباً نقياً اخلق فيّ يا الله، وروحاً مستقيماً جدد في أحشائي.\n'
                  'لا تطرحني من قدام وجهك، وروحك القدوس لا تنزعه مني.\n'
                  'امنحني بهجة خلاصك، وبروح رئاسي عضّدني...\n'
                  'الذبيحة لله روح منسحق؛ القلب المنكسر والمتواضع لا يرذله الله. هلليلويا.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, luxeRoute(const ConscienceExamView())),
              style: OutlinedButton.styleFrom(
                foregroundColor: p.accent,
                side: BorderSide(color: p.goldBorder),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.lock_outline_rounded, size: 18),
              label: Text(
                'افتح مذكرة فحص الضمير المشفّرة تراجعها قبل ما تدخل',
                style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAfterAbsolutionTab(AppPalette p) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
          children: [
            _prayerCard(
              p,
              badge: 'صلاة الشكر بعد الحل والمصالحة',
              title: 'أشكرك يا رب على غفرانك وسلامك',
              body:
                  'أشكرك يا ربي يسوع المسيح يا محب البشر الصالح، لأنك قبلت توبتي ورفعت عني حمل خطاياي بحلّ الكهنوت المقدس.\n'
                  'أشكرك على السلام اللي مليت بيه قلبي دلوقتي. احفظني يا رب في نعمتك، واسندني إني أمشي في التدريب اللي قدس أبونا ادهولي، ومسمحش لعدو الخير يرجّعني تاني للي سبته ورا ضهري.\n'
                  'لك المجد والشكر إلى الأبد. آمين.',
            ),
            const SizedBox(height: 12),
            _prayerCard(
              p,
              badge: 'المزمور الثاني والثلاثون',
              title: 'طوبى للذي غُفر إثمه وسُترت خطيته',
              body:
                  'طوبى للذي غُفر إثمه وسُترت خطيته. طوبى لرجل لا يحسب له الرب خطية، ولا في روحه غش.\n'
                  'أعترف لك بخطيتي ولا أكتم إثمي. قلت أعترف للرب بذنبي، وأنت رفعت آثام خطيتي.\n'
                  'أنت ستر لي. من الضيق تحفظني. بترنم النجاة تكتنفني.\n'
                  'افرحوا بالرب وابتهجوا يا أيها الصديقون، واهتفوا يا جميع المستقيمي القلوب.',
            ),
            const SizedBox(height: 12),
            _tipBox(
              p,
              '٣ نصايح دهبية بعد ما تطلع من عند أبونا:',
              '١) اقعد ٥ دقايق هادية في الكنيسة اشكر ربنا وافتكر إن صفحتك دلوقتي بيضا تماماً.\n'
              '٢) سجّل التدريب البسيط اللي أبونا قالك عليه وابدأ فيه النهاردة.\n'
              '٣) استعد للتناول في أقرب قداس — التناول هو القوة اللي هتثبّت توبتك!',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturningGuideTab(BuildContext context, AppPalette p) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B1C12), Color(0xFF1A120D)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5C175).withValues(alpha: 0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CopticCross(size: 20, color: Color(0xFFF3D591)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'بقالي كتير معترفتش ومكسوف أروح.. أعمل إيه؟',
                          style: GoogleFonts.amiri(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFDF5E6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أولاً: افرح! مجرد إنك فتحت الصفحة دي معناها إن ربنا بيندهلك وحنين عليك أوي. السما كلها بتفرح بخاطي واحد بيتوب أكتر من ٩٩ بار!',
                    style: GoogleFonts.cairo(fontSize: 12.5, color: const Color(0xFFE4D3B5), height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _tipBox(
              p,
              '١) أبونا أب حنين مش قاضي ولا هيزعّلك!',
              'أبونا سمع آلاف الاعترافات قبل كده ومفيش خطية بتصدمه. هو مش جاي يحكم عليك؛ هو دكتور روحي بيفرح جداً لما يشوف ابن راجع لحضن المسيح حتى لو بعد ١٠ سنين.',
            ),
            const SizedBox(height: 10),
            _tipBox(
              p,
              '٢) أبدأ الكلام بإيه أول ما أقعد قدامه؟',
              'بكل بساطة وبمنتهى الصراحة قولّه الجملة دي بس:\n«سلام ونعمة يا أبونا.. أنا بقالي فترة طويلة معترفتش وعايز أرجع لربنا ومش عارف أبدأ منين، ممكن قدسك تساعدني؟»\nصدقني أول ما تقول الجملة دي كل التوتر هيروح وهتحس براحة عمرك ما حسيت بيها!',
            ),
            const SizedBox(height: 10),
            _tipBox(
              p,
              '٣) مش لازم تفاصيل محرجة — قول العنوان بس بصدق',
              'الاعتراف مش قصة طويلة بتفاصيل؛ بتقول اسم الخطية بوضوح ومن غير لف ولا تبرير (مثلاً: ضعفت في كذا، زعلت فلان، قصّرت في صلاتي). ولو خايف تنسى، اكتب عناوين صغيرة في «فحص الضمير» المشفّر واقرأ منها قدام أبونا عادي جداً!',
            ),
            const SizedBox(height: 10),
            _tipBox(
              p,
              '٤) لو حاسس إنك مش مستحق؟',
              'مفيش ولا واحد فينا مستحق! المستشفى اتعملت للمرضى مش للأصحاء، وسر الاعتراف اتعمل مخصوص لينا وإحنا ضعاف عشان نرجع أقوى بنعمة المسيح.',
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, luxeRoute(const ConscienceExamView())),
              style: ElevatedButton.styleFrom(
                backgroundColor: p.gold,
                foregroundColor: const Color(0xFF19130A),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: Text(
                'يلا أجهّز نفسي بهدوء في «فحص الضمير»',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prayerCard(
    AppPalette p, {
    required String badge,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.goldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: p.goldSoft, borderRadius: BorderRadius.circular(10)),
            child: Text(
              badge,
              style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: p.gold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.bold, color: p.ink),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.amiri(fontSize: 17.5, color: p.inkSecondary, height: 1.85),
          ),
        ],
      ),
    );
  }

  Widget _tipBox(AppPalette p, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold, color: p.ink),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: GoogleFonts.cairo(fontSize: 12.2, color: p.inkSecondary, height: 1.65),
          ),
        ],
      ),
    );
  }
}
