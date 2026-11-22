import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/ai_theology_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/theme/app_palette.dart';
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
  final SpeechPronunciationService _speech = SpeechPronunciationService();

  @override
  void dispose() {
    _speech.stop();
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
    Future.delayed(const Duration(milliseconds: 220), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
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
      final isHeader = line.startsWith('☦') ||
          (line.endsWith(':') && line.length <= 55);
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
      final bulletMatch =
          RegExp(r'^([•\-]|[٠-٩0-9]+[\.\-\)])\s*(.+)$').firstMatch(line);
      if (bulletMatch != null) {
        final marker = bulletMatch.group(1)!;
        final body = bulletMatch.group(2)!;
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 3, left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    marker == '•' || marker == '-' ? '•' : marker,
                    style: GoogleFonts.cairo(
                      fontSize: 11.5 * fontScale,
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
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 3. Patristic / Biblical Quote Paragraph (contains «...»)
      if (line.contains('«') && line.contains('»')) {
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: p.accentSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                right: BorderSide(color: p.accent, width: 3),
              ),
            ),
            child: SelectableText(
              line,
              style: GoogleFonts.amiri(
                fontSize: 16.5 * fontScale,
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

  void _showApiSetupSheet(BuildContext context, AiCompanionProvider aiProv) {
    final p = context.palette;
    var selectedProvider = aiProv.apiConfig.provider;
    final keyCtrl = TextEditingController(text: aiProv.apiConfig.apiKey);
    final urlCtrl =
        TextEditingController(text: aiProv.apiConfig.customEndpoint);
    final modelCtrl = TextEditingController(text: aiProv.apiConfig.customModel);
    bool testing = false;
    String? statusMsg;
    bool statusOk = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: p.border)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Text(
                    'ربط الذكاء الاصطناعي للمرشد الآبائي',
                    style: GoogleFonts.amiri(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اختر مزوداً مجانياً (بدون كارت بنكي) لحفظ مفتاحك مشفراً داخل هاتفك وتشغيل الإجابات المفتوحة:',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: p.inkMuted, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text('Google Gemini (مجاني — موصى به)',
                            style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: selectedProvider == AiProviderType.gemini
                                    ? p.onAccent
                                    : p.ink)),
                        selected: selectedProvider == AiProviderType.gemini,
                        selectedColor: p.accent,
                        backgroundColor: p.surfaceMuted,
                        showCheckmark: false,
                        onSelected: (_) => setSheet(
                            () => selectedProvider = AiProviderType.gemini),
                      ),
                      ChoiceChip(
                        label: Text('Groq (سريع ومجاني)',
                            style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: selectedProvider == AiProviderType.groq
                                    ? p.onAccent
                                    : p.ink)),
                        selected: selectedProvider == AiProviderType.groq,
                        selectedColor: p.accent,
                        backgroundColor: p.surfaceMuted,
                        showCheckmark: false,
                        onSelected: (_) => setSheet(
                            () => selectedProvider = AiProviderType.groq),
                      ),
                      ChoiceChip(
                        label: Text('خادم مخصص (Proxy)',
                            style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: selectedProvider ==
                                        AiProviderType.customProxy
                                    ? p.onAccent
                                    : p.ink)),
                        selected:
                            selectedProvider == AiProviderType.customProxy,
                        selectedColor: p.accent,
                        backgroundColor: p.surfaceMuted,
                        showCheckmark: false,
                        onSelected: (_) => setSheet(() =>
                            selectedProvider = AiProviderType.customProxy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (selectedProvider == AiProviderType.gemini)
                    InkWell(
                      onTap: () => launchUrl(
                        Uri.parse('https://aistudio.google.com/apikey'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: p.accentSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: p.accent.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.key_rounded, color: p.accent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'احصل على مفتاح Google Gemini مجاناً (١٥٠٠ سؤال يومياً بدون كارت) ← اضغط هنا',
                                style: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: p.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (selectedProvider == AiProviderType.groq)
                    InkWell(
                      onTap: () => launchUrl(
                        Uri.parse('https://console.groq.com/keys'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: p.accentSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: p.accent.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: p.accent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'احصل على مفتاح Groq المجاني (Llama 3.3 السريع) ← اضغط هنا',
                                style: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: p.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (selectedProvider == AiProviderType.customProxy) ...[
                    TextField(
                      controller: urlCtrl,
                      textDirection: TextDirection.ltr,
                      style: GoogleFonts.cairo(color: p.ink, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'رابط الخادم (HTTPS Endpoint)',
                        hintText: 'https://your-worker.workers.dev/v1/chat/completions',
                        filled: true,
                        fillColor: p.surfaceMuted,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: modelCtrl,
                      textDirection: TextDirection.ltr,
                      style: GoogleFonts.cairo(color: p.ink, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'اسم النموذج (اختياري)',
                        hintText: 'gemini-2.5-flash / gpt-4o-mini',
                        filled: true,
                        fillColor: p.surfaceMuted,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: keyCtrl,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    style: GoogleFonts.cairo(color: p.ink, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: selectedProvider == AiProviderType.customProxy
                          ? 'مفتاح API (إن وجد)'
                          : 'الصق مفتاح API هنا',
                      filled: true,
                      fillColor: p.surfaceMuted,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  if (statusMsg != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      statusMsg!,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusOk ? p.success : p.crimson,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (aiProv.apiConfig.isConfigured)
                        TextButton(
                          onPressed: testing
                              ? null
                              : () async {
                                  await aiProv.disconnectApi();
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                          child: Text('إلغاء الربط',
                              style: GoogleFonts.cairo(color: p.crimson)),
                        ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: p.accent,
                          foregroundColor: p.onAccent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: testing
                            ? null
                            : () async {
                                setSheet(() {
                                  testing = true;
                                  statusMsg = 'جارٍ اختبار الاتصال...';
                                  statusOk = false;
                                });
                                final cfg = AiApiConfig(
                                  provider: selectedProvider,
                                  apiKey: keyCtrl.text.trim(),
                                  customEndpoint: urlCtrl.text.trim(),
                                  customModel: modelCtrl.text.trim(),
                                );
                                final (ok, msg) =
                                    await aiProv.testAndSaveApiConfig(cfg);
                                if (!ctx.mounted) return;
                                setSheet(() {
                                  testing = false;
                                  statusOk = ok;
                                  statusMsg = msg;
                                });
                                if (ok) {
                                  Future.delayed(
                                      const Duration(milliseconds: 900), () {
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  });
                                }
                              },
                        icon: testing
                            ? SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: p.onAccent),
                              )
                            : const Icon(Icons.check_circle_outline_rounded,
                                size: 17),
                        label: Text(
                          testing ? 'جارٍ الاختبار...' : 'اختبار الاتصال والحفظ',
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final themeProv = Provider.of<ThemeProvider>(context);
    final fontScale = themeProv.fontScale;

    return Consumer<AiCompanionProvider>(
      builder: (context, aiProv, _) {
        return Scaffold(
          backgroundColor: p.background,
          appBar: AppBar(
            backgroundColor: p.background,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.accentSoft,
                    border: Border.all(color: p.accent.withValues(alpha: 0.45)),
                  ),
                  child: Center(child: CopticCross(size: 18, color: p.accent)),
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
                        aiProv.apiConfig.isConfigured
                            ? 'متصل بـ ${aiProv.apiConfig.providerDisplayName} • مراجع أرثوذكسية'
                            : 'الموسوعة الآبائية المحلية • اضغط «ربط API» للتفعيل المفتوح',
                        style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            color: aiProv.apiConfig.isConfigured
                                ? p.success
                                : p.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _showApiSetupSheet(context, aiProv),
                icon: Icon(
                  aiProv.apiConfig.isConfigured
                      ? Icons.cloud_done_rounded
                      : Icons.vpn_key_rounded,
                  size: 16,
                  color: aiProv.apiConfig.isConfigured ? p.success : p.accent,
                ),
                label: Text(
                  aiProv.apiConfig.customModel == 'orthoxia-cloud'
                      ? 'متصل'
                      : (aiProv.apiConfig.isConfigured ? 'API متصل' : 'ربط API'),
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: aiProv.apiConfig.isConfigured ? p.success : p.accent,
                  ),
                ),
              ),
              if (aiProv.messages.length > 1)
                IconButton(
                  tooltip: 'محادثة جديدة',
                  icon: Icon(Icons.refresh_rounded, color: p.accent),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    aiProv.clearConversation();
                  },
                ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    itemCount: aiProv.messages.length,
                    itemBuilder: (context, index) {
                      final msg = aiProv.messages[index];
                      final cleanedText =
                          AiTheologyService.cleanMarkdownFormatting(msg.text);
                      return Align(
                        alignment: msg.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.90,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? p.accentSoft
                                : p.surfaceElevated,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                              bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                            ),
                            border: Border.all(
                              color: msg.isUser
                                  ? p.accent.withValues(alpha: 0.45)
                                  : p.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (msg.isUser)
                                SelectableText(
                                  cleanedText,
                                  style: GoogleFonts.cairo(
                                    fontSize: 14 * fontScale,
                                    fontWeight: FontWeight.w600,
                                    color: p.ink,
                                    height: 1.55,
                                  ),
                                )
                              else
                                _buildFormattedPatristicAnswer(
                                    p, cleanedText, fontScale),

                              // Action bar for Patristic responses (Audio Reader + Copy)
                              if (!msg.isUser) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SpeechPlayStopButton(
                                      textToSpeak: cleanedText,
                                      label: 'إجابة المرشد الآبائي $index',
                                      playText: 'استماع',
                                      stopText: 'إيقاف',
                                      compact: true,
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(
                                            ClipboardData(text: cleanedText));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'تم نسخ الإجابة',
                                              style: GoogleFonts.cairo(
                                                  fontSize: 12),
                                            ),
                                            duration:
                                                const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 9, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: p.surfaceMuted,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(color: p.border),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.copy_rounded,
                                                size: 13, color: p.inkMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              'نسخ',
                                              style: GoogleFonts.cairo(
                                                fontSize: 10.5,
                                                color: p.inkMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              if (msg.citations != null &&
                                  msg.citations!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Divider(color: p.border, height: 1),
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
                                        color: p.surfaceMuted,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: p.border),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.bookmark_outline_rounded,
                                            size: 11,
                                            color: p.accent,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              c,
                                              style: GoogleFonts.cairo(
                                                fontSize: 10,
                                                color: p.inkMuted,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: p.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'جارٍ البحث في التفاسير وأقوال الآباء...',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: p.accent,
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
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final prompt = aiProv.quickPrompts[index];
                      return ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          prompt,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: p.ink,
                          ),
                        ),
                        backgroundColor: p.surfaceElevated,
                        side: BorderSide(color: p.border),
                        onPressed: () => _sendMessage(aiProv, prompt),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Input Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 84),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: p.accent.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          textInputAction: TextInputAction.send,
                          style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
                          cursorColor: p.accent,
                          decoration: InputDecoration(
                            hintText:
                                'اكتب سؤالك في الكتاب المقدس أو الطقس أو العقيدة...',
                            hintStyle: GoogleFonts.cairo(
                              color: p.inkSubtle,
                              fontSize: 12.5,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onSubmitted: (val) => _sendMessage(aiProv, val),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _sendMessage(aiProv, _msgCtrl.text),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.accent,
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            color: p.onAccent,
                            size: 18,
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
