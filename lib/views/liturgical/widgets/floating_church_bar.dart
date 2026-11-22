import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/theme_provider.dart';

class FloatingChurchBar extends StatefulWidget {
  const FloatingChurchBar({super.key});

  @override
  State<FloatingChurchBar> createState() => _FloatingChurchBarState();
}

class _FloatingChurchBarState extends State<FloatingChurchBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final themeProv = Provider.of<ThemeProvider>(context);
    final isAmoled = themeProv.mode == AppThemeMode.amoledChurch;

    return Positioned(
      bottom: 20,
      left: 18,
      right: 18,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: p.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _isExpanded ? p.goldBorder : p.border,
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: p.shadow.withValues(alpha: p.isDark ? 0.5 : 0.2),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.church_outlined, size: 19, color: p.accent),
                    const SizedBox(width: 8),
                    Text(
                      'أدوات القراءة والخشوع',
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.text_decrease_rounded, size: 18),
                      color: p.ink,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => themeProv.decreaseFontSize(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.text_increase_rounded, size: 18),
                      color: p.ink,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => themeProv.increaseFontSize(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.tune_rounded,
                        size: 20,
                        color: p.accent,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    ),
                  ],
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 10),
              Divider(color: p.border, height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (isAmoled) {
                        themeProv.setThemeMode(AppThemeMode.lightParchment);
                      } else {
                        themeProv.setThemeMode(AppThemeMode.amoledChurch);
                      }
                    },
                    icon: Icon(
                      isAmoled ? Icons.check_circle_rounded : Icons.dark_mode_outlined,
                      size: 16,
                      color: p.accent,
                    ),
                    label: Text(
                      isAmoled ? 'إلغاء المعتم' : 'وضع الكنيسة المعتم',
                      style: GoogleFonts.cairo(fontSize: 12, color: p.ink),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      themeProv.toggleKeepAwake();
                      try {
                        WakelockPlus.toggle(enable: themeProv.keepAwake);
                      } catch (_) {}
                    },
                    icon: Icon(
                      themeProv.keepAwake ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: p.accent,
                    ),
                    label: Text(
                      themeProv.keepAwake ? 'إبقاء الشاشة نشطة' : 'سكون تلقائي',
                      style: GoogleFonts.cairo(fontSize: 12, color: p.ink),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
