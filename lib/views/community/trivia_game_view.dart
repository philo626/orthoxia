import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trivia_provider.dart';

class TriviaGameView extends StatelessWidget {
  const TriviaGameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TriviaProvider>(
      builder: (context, triviaProv, _) {
        final q = triviaProv.currentQuestion;
        final tier = triviaProv.currentTier;
        final nextTier = triviaProv.nextTier;

        if (q == null) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
        }

        const arabicLetters = ['أ', 'ب', 'ج', 'د'];

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Ornate Rank, XP Bar, Coins & Streak Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3A121C), Color(0xFF0E1525)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.55), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGold.withValues(alpha: 0.12),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Rank Badge + Title
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.4),
                                    border: Border.all(color: AppColors.primaryGold, width: 1.5),
                                  ),
                                  child: Center(
                                    child: Text(tier.badge, style: const TextStyle(fontSize: 24)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tier.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGoldLight,
                                        ),
                                      ),
                                      Text(
                                        'الرصيد: ${triviaProv.score} XP • إجاباتك: ${triviaProv.totalAnswered}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 11.5,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Coins + Streak Badges
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.monetization_on_rounded,
                                        color: AppColors.primaryGold, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${triviaProv.coins}',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGoldLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_fire_department_rounded,
                                        color: Colors.orangeAccent, size: 16),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${triviaProv.streak}',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orangeAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // XP Progress Bar to Next Rank
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                nextTier != null
                                    ? 'الرتبة القادمة: ${nextTier.name}'
                                    : 'وصلت إلى أعلى رتبة كنسية مباركة!',
                                style: GoogleFonts.cairo(fontSize: 11, color: AppColors.primaryGoldLight),
                              ),
                              if (nextTier != null)
                                Text(
                                  '${triviaProv.score} / ${nextTier.minScore} XP',
                                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: triviaProv.tierProgress,
                              minHeight: 7,
                              backgroundColor: Colors.black38,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2. Game Mode Selector Chips (Infinite Modes)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: TriviaGameMode.values.map((mode) {
                      final selected = triviaProv.activeMode == mode;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(
                            mode.label,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.black : AppColors.textLight,
                            ),
                          ),
                          selected: selected,
                          selectedColor: AppColors.primaryGold,
                          backgroundColor: AppColors.cardNavy,
                          side: BorderSide(
                            color: selected
                                ? AppColors.primaryGold
                                : AppColors.primaryGold.withValues(alpha: 0.3),
                          ),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            triviaProv.setGameMode(mode);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Ornate Gilded Question Card
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey(q.id),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101726),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primaryGold.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                q.category,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGoldLight,
                                ),
                              ),
                            ),
                            Text(
                              'السؤال #${triviaProv.questionNumber}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          q.question,
                          style: GoogleFonts.amiri(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Hint Box if revealed before answering
                        if (triviaProv.hintRevealed && !triviaProv.isAnswered) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'تلميح آبائي: ${q.explanation}',
                                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.amberAccent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Answer Options (أ، ب، ج، د)
                        for (int i = 0; i < q.options.length; i++) ...[
                          if (!triviaProv.hiddenOptions.contains(i)) ...[
                            _buildOptionTile(
                              index: i,
                              letter: arabicLetters[i % arabicLetters.length],
                              text: q.options[i],
                              correctIndex: q.correctIndex,
                              selectedIndex: triviaProv.selectedAnswerIndex,
                              isAnswered: triviaProv.isAnswered,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                triviaProv.selectAnswer(i);
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],

                        const SizedBox(height: 8),

                        // Lifelines Row (50/50, Patristic Hint, Skip)
                        if (!triviaProv.isAnswered)
                          Row(
                            children: [
                              Expanded(
                                child: _buildLifelineButton(
                                  icon: Icons.filter_2_rounded,
                                  label: 'حذف إجابتين (١٥)',
                                  enabled: triviaProv.hiddenOptions.isEmpty && triviaProv.coins >= 15,
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    triviaProv.useFiftyFifty();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildLifelineButton(
                                  icon: Icons.lightbulb_outline_rounded,
                                  label: 'تلميح (١٠)',
                                  enabled: !triviaProv.hintRevealed && triviaProv.coins >= 10,
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    triviaProv.useHint();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildLifelineButton(
                                  icon: Icons.skip_next_rounded,
                                  label: 'تخطي (١٠)',
                                  enabled: triviaProv.coins >= 10,
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    triviaProv.skipQuestion();
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Explanation & Next Infinite Question Button
                if (triviaProv.isAnswered) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceNavy,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_stories_rounded,
                                color: AppColors.primaryGold, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'إضاءة آبائية وكتابية:',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.explanation,
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            color: AppColors.textLight.withValues(alpha: 0.95),
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      triviaProv.nextQuestion();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.bolt_rounded),
                    label: Text(
                      'السؤال اللانهائي التالي',
                      style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLifelineButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF172136),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryGold, size: 18),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGoldLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required int index,
    required String letter,
    required String text,
    required int correctIndex,
    required int? selectedIndex,
    required bool isAnswered,
    required VoidCallback onTap,
  }) {
    Color borderColor = AppColors.primaryGold.withValues(alpha: 0.25);
    Color bgColor = const Color(0xFF161F33);
    Color textColor = AppColors.textLight;

    if (isAnswered) {
      if (index == correctIndex) {
        borderColor = AppColors.successGreen;
        bgColor = AppColors.successGreen.withValues(alpha: 0.22);
        textColor = AppColors.successGreen;
      } else if (index == selectedIndex) {
        borderColor = Colors.redAccent;
        bgColor = Colors.redAccent.withValues(alpha: 0.22);
        textColor = Colors.redAccent;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black26,
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            if (isAnswered && index == correctIndex)
              const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 20),
            if (isAnswered && index == selectedIndex && index != correctIndex)
              const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20),
          ],
        ),
      ),
    );
  }
}
