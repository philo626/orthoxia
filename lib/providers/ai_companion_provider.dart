import 'package:flutter/material.dart';
import '../core/services/ai_theology_service.dart';

class AiCompanionProvider with ChangeNotifier {
  final AiTheologyService _service = AiTheologyService();

  final List<AiMessage> _messages = [
    AiMessage(
      text: 'سلام ونعمة يا أخي المبارك. أنا رفيقك الآبائي لدراسة الإيمان الأرثوذكسي وتفاسير الكتاب المقدس وأقوال الآباء القديسين. كيف يمكنني إعانتك اليوم في مسيرتك الروحية؟',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      citations: ['الكنيسة القبطية الأرثوذكسية'],
    ),
  ];

  bool _isLoading = false;
  String? _apiKey;

  List<AiMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  final List<String> quickPrompts = [
    'ما هو مفهوم التوبة والاعتراف؟',
    'لماذا نصوم صوم يونان؟',
    'ما هو سر التجسد الإلهي؟',
    'كيف أتغلب على الفتور الروحي؟',
  ];

  void setApiKey(String key) {
    _apiKey = key;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(AiMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _service.askQuestion(text.trim(), apiKey: _apiKey);
      _messages.add(response);
    } catch (e) {
      _messages.add(AiMessage(
        text: 'عذراً، حدث خطأ أثناء معالجة السؤال. يرجى المحاولة مرة أخرى.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
