import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/liturgy_model.dart';

class LiturgyProvider extends ChangeNotifier {
  List<Liturgy> _liturgies = [];
  bool _isLoading = false;
  Liturgy? _selectedLiturgy;
  String _activeRole = 'all'; // 'all', 'priest', 'deacon', 'people'
  String _displayMode = 'all'; // 'all' (tri-lingual), 'coptic', 'arabic'
  double _fontSizeMultiplier = 1.0;

  List<Liturgy> get liturgies => _liturgies;
  bool get isLoading => _isLoading;
  Liturgy? get selectedLiturgy => _selectedLiturgy;
  String get activeRole => _activeRole;
  String get displayMode => _displayMode;
  double get fontSizeMultiplier => _fontSizeMultiplier;

  Future<void> loadLiturgies() async {
    if (_liturgies.isNotEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final jsonString = await rootBundle.loadString('assets/data/liturgies.json');
      final List<dynamic> data = json.decode(jsonString);
      _liturgies = data.map((item) => Liturgy.fromJson(item)).toList();
      if (_liturgies.isNotEmpty && _selectedLiturgy == null) {
        _selectedLiturgy = _liturgies.first; // Default to St. Basil
      }
    } catch (e) {
      debugPrint('Error loading liturgies: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectLiturgy(Liturgy liturgy) {
    _selectedLiturgy = liturgy;
    notifyListeners();
  }

  void selectLiturgyById(String id) {
    final found = _liturgies.firstWhere((l) => l.id == id, orElse: () => _liturgies.first);
    _selectedLiturgy = found;
    notifyListeners();
  }

  void setActiveRole(String role) {
    _activeRole = role;
    notifyListeners();
  }

  void setDisplayMode(String mode) {
    _displayMode = mode;
    notifyListeners();
  }

  void setFontSizeMultiplier(double multiplier) {
    _fontSizeMultiplier = multiplier.clamp(0.8, 1.6);
    notifyListeners();
  }

  List<LiturgyVerse> filterVerses(List<LiturgyVerse> raw) {
    if (_activeRole == 'all') return raw;
    return raw.where((v) => v.role == _activeRole || v.role == 'all').toList();
  }
}
