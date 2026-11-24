import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/ai_theology_service.dart';

class AiChatSession {
  final String id;
  final String title;
  final DateTime updatedAt;
  final List<AiMessage> messages;

  AiChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });

  factory AiChatSession.fromJson(Map<String, dynamic> json) {
    final msgs = (json['messages'] as List<dynamic>? ?? [])
        .map((e) => AiMessage.fromJson(Map<String, dynamic>.from(e)))
        .where((m) => m.text.isNotEmpty)
        .toList();
    return AiChatSession(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'محادثة جديدة',
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      messages: msgs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };
}

class AiCompanionProvider with ChangeNotifier {
  static const _sessionsStorageKey = 'ai_chat_sessions_v2';
  static const _legacyStorageKey = 'ai_chat_history_v1';
  static const _maxSessions = 25;
  static const _maxStoredMessagesPerSession = 40;

  final AiTheologyService _service = AiTheologyService();

  final List<AiChatSession> _sessions = [];
  String _activeSessionId = '';
  bool _isLoading = false;
  String? _apiKey;
  AiApiConfig _apiConfig = const AiApiConfig();

  List<AiChatSession> get sessions => List.unmodifiable(_sessions);
  String get activeSessionId => _activeSessionId;
  bool get isLoading => _isLoading;
  AiApiConfig get apiConfig => _apiConfig;

  AiChatSession get activeSession {
    final idx = _sessions.indexWhere((s) => s.id == _activeSessionId);
    if (idx != -1) return _sessions[idx];
    if (_sessions.isNotEmpty) {
      _activeSessionId = _sessions.first.id;
      return _sessions.first;
    }
    final fresh = _createEmptySession();
    _sessions.add(fresh);
    _activeSessionId = fresh.id;
    return fresh;
  }

  List<AiMessage> get messages => activeSession.messages;

  bool get isNewEmptyChat => messages.where((m) => m.isUser).isEmpty;

  final List<Map<String, String>> starterTopics = const [
    {
      'category': 'العقيدة والإيمان',
      'title': 'سر التجسد الإلهي',
      'prompt': 'اشرح لي سر التجسد الإلهي بحسب تعليم القديس أثناسيوس الرسولي',
    },
    {
      'category': 'الطقس والليتورجيا',
      'title': 'ترتيب القداس الباسيلي',
      'prompt': 'اشرح لي ترتيب القداس الباسيلي ومعاني أجزائه الأساسية',
    },
    {
      'category': 'الكتاب المقدس',
      'title': 'تأمل في مزمور ٢٣',
      'prompt': 'أعطني تأملاً آبائياً في مزمور: الرب راعيّ فلا يعوزني شيء',
    },
    {
      'category': 'الحياة الروحية',
      'title': 'علاج الفتور الروحي',
      'prompt': 'كيف أتغلب على الفتور الروحي والكسل في الصلاة حسب أقوال الآباء؟',
    },
  ];

  AiCompanionProvider() {
    _sessions.add(_createEmptySession());
    _activeSessionId = _sessions.first.id;
    _loadSessions();
    _loadApiConfig();
  }

  AiChatSession _createEmptySession() {
    return AiChatSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: 'محادثة جديدة',
      updatedAt: DateTime.now(),
      messages: [],
    );
  }

  Future<void> _loadApiConfig() async {
    _apiConfig = await AiTheologyService.loadConfig();
    notifyListeners();
  }

  Future<(bool, String)> testAndSaveApiConfig(AiApiConfig cfg) async {
    final (ok, msg) = await _service.testConnection(cfg);
    if (ok) {
      await AiTheologyService.saveConfig(cfg);
      _apiConfig = cfg;
      notifyListeners();
    }
    return (ok, msg);
  }

  Future<void> disconnectApi() async {
    await AiTheologyService.clearConfig();
    _apiConfig = await AiTheologyService.loadConfig();
    notifyListeners();
  }

  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawV2 = prefs.getString(_sessionsStorageKey);
      if (rawV2 != null && rawV2.isNotEmpty) {
        final list = (jsonDecode(rawV2) as List<dynamic>)
            .map((e) => AiChatSession.fromJson(Map<String, dynamic>.from(e)))
            .where((s) => s.messages.isNotEmpty)
            .toList();
        if (list.isNotEmpty) {
          _sessions
            ..clear()
            ..addAll(list);
          _activeSessionId = _sessions.first.id;
          notifyListeners();
          return;
        }
      }

      // Migrate v1 history smoothly if present
      final rawV1 = prefs.getString(_legacyStorageKey);
      if (rawV1 != null && rawV1.isNotEmpty) {
        final decoded = (jsonDecode(rawV1) as List<dynamic>)
            .map((e) => AiMessage.fromJson(Map<String, dynamic>.from(e)))
            .where((m) => m.text.isNotEmpty)
            .toList();
        final firstUser = decoded.where((m) => m.isUser).toList();
        if (firstUser.isNotEmpty) {
          final migrated = AiChatSession(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: _deriveTitle(firstUser.first.text),
            updatedAt: decoded.last.timestamp,
            messages: decoded,
          );
          _sessions
            ..clear()
            ..add(migrated);
          _activeSessionId = migrated.id;
          await _persistSessions();
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  String _deriveTitle(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= 42) return cleaned;
    return '${cleaned.substring(0, 42)}…';
  }

  Future<void> _persistSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nonEmpty = _sessions.where((s) => s.messages.isNotEmpty).take(_maxSessions).map((s) {
        final trimmedMsgs = s.messages.length > _maxStoredMessagesPerSession
            ? s.messages.sublist(s.messages.length - _maxStoredMessagesPerSession)
            : s.messages;
        return AiChatSession(
          id: s.id,
          title: s.title,
          updatedAt: s.updatedAt,
          messages: trimmedMsgs,
        ).toJson();
      }).toList();
      await prefs.setString(_sessionsStorageKey, jsonEncode(nonEmpty));
    } catch (_) {}
  }

  Future<void> startNewChat() async {
    // Reuse current empty session if already empty
    if (isNewEmptyChat) return;
    final fresh = _createEmptySession();
    _sessions.insert(0, fresh);
    _activeSessionId = fresh.id;
    notifyListeners();
  }

  void selectSession(String id) {
    if (_sessions.any((s) => s.id == id)) {
      _activeSessionId = id;
      notifyListeners();
    }
  }

  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    if (_sessions.isEmpty) {
      final fresh = _createEmptySession();
      _sessions.add(fresh);
      _activeSessionId = fresh.id;
    } else if (_activeSessionId == id) {
      _activeSessionId = _sessions.first.id;
    }
    notifyListeners();
    await _persistSessions();
  }

  Future<void> clearConversation() async {
    await startNewChat();
  }

  void setApiKey(String key) {
    _apiKey = key;
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    final idx = _sessions.indexWhere((s) => s.id == _activeSessionId);
    final current = idx != -1 ? _sessions[idx] : activeSession;
    final historySnapshot = List<AiMessage>.from(current.messages);

    final updatedMessages = List<AiMessage>.from(current.messages)
      ..add(AiMessage(
        text: trimmed,
        isUser: true,
        timestamp: DateTime.now(),
      ));

    final newTitle = current.messages.where((m) => m.isUser).isEmpty
        ? _deriveTitle(trimmed)
        : current.title;

    _replaceSession(AiChatSession(
      id: current.id,
      title: newTitle,
      updatedAt: DateTime.now(),
      messages: updatedMessages,
    ));

    _isLoading = true;
    notifyListeners();
    await _persistSessions();

    try {
      final response = await _service.askQuestion(
        trimmed,
        apiKey: _apiKey,
        history: historySnapshot,
      );
      final latest = activeSession;
      _replaceSession(AiChatSession(
        id: latest.id,
        title: latest.title,
        updatedAt: DateTime.now(),
        messages: [...latest.messages, response],
      ));
    } catch (_) {
      final latest = activeSession;
      _replaceSession(AiChatSession(
        id: latest.id,
        title: latest.title,
        updatedAt: DateTime.now(),
        messages: [
          ...latest.messages,
          AiMessage(
            text: 'عذراً، تعذر إتمام الإجابة حالياً. يُرجى المحاولة مرة أخرى بعد لحظات.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
      await _persistSessions();
    }
  }

  void _replaceSession(AiChatSession updated) {
    _sessions.removeWhere((s) => s.id == updated.id);
    _sessions.insert(0, updated);
    _activeSessionId = updated.id;
  }
}
