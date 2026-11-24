import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../providers/theme_provider.dart';

/// Complete Coptic Orthodox Church History & Ecumenical Councils («تاريخ الكنيسة والمجامع»).
class ChurchHistoryView extends StatelessWidget {
  const ChurchHistoryView({super.key});

  static const List<Map<String, String>> _eras = [
    {
      'era': 'القرن الأول الميلادي (حوالي ٥٥ – ٦٨م)',
      'title': '١. دخول المسيحية إلى مصر على يد مارمرقس الرسول',
      'summary':
          'دخل القديس مارمرقس الإنجيلي مدينة الإسكندرية حاملاً بشارة الإنجيل، وكان أول من آمن به «إنيانوس» الإسكافي الذي صار أول أسقف بعده.\n\nأسّس مارمرقس مدرسة الإسكندرية اللاهوتية ووضع القداس الكيرلسي، ثم استُشهد في شوارع الإسكندرية عام ٦٨م ليروي بدمائه الكرازة المصرية.'
    },
    {
      'era': 'القرنان الثاني والثالث الميلاديان',
      'title': '٢. مدرسة الإسكندرية اللاهوتية العظمى',
      'summary':
          'أصبحت الإسكندرية منارة العلم والتفسير والدفاع عن الإيمان في العالم كله. تولّى إدارتها عمالقة مثل: القديس بنتينوس، إكليمندس السكندري، العلامة أوريجانوس، والقديس ديديموس الضرير الذي ابتكر الحروف البارزة للمكفوفين قبل برايل بـ ١٥٠٠ عام!'
    },
    {
      'era': '٢٨٤ – ٣١٣م (بداية التقويم القبطي)',
      'title': '٣. عصر الشهداء وتقويم الشهداء (٢٨٤م)',
      'summary':
          'شهدت الكنيسة القبطية أشرس اضطهادات الأباطرة الرومان، خاصة دقلديانوس عام ٢٨٤م، فقدمت مصر مئات الآلاف من الشهداء (مثل مارجرجس، مارمينا، أبو سيفين، القديسة دميانة، والقديس أبانوب).\n\nاعتزازاً بثباتهم، اتخذت الكنيسة القبطية عام ٢٨٤م بداية لتقويمها القبطي المسمى «تقويم الشهداء».'
    },
    {
      'era': 'القرن الرابع الميلادي',
      'title': '٤. مصر مهد الرهبنة المسيحية في العالم كله',
      'summary':
          'من صحاري مصر (البرية الشرقية، وادي النطرون، والصعيد) خرجت الرهبنة إلى العالم كله على يد:\n• القديس الأنبا بولا (أول السواح).\n• القديس الأنبا أنطونيوس الكبير (أب الرهبان ونظام التوحد).\n• القديس الأنبا باخوميوس (مؤسس نظام الشركة الديرية).\n• القديس الأنبا مقار الكبير (أب برية شهيت وادي النطرون).\n• القديس الأنبا شنودة رئيس المتوحدين.'
    },
    {
      'era': '٣٢٥م — المجمع المسكوني الأول',
      'title': '٥. مجمع نيقية المقدس والقديس أثناسيوس الرسولي',
      'summary':
          'انعقد بحضور ٣١٨ أسقفاً للرد على بدعة آريوس الذي أنكر لاهوت السيد المسيح وأزليته.\n\nبرز فيه الشماس السكندري الشاب أثناسيوس الرسولي (حامي الإيمان) وصاغ المجمع الجزء الأول من قانون الإيمان الأرثوذكسي: «إله حق من إله حق، مولود غير مخلوق، مساوٍ للآب في الجوهر».'
    },
    {
      'era': '٣٨١م — المجمع المسكوني الثاني',
      'title': '٦. مجمع القسطنطينية المقدس',
      'summary':
          'انعقد بحضور ١٥٠ أسقفاً للرد على بدعة مقدونيوس عدو الروح القدس، وبدعة أبوليناريوس.\n\nأكمل المجمع قانون الإيمان بإضافة الجزء الخاص بالروح القدس: «نعم نؤمن بالروح القدس الرب المحيي المنبثق من الآب، نسجد له ونمجده مع الآب والابن، الناطق في الأنبياء».'
    },
    {
      'era': '٤٣١م — المجمع المسكوني الثالث',
      'title': '٧. مجمع أفسس المقدس والقديس كيرلس عمود الدين',
      'summary':
          'انعقد بحضور ٢٠٠ أسقف برئاسة البابا كيرلس الأول (عمود الدين — البطريرك ٢٤) للرد على نسطور الذي فصم السيد المسيح إلى شخصين وأنكر لقب العذراء «والدة الإله — ثيؤطوكوس».\n\nأقر المجمع مقدمة قانون الإيمان («نعظمك يا أم النور الحقيقي») وأكد وحدة شخص وطبيعة السيد المسيح الكلمة المتجسد.'
    },
    {
      'era': '٤٥١م — موقف الكنيسة القبطية التاريخي',
      'title': '٨. مجمع خلقيدونية وثبات البابا ديسقوروس',
      'summary':
          'تمسّكت الكنيسة القبطية الأرثوذكسية بقيادة البابا ديسقوروس بصيغة القديس كيرلس الكبير الدقيقة: «طبيعة واحدة لله الكلمة المتجسد» (ميافيزيت — بغير اختلاط ولا امتزاج ولا تغيير)، رافضة «طومس لاون» الذي بدا يميل للفصل النسطوري.\n\nتعرض البابا ديسقوروس للنفي في جزيرة غنغرا، وبقيت الكنائس الأرثوذكسية الشرقية (القبطية، السريانية، الأرمنية، الإثيوبية، الإريترية، والهندية) متحدة في نفس الإيمان الرسولي، وتوصلت الحوارات اللاهوتية المعاصرة إلى أن الخلاف كان لفظياً في معظمه.'
    },
    {
      'era': 'القرن العاشر — معجزة جبل المقطم',
      'title': '٩. البابا إبرآم بن زرعة والقديس سمعان الخراز',
      'summary':
          'في عهد الخليفة المعز لدين الله الفاطمي، صامت الكنيسة القبطية ثلاثة أيام متواصلة وتحققت معجزة نقل جبل المقطم بإيمان القديس سمعان الخراز والبابا إبرآم بن زرعة، ومنذ ذلك الحين أُضيف صوم ثلاثة أيام إكراماً لعمل الله العجيب.'
    },
    {
      'era': 'القرنان العشرون والحادي والعشرون',
      'title': '١٠. النهضة القبطية المعاصرة ومدارس الأحد',
      'summary':
          'أشعل القديس الأرشيدياكون حبيب جرجس نهضة التعليم الكنسي وتأسيس مدارس الأحد والكلية الإكليريكية.\n\nوتواصلت النهضة الروحية واللاهوتية والعمرانية وانتشار الكرازة القبطية في قارات العالم الخمس في عهد القديس البابا كيرلس السادس (رجل الصلاة والمعجزات)، ومثلث الرحمات قداسة البابا شنودة الثالث (معلم الأجيال)، وقداسة البابا تواضروس الثاني.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fontScale = context.watch<ThemeProvider>().fontScale;

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
              'تاريخ الكنيسة والمجامع',
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: p.ink,
                height: 1.15,
              ),
            ),
            Text(
              'من مارمرقس الرسول ومدرسة الإسكندرية حتى النهضة المعاصرة',
              style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            itemCount: _eras.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, idx) {
              final item = _eras[idx];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.goldSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.goldBorder),
                      ),
                      child: Text(
                        item['era']!,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: p.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CopticCross(size: 14, color: p.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['title']!,
                            style: GoogleFonts.amiri(
                              fontSize: 20 * fontScale.clamp(0.85, 1.3),
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      item['summary']!,
                      style: GoogleFonts.cairo(
                        fontSize: 13.8 * fontScale,
                        height: 1.75,
                        color: p.inkSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
