import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../providers/ai_companion_provider.dart';
import '../../providers/theme_provider.dart';

class AiCompanionView extends StatefulWidget {
  const AiCompanionView({super.key});

  @override
  State<AiCompanionView> createState() => _AiCompanionViewState();
}

class _AiCompanionViewState extends State<AiCompanionView> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(AiCompanionProvider provider, String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    _msgCtrl.clear();
    FocusScope.of(context).unfocus();
    provider.sendMessage(text);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final fontScale = themeProv.fontScale;

    return Consumer<AiCompanionProvider>(
      builder: (context, aiProv, _) {
        return Scaffold(
          backgroundColor: AppColors.deepNavy,
          appBar: AppBar(
            backgroundColor: AppColors.deepNavy,
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryGold.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.primaryGold, width: 1.2),
                  ),
                  child: const Center(child: CopticCross(size: 20)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المساعد الآبائي الذكي (AI)',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: AppColors.primaryGoldLight,
                        ),
                      ),
                      Text(
                        'اسأل بحرية في الكتاب المقدس والطقس وتفاسير الآباء',
                        style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Chat Messages List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: aiProv.messages.length,
                    itemBuilder: (context, index) {
                      final msg = aiProv.messages[index];
                      return Align(
                        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.86,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: msg.isUser
                                ? const LinearGradient(
                                    colors: [Color(0xFF3A2B18), Color(0xFF241B10)],
                                  )
                                : AppColors.obsidianCard,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                              bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                            ),
                            border: Border.all(
                              color: msg.isUser
                                  ? AppColors.primaryGold.withValues(alpha: 0.6)
                                  : AppColors.primaryGold.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                msg.text,
                                style: GoogleFonts.cairo(
                                  fontSize: 14 * fontScale,
                                  color: AppColors.textLight,
                                  height: 1.65,
                                ),
                              ),
                              if (msg.citations != null && msg.citations!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: msg.citations!.map((c) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceNavy,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primaryGold.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.bookmark_outline_rounded,
                                            size: 11,
                                            color: AppColors.primaryGold,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              c,
                                              style: GoogleFonts.cairo(
                                                fontSize: 10,
                                                color: AppColors.primaryGoldLight,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
           
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                if (aiProv.isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryGold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'المساعد الآبائي يبحث في التفاسير وأقوال الآباء...',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Suggested Quick Prompts
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: aiProv.quickPrompts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final prompt = aiProv.quickPrompts[index];
                      return ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          prompt,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                        backgroundColor: AppColors.cardNavy,
                        side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                        onPressed: () => _sendMessage(aiProv, prompt),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Prominent Free-Text AI Input Bar (Elevated above the Bottom Navigation Bar!)
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 82),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E22),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.primaryGold.withValues(alpha: 0.55),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.65),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          textInputAction: TextInputAction.send,
                          style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 14),
                          cursorColor: AppColors.primaryGold,
                          decoration: InputDecoration(
                            hintText: 'اكتب أي سؤال في الكتاب المقدس أو الطقس أو العقيدة...',
                            hintStyle: GoogleFonts.cairo(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onSubmitted: (val) => _sendMessage(aiProv, val),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _sendMessage(aiProv, _msgCtrl.text),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.champagne,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
