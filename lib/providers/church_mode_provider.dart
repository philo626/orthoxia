import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ChurchModeProvider with ChangeNotifier {
  bool _isChurchMode = false;
  double _dimFactor = 0.28; // Extra darkness overlay for dimly lit churches
  bool _silenceNotifications = true;

  bool get isChurchMode => _isChurchMode;
  double get dimFactor => _dimFactor;
  bool get silenceNotifications => _silenceNotifications;

  Future<void> _applyHardwareEffects(bool enabled) async {
    try {
      if (enabled) {
        await WakelockPlus.enable();
        await ScreenBrightness.instance.setApplicationScreenBrightness(0.14);
      } else {
        await WakelockPlus.disable();
        await ScreenBrightness.instance.resetApplicationScreenBrightness();
      }
    } catch (_) {
      // Safe fallback in headless tests or unsupported desktop targets
    }
  }

  void toggleChurchMode() {
    HapticFeedback.mediumImpact();
    _isChurchMode = !_isChurchMode;
    _applyHardwareEffects(_isChurchMode);
    notifyListeners();
  }

  void setChurchMode(bool enabled) {
    if (_isChurchMode == enabled) return;
    _isChurchMode = enabled;
    _applyHardwareEffects(_isChurchMode);
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
