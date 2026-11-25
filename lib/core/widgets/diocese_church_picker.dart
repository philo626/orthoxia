import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/confession_models.dart';
import '../theme/app_palette.dart';

/// Clean, effortless 2-tap Diocese & Church Selector for Coptic Priests:
/// Zero manual typing required — Abona simply taps to choose Diocese, then taps to choose his Church
/// from the diocese's curated list (with instant filter search + optional "كنيسة أخرى" fallback).
class DioceseChurchSelector extends StatelessWidget {
  final String selectedDiocese;
  final String selectedChurch;
  final ValueChanged<String> onDioceseChanged;
  final ValueChanged<String> onChurchChanged;

  const DioceseChurchSelector({
    super.key,
    required this.selectedDiocese,
    required this.selectedChurch,
    required this.onDioceseChanged,
    required this.onChurchChanged,
  });

  Future<void> _openDiocesePicker(BuildContext context) async {
    HapticFeedback.selectionClick();
    final picked = await _showSearchablePickerSheet(
      context: context,
      title: 'اختر الإيبارشية',
      searchHint: 'ابحث عن الإيبارشية...',
      items: CopticDiocesesCatalog.dioceses,
      selectedValue: selectedDiocese,
      icon: Icons.location_city_rounded,
      allowCustomOther: false,
    );
    if (picked != null && picked != selectedDiocese) {
      onDioceseChanged(picked);
      // Automatically pick first church in new diocese or clear so user picks cleanly
      final churches = CopticDiocesesCatalog.churchesFor(picked);
      if (churches.isNotEmpty) {
        onChurchChanged(churches.first);
      }
    }
  }

  static String _normAr(String s) {
    return s
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _openChurchPicker(BuildContext context) async {
    HapticFeedback.selectionClick();
    final churches = CopticDiocesesCatalog.churchesFor(selectedDiocese);
    final picked = await _showSearchablePickerSheet(
      context: context,
      title: 'اختر الكنيسة (${churches.length} كنيسة)',
      subtitle: 'إيبارشية $selectedDiocese',
      searchHint: 'ابحث باسم الكنيسة أو المنطقة (مثال: العذراء، مارجرجس، شبرا)...',
      items: churches,
      selectedValue: selectedChurch,
      icon: Icons.church_outlined,
      allowCustomOther: true,
    );
    if (picked != null && picked.trim().isNotEmpty) {
      onChurchChanged(picked.trim());
    }
  }

  static Future<String?> _showSearchablePickerSheet({
    required BuildContext context,
    required String title,
    String? subtitle,
    required String searchHint,
    required List<String> items,
    required String selectedValue,
    required IconData icon,
    required bool allowCustomOther,
  }) {
    final p = context.palette;
    final queryCtrl = TextEditingController();
    final otherCtrl = TextEditingController();
    bool enteringOther = false;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final q = _normAr(queryCtrl.text);
          final filtered = q.isEmpty
              ? items
              : items.where((x) => _normAr(x).contains(q)).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.72,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: p.goldBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: p.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.amiri(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: p.ink,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(fontSize: 11.5, color: p.gold, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 10),
                  if (!enteringOther) ...[
                    TextField(
                      controller: queryCtrl,
                      onChanged: (_) => setSheet(() {}),
                      style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: searchHint,
                        isDense: true,
                        prefixIcon: const Icon(Icons.search_rounded, size: 19),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length + (allowCustomOther ? 1 : 0),
                        separatorBuilder: (_, _) => Divider(color: p.border.withValues(alpha: 0.6), height: 1),
                        itemBuilder: (_, idx) {
                          if (allowCustomOther && idx == filtered.length) {
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              leading: Icon(Icons.add_circle_outline_rounded, color: p.accent, size: 20),
                              title: Text(
                                queryCtrl.text.trim().isNotEmpty
                                    ? 'إضافة «${queryCtrl.text.trim()}» كاسم كنيستي'
                                    : 'كنيستي مش في القائمة؟ اكتب اسمها هنا',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: p.accent,
                                ),
                              ),
                              onTap: () {
                                if (queryCtrl.text.trim().length >= 3) {
                                  otherCtrl.text = queryCtrl.text.trim();
                                }
                                setSheet(() => enteringOther = true);
                              },
                            );
                          }
                          final item = filtered[idx];
                          final isSel = item == selectedValue;
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            leading: Icon(
                              isSel ? Icons.check_circle_rounded : icon,
                              color: isSel ? p.gold : p.inkMuted,
                              size: 20,
                            ),
                            title: Text(
                              item,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? p.ink : p.inkSecondary,
                              ),
                            ),
                            onTap: () => Navigator.pop(ctx, item),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    Text(
                      'اكتب اسم الكنيسة والمنطقة:',
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: p.ink),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: otherCtrl,
                      autofocus: true,
                      style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'مثال: كنيسة السيدة العذراء...',
                        prefixIcon: Icon(Icons.church_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setSheet(() => enteringOther = false),
                            child: Text('رجوع للقائمة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final txt = otherCtrl.text.trim();
                              if (txt.length >= 2) Navigator.pop(ctx, txt);
                            },
                            child: Text('اختيار', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pickerField(
          p: p,
          label: 'الإيبارشية',
          value: selectedDiocese.isNotEmpty ? selectedDiocese : 'اضغط لاختيار الإيبارشية',
          isPlaceholder: selectedDiocese.isEmpty,
          icon: Icons.location_city_rounded,
          onTap: () => _openDiocesePicker(context),
        ),
        const SizedBox(height: 11),
        _pickerField(
          p: p,
          label: 'الكنيسة',
          value: selectedChurch.isNotEmpty ? selectedChurch : 'اضغط لاختيار الكنيسة',
          isPlaceholder: selectedChurch.isEmpty,
          icon: Icons.church_outlined,
          onTap: () => _openChurchPicker(context),
        ),
      ],
    );
  }

  Widget _pickerField({
    required AppPalette p,
    required String label,
    required String value,
    required bool isPlaceholder,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: p.surfaceSubtle,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isPlaceholder ? p.border : p.goldBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isPlaceholder ? p.inkMuted : p.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cairo(fontSize: 10.5, color: p.inkMuted, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 13.5,
                      fontWeight: isPlaceholder ? FontWeight.w500 : FontWeight.bold,
                      color: isPlaceholder ? p.inkMuted : p.ink,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: p.gold, size: 22),
          ],
        ),
      ),
    );
  }
}
