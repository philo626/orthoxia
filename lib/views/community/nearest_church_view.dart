import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/coptic_cross.dart';

class NearestChurchView extends StatelessWidget {
  const NearestChurchView({super.key});

  static const List<Map<String, String>> _featuredChurches = [
    {
      'name': 'الكاتدرائية المرقسية الكبرى بالعباسية',
      'city': 'القاهرة',
      'schedule': 'القداسات يومياً من ٦:٣٠ ص • عشية وتسبحة مساء السبت',
      'query': 'الكاتدرائية المرقسية الكبرى بالعباسية القاهرة',
    },
    {
      'name': 'الكاتدرائية المرقسية بمحطة الرمل',
      'city': 'الإسكندرية',
      'schedule': 'القداسات يومياً ٧:٠٠ ص • مزار القديس مارمرقس الرسول',
      'query': 'الكاتدرائية المرقسية محطة الرمل الإسكندرية',
    },
    {
      'name': 'دير الشهيد العظيم مارمينا العجايبي',
      'city': 'مريوط - الإسكندرية',
      'schedule': 'مزار القديس البابا كيرلس السادس والشهيد مارمينا',
      'query': 'دير الشهيد مارمينا العجايبي بمريوط',
    },
    {
      'name': 'الكنيسة المعلقة (السيدة العذراء) - مصر القديمة',
      'city': 'القاهرة',
      'schedule': 'مجمع الأديان • قداسات الأربعاء والجمعة والأحد ٧:٠٠ ص',
      'query': 'الكنيسة المعلقة مصر القديمة القاهرة',
    },
    {
      'name': 'دير السيدة العذراء المحرق (جبل قسقام)',
      'city': 'أسيوط',
      'schedule': 'مباركة العائلة المقدسة • قداسات يومية ومزار مفتوح',
      'query': 'دير السيدة العذراء المحرق أسيوط',
    },
    {
      'name': 'أديرة وادي النطرون (الأنبا بيشوي • السريان • البراموس • أبو مقار)',
      'city': 'البحيرة - طريق مصر إسكندرية الصحراوي',
      'schedule': 'مزارات الآباء الرهبان القديسين مفتوحة طوال الأسبوع',
      'query': 'دير الأنبا بيشوي وادي النطرون',
    },
  ];

  Future<void> _openMapsSearch(String query) async {
    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        centerTitle: true,
        title: Text(
          'أقرب كنيسة قبطية ومزارات الكنيسة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          // GPS Instant Nearby Search Banner (100% Free - Zero paid API required!)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF281E12), Color(0xFF141620)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primaryGold, width: 1.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primaryGold, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ابحث عن أقرب كنيسة قبطية لموقعك الآن',
                        style: GoogleFonts.cairo(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGoldLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'سواء كنت في سفر داخل مصر أو في المهجر، بضغطة واحدة يفتح لك خرائط جوجل على أقرب كنيسة قبطية أرثوذكسية بالاتجاهات الدقيقة ومواعيدها مجاناً بالكامل.',
                  style: GoogleFonts.cairo(fontSize: 12.5, height: 1.6, color: Colors.white70),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _openMapsSearch('كنيسة قبطية أرثوذكسية قريبة مني'),
                  icon: const Icon(Icons.map_rounded, color: Colors.black),
                  label: Text(
                    'إظهار أقرب كنيسة قبطية على الخريطة (GPS)',
                    style: GoogleFonts.cairo(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          Text(
            'أبرز الكاتدرائيات والأديرة القبطية المباركة:',
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGoldLight,
            ),
          ),
          const SizedBox(height: 10),

          ..._featuredChurches.map((ch) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardNavy,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const CopticCross(size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ch['name']!,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '📍 ${ch['city']}',
                            style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.primaryGold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ch['schedule']!,
                            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () => _openMapsSearch(ch['query']!),
                              icon: const Icon(Icons.directions_rounded, size: 15, color: AppColors.primaryGold),
                              label: Text(
                                'الاتجاهات على الخريطة',
                                style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.primaryGoldLight),
                              ),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
