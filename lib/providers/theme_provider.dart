import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';
import '../core/theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  final StorageService _storage = StorageService();

  late AppThemeMode _mode;
  late double _fontScale;
  double _screenBrightness = 1.0;
  bool _keepAwake = false;

  AppThemeMode get mode => _mode;
  double get fontScale => _fontScale;
  double get screenBrightness => _screenBrightness;
  bool get keepAwake => _keepAwake;

  ThemeProvider() {
    _mode = _storage.getThemeMode();
    _fontScale = _storage.getFontSizeScale();
  }

  ThemeData get currentTheme => AppTheme.getTheme(_mode);

  void setThemeMode(AppThemeMode newMode) {
    _mode = newMode;
    _storage.setThemeMode(newMode);
    notifyListeners();
  }

  void setFontScale(double scale) {
    _fontScale = scale.clamp(0.8, 1.8);
    _storage.setFontSizeScale(_fontScale);
    notifyListeners();
  }

  void increaseFontSize() {
    setFontScale(_fontScale + 0.1);
  }

  void decreaseFontSize() {
    setFontScale(_fontScale - 0.1);
  }

  void setBrightness(double value) {
    _screenBrightness = value.clamp(0.05, 1.0);
    notifyListeners();
  }

  void toggleKeepAwake() {
    _keepAwake = !_keepAwake;
    notifyListeners();
  }
}
