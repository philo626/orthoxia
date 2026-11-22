import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/ai_theology_service.dart';

class AiCompanionProvider with ChangeNotifier {
  static const _storageKey = 'ai_chat_history_v1';
  static const _maxStoredMessages = 40;

  final AiTheologyService _service = AiTheologyService();

  static AiMessage _welcomeMessage() => AiMessage(
        text:
            'سلام ونعمة. أنا المرشد الآبائي لدراسة الإيمان القبطي الأرثوذكسي وتفاسير الكتاب المقدس وأقوال الآباء القديسين. بماذا يمكنني أن أخدمك اليوم؟',
        isUser: false,
        timestamp: DateTime.now(),
        citations: ['الكنيسة القبطية الأرثوذكسية'],
      );

  final List<AiMessage> _messages = [_welcomeMessage()];
  bool _isLoading = false;
  String? _apiKey;

  List<AiMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  final List<String> quickPrompts = const [
    'ما هو مفهوم التوبة والاعتراف؟',
    'لماذا نصوم صوم يونان؟',
    'ما هو سر التجسد الإلهي؟',
    'كيف أتغلب على الفتور الروحي؟',
    'ما هي أسرار الكنيسة السبعة؟',
  ];

  AiCompanionProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final restored = decoded
            .map((e) => AiMessage.fromJson(Map<String, dynamic>.from(e)))
            .where((m) => m.text.isNotEmpty)
            .toList();
        if (restored.isNotEmpty) {
          _messages
            ..clear()
            ..addAll(restored);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _persistHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final slice = _messages.length > _maxStoredMessages
          ? _messages.sublist(_messages.length - _maxStoredMessages)
          : _messages;
      await prefs.setString(
        _storageKey,
        jsonEncode(slice.map((m) => m.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> clearConversation() async {
    _messages
      ..clear()
      ..add(_welcomeMessage());
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  void setApiKey(String key) {
    _apiKey = key;
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    final historySnapshot = List<AiMessage>.from(_messages);
    _messages.add(AiMessage(
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    notifyListeners();
    await _persistHistory();

    try {
      final response = await _service.askQuestion(
        trimmed,
        apiKey: _apiKey,
        history: historySnapshot,
      );
      _messages.add(response);
    } catch (_) {
      _messages.add(AiMessage(
        text: 'عذراً، حدث خطأ أثناء معالجة السؤال. يرجى المحاولة مرة أخرى.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
      await _persistHistory();
    }
  }
}
