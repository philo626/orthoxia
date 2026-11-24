import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/ai_theology_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/blessing_poster_studio_sheet.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../providers/ai_companion_provider.dart';
import '../../providers/theme_provider.dart';

/// Organized Modern Orthodox Chatbot («المرشد الآبائي»):
/// - Zero technical/API jargon or connection badges exposed to users
/// - Multi-session chat history («محادثاتي السابقة») + 1-tap New Chat
/// - Categorized Orthodox welcome cards (العقيدة، الطقس، الكتاب، الحياة الروحية)
/// - Editorial formatted Patristic answers with Copy & Share Poster actions
class AiCompanionView extends StatefulWidget {
  const AiCompanionView({super.key});

  @override
  State<AiCompanionView> createState() => _AiCompanionViewState();
}

class _AiCompanionViewState extends State<AiCompanionView> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendPrompt(AiCompanionProvider prov, String text) {
    if (text.trim().isEmpty || prov.isLoading) return;
    HapticFeedback.lightImpact();
    _inputCtrl.clear();
    FocusScope.of(context).unfocus();
    prov.sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 140), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 160,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showChatHistorySheet(BuildContext context, AiCompanionProvider aiProv) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Consumer<AiCompanionProvider>(
        builder: (ctx, prov, _) {
          final savedSessions =
              prov.sessions.where((s) => s.messages.any((m) => m.isUser)).toList();
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.68,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: p.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.borderStrong,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'محادثاتي السابقة',
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        prov.startNewChat();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.accent,
                        foregroundColor: p.onAccent,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: Text(
                        'محادثة جديدة',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: savedSessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  size: 40, color: p.inkMuted.withValues(alpha: 0.5)),
                              const SizedBox(height: 10),
                              Text(
                                'ستُحفظ محادثاتك هنا تلقائياً لتعود إليها في أي وقت.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(fontSize: 13, color: p.inkMuted),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: savedSessions.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, idx) {
                            final session = savedSessions[idx];
                            final isSelected = session.id == prov.activeSessionId;
                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected ? p.goldSoft : p.surfaceSubtle,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? p.accent : p.border,
                                ),
                              ),
                              child: Material(
                                type: MaterialType.transparency,
                                child: ListTile(
                                  dense: true,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  leading: Icon(
                                    Icons.forum_outlined,
                                    size: 19,
                                    color: isSelected ? p.accent : p.inkMuted,
                                  ),
                                  title: Text(
                                    session.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: p.ink,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${session.messages.length} رسالة',
                                    style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete_outline_rounded,
                                        size: 18, color: p.inkMuted),
                                    onPressed: () => prov.deleteSession(session.id),
                                  ),
                                  onTap: () {
                                    prov.selectSession(session.id);
                                    Navigator.pop(ctx);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Renders a clean, structured Patristic answer adapted to AppPalette
  Widget _buildFormattedPatristicAnswer(
    AppPalette p,
    String rawText,
    double fontScale,
  ) {
    final cleaned = AiTheologyService.cleanMarkdownFormatting(rawText);
    final lines = cleaned.split('\n');
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // 1. Section Header
      final isHeader = line.startsWith('☦') || (line.endsWith(':') && line.length <= 55);
      if (isHeader) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CopticCross(size: 13, color: p.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    line.replaceFirst(RegExp(r'^☦\s*'), ''),
                    style: GoogleFonts.cairo(
                      fontSize: 14 * fontScale,
                      fontWeight: FontWeight.w700,
                      color: p.accent,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 2. Bullet or Numbered Point
      final bulletMatch = RegExp(r'^([•\-]|[٠-٩0-9]+[\.\-\)])\s*(.+)$').firstMatch(line);
      if (bulletMatch != null) {
        final marker = bulletMatch.group(1)!;
        final body = bulletMatch.group(2)!;
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: p.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 3, left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: p.goldSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    marker == '-' ? '•' : marker,
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: p.accent,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    body,
                    style: GoogleFonts.cairo(
                      fontSize: 13.5 * fontScale,
                      color: p.ink,
                      height: 1.65,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 3. Scriptural / Patristic Quote Block
      if (line.contains('«') && line.contains('»')) {
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: p.goldSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                right: BorderSide(color: p.accent, width: 3),
              ),
            ),
            child: SelectableText(
              line,
              style: GoogleFonts.amiri(
                fontSize: 17 * fontScale,
                fontWeight: FontWeight.w600,
                color: p.ink,
                height: 1.65,
              ),
            ),
          ),
        );
        continue;
      }

      // 4. Standard Paragraph
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: SelectableText(
            line,
            style: GoogleFonts.cairo(
              fontSize: 13.8 * fontScale,
              color: p.ink,
              height: 1.65,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fontScale = context.watch<ThemeProvider>().fontScale;

    return Consumer<AiCompanionProvider>(
      builder: (context, aiProv, _) {
        final hasMessages = aiProv.messages.isNotEmpty;

        return Scaffold(
          backgroundColor: p.canvas,
          appBar: AppBar(
            backgroundColor: p.canvas,
            foregroundColor: p.ink,
            elevation: 0,
            leading: IconButton(
              tooltip: 'محادثاتي السابقة',
              icon: Icon(Icons.history_rounded, color: p.ink),
              onPressed: () => _showChatHistorySheet(context, aiProv),
            ),
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.goldSoft,
                    border: Border.all(color: p.goldBorder),
                  ),
                  child: Center(child: CopticCross(size: 17, color: p.accent)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المرشد الآبائي',
                        style: GoogleFonts.amiri(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: p.ink,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'حوار روحي ولاهوتي وطقسي أرثوذكسي',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 10.5,
                          color: p.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'محادثة جديدة',
                icon: Icon(Icons.edit_square, size: 20, color: p.accent),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  aiProv.startNewChat();
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: Column(
                  children: [
                    Divider(color: p.border, height: 1),

                    // Main Chat Canvas OR Organized Welcome View
                    Expanded(
                      child: !hasMessages
                          ? _buildOrganizedWelcome(p, aiProv)
                          : ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                              itemCount: aiProv.messages.length + (aiProv.isLoading ? 1 : 0),
                              itemBuilder: (context, idx) {
                                if (idx == aiProv.messages.length) {
                                  return _buildThinkingBubble(p);
                                }
                                final msg = aiProv.messages[idx];
                                return _buildMessageBubble(context, p, msg, fontScale);
                              },
                            ),
                    ),

                    // Clean Floating Pill Chat Input
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                      decoration: BoxDecoration(
                        color: p.canvas,
                        border: Border(top: BorderSide(color: p.border, width: 0.8)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: p.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: p.border),
                              ),
                              child: TextField(
                                controller: _inputCtrl,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (val) => _sendPrompt(aiProv, val),
                                style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                                decoration: InputDecoration(
                                  hintText: 'اسأل في العقيدة، الطقس، الكتاب المقدس، أو حياتك الروحية...',
                                  hintStyle: GoogleFonts.cairo(color: p.inkMuted, fontSize: 12.5),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PressScale(
                            scale: 0.94,
                            onTap: () => _sendPrompt(aiProv, _inputCtrl.text),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: aiProv.isLoading ? p.borderStrong : p.accent,
                              ),
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                color: p.onAccent,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrganizedWelcome(AppPalette p, AiCompanionProvider aiProv) {
    final icons = const [
      Icons.auto_awesome_outlined,
      Icons.church_outlined,
      Icons.menu_book_outlined,
      Icons.spa_outlined,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.goldSoft,
                border: Border.all(color: p.goldBorder, width: 1.4),
              ),
              child: Center(child: CopticCross(size: 32, color: p.accent)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'سلام ونعمة، كيف أخدمك اليوم؟',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اسأل أي سؤال في الإيمان القبطي الأرثوذكسي، تفاسير الكتاب المقدس، طقوس الكنيسة، أو أقوال الآباء.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: p.inkSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 26),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: aiProv.starterTopics.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (_, i) {
              final topic = aiProv.starterTopics[i];
              return PressScale(
                scale: 0.97,
                onTap: () => _sendPrompt(aiProv, topic['prompt']!),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: p.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(icons[i % icons.length], size: 18, color: p.accent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              topic['category']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: p.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        topic['title']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.amiri(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                          height: 1.25,
                        ),
                      ),
                      Text(
                        topic['prompt']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 10.5,
                          color: p.inkMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(left: 10, top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.goldSoft,
              border: Border.all(color: p.goldBorder),
            ),
            child: Center(child: CopticCross(size: 14, color: p.accent)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(color: p.accent, strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'جاري إعداد الإجابة الآبائية...',
                  style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    AppPalette p,
    AiMessage msg,
    double fontScale,
  ) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            color: p.accent,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(18),
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.text,
            style: GoogleFonts.cairo(
              fontSize: 13.8 * fontScale,
              color: p.onAccent,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
        ),
      );
    }

    // Assistant Editorial Message (Clean ChatGPT/Claude layout)
    final cleanPlain = AiTheologyService.cleanMarkdownFormatting(msg.text);
    final citations = (msg.citations ?? [])
        .where((c) => !c.contains('سحابة') && !c.contains('Gemini') && !c.contains('Groq'))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(left: 10, top: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.goldSoft,
              border: Border.all(color: p.goldBorder),
            ),
            child: Center(child: CopticCross(size: 14, color: p.accent)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFormattedPatristicAnswer(p, msg.text, fontScale),
                  if (citations.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: citations
                          .map(
                            (c) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: p.surfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: p.border),
                              ),
                              child: Text(
                                c,
                                style: GoogleFonts.cairo(
                                  fontSize: 10.5,
                                  color: p.inkSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Divider(color: p.border, height: 1),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _msgActionBtn(
                        p: p,
                        icon: Icons.copy_rounded,
                        label: 'نسخ',
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: cleanPlain));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم نسخ الإجابة', style: GoogleFonts.cairo()),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _msgActionBtn(
                        p: p,
                        icon: Icons.ios_share_rounded,
                        label: 'مشاركة كبطاقة',
                        onTap: () {
                          final excerpt = cleanPlain.length > 260
                              ? '${cleanPlain.substring(0, 260)}...'
                              : cleanPlain;
                          BlessingPosterStudioSheet.show(
                            context,
                            title: 'من المرشد الآبائي',
                            bodyText: excerpt,
                            reference: 'تطبيق أرثوذكسيا',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _msgActionBtn({
    required AppPalette p,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: p.inkMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: p.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
