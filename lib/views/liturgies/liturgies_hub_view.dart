import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../models/liturgy_model.dart';
import '../../providers/liturgy_provider.dart';
import 'liturgy_reader_view.dart';

class LiturgiesHubView extends StatefulWidget {
  const LiturgiesHubView({super.key});

  @override
  State<LiturgiesHubView> createState() => _LiturgiesHubViewState();
}

class _LiturgiesHubViewState extends State<LiturgiesHubView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiturgyProvider>().loadLiturgies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final liturgyProvider = context.watch<LiturgyProvider>();
    final liturgies = liturgyProvider.liturgies;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'القداسات الإلهية الأرثوذكسية',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: liturgyProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero liturgical banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.burgundy,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.church, size: 48, color: AppColors.gold),
                        const SizedBox(height: 12),
                        const Text(
                          'سر التناول والإفخارستيا المقدسة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'نصوص القداسات الإلهية الثلاثة المعتمدة في الكنيسة القبطية، بنظام تقسيم الأدوار (الكاهن، الشماس، الشعب) وباللغات الثلاث (قبطي، معرب، عربي).',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: AppColors.cream.withValues(alpha: 0.9),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),
                  const Text(
                    'اختر القداس الإلهي:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (liturgies.isEmpty)
                    const Center(child: Text('جاري تحميل بيانات القداسات...'))
                  else
                    ...liturgies.map((liturgy) => _buildLiturgyCard(context, liturgy)),
                ],
              ),
            ),
    );
  }

  Widget _buildLiturgyCard(BuildContext context, Liturgy liturgy) {
    Color accentColor;
    IconData icon;
    if (liturgy.type == 'basil') {
      accentColor = AppColors.gold;
      icon = Icons.auto_awesome;
    } else if (liturgy.type == 'gregory') {
      accentColor = const Color(0xFFE57373);
      icon = Icons.favorite;
    } else {
      accentColor = const Color(0xFF64B5F6);
      icon = Icons.shield;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.black.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {
          context.read<LiturgyProvider>().selectLiturgy(liturgy);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LiturgyReaderView(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liturgy.title,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${liturgy.sections.length} أقسام ليتورجية رئيسية',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                liturgy.description,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.cream,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}
