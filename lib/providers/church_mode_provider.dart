import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChurchModeProvider with ChangeNotifier {
  bool _isChurchMode = false;
  double _dimFactor = 0.25; // Extra darkness overlay for dimly lit churches
  bool _silenceNotifications = true;

  bool get isChurchMode => _isChurchMode;
  double get dimFactor => _dimFactor;
  bool get silenceNotifications => _silenceNotifications;

  void toggleChurchMode() {
    HapticFeedback.mediumImpact();
    _isChurchMode = !_isChurchMode;
    notifyListeners();
  }

  void setChurchMode(bool enabled) {
    if (_isChurchMode == enabled) return;
    _isChurchMode = enabled;
    notifyListeners();
  }

  void setDimFactor(double value) {
    _dimFactor = value.clamp(0.0, 0.55);
    notifyListeners();
  }

  void toggleSilenceNotifications() {
    _silenceNotifications = !_silenceNotifications;
    notifyListeners();
  }
}
