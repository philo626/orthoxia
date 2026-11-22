import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/agpeya_model.dart';
import 'agpeya_reader_view.dart';

class AgpeyaView extends StatefulWidget {
  const AgpeyaView({super.key});

  @override
  State<AgpeyaView> createState() => _AgpeyaViewState();
}

class _AgpeyaViewState extends State<AgpeyaView> {
  List<AgpeyaHour> _hours = [];
  bool _isLoading = true;
  Set<String> _enabledAlarmIds = {};

  static const List<Map<String, String>> _alarmSlots = [
    {'id': 'prime', 'title': 'صلاة باكر (٦:٠٠ ص)'},
    {'id': 'terce', 'title': 'صلاة الساعة الثالثة (٩:٠٠ ص)'},
    {'id': 'sext', 'title': 'صلاة الساعة السادسة (١٢:٠٠ ظ)'},
    {'id': 'none', 'title': 'صلاة الساعة التاسعة (٣:٠٠ ع)'},
    {'id': 'vespers', 'title': 'صلاة الغروب (٥:٠٠ م)'},
    {'id': 'compline', 'title': 'صلاة النوم (٩:٠٠ م)'},
    {'id': 'midnight', 'title': 'صلاة نصف الليل (١١:٣٠ م)'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHours();
  }

  Future<void> _loadHours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabledAlarmIds =
          (prefs.getStringList(NotificationService.agpeyaAlarmsPrefsKey) ?? []).toSet();

      final raw = await rootBundle.loadString('assets/data/agpeya.json');
      final list = jsonDecode(raw) as List;
      _hours = list.map((item) => AgpeyaHour.fromJson(item)).toList();
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _recommendedHourIdNow() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 9) return 'prime';
    if (h >= 9 && h < 12) return 'terce';
    if (h >= 12 && h < 15) return 'sext';
    if (h >= 15 && h < 17) return 'none';
    if (h >= 17 && h < 20) return 'vespers';
    if (h >= 20 && h < 23) return 'compline';
    return 'midnight';
  }

  void _openAgpeyaAlarmsSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final p = ctx.palette;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 16),
                  Text(
                    'منبّه سواعي الأجبية',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اختر الساعات التي ترغب أن يذكّرك بها التطبيق يومياً في موعدها',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary),
                  ),
                  const SizedBox(height: 12),
                  ..._alarmSlots.map((slot) {
                    final id = slot['id']!;
                    final isOn = _enabledAlarmIds.contains(id);
                    return SwitchListTile(
                      dense: true,
                      activeThumbColor: p.accent,
                      title: Text(
                        slot['title']!,
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: isOn ? FontWeight.bold : FontWeight.w500,
                          color: isOn ? p.accent : p.ink,
                        ),
                      ),
                      value: isOn,
                      onChanged: (val) async {
                        setSheetState(() {
                          if (val) {
                            _enabledAlarmIds.add(id);
                          } else {
                            _enabledAlarmIds.remove(id);
                          }
                        });
                        setState(() {});
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setStringList(
                          NotificationService.agpeyaAlarmsPrefsKey,
                          _enabledAlarmIds.toList(),
                        );
                        if (val) {
                          await NotificationService().requestPermission();
                        }
                        await NotificationService().syncAgpeyaAlarms(_enabledAlarmIds);
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: p.canvas,
        body: Center(child: CircularProgressIndicator(color: p.accent, strokeWidth: 2)),
      );
    }

    final currentHourId = _recommendedHourIdNow();

    return Scaffold(
      backgroundColor: p.canvas,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              // Clean Adaptive Alarms Strip
              Container(
                margin: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.border),
                  boxShadow: p.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: p.shadow,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.goldSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.notifications_active_outlined, color: p.gold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'منبّه سواعي الأجبية',
                            style: GoogleFonts.cairo(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                            ),
                          ),
                          Text(
                            _enabledAlarmIds.isEmpty
                                ? 'اختياري — اضبط الساعات التي تحب التذكير بها'
                                : 'مُفعّل لـ ${_enabledAlarmIds.length} من سواعي الصلاة يومياً',
                            style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkSecondary),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _openAgpeyaAlarmsSheet,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        side: BorderSide(color: p.goldBorder),
                        backgroundColor: p.goldSoft,
                      ),
                      child: Text(
                        'ضبط',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: p.isDark ? p.gold : p.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 36),
                  itemCount: _hours.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final hour = _hours[index];
                    final isRecommended = hour.id == currentHourId;
                    return PressScale(
                      scale: 0.985,
                      onTap: () => Navigator.push(
                        context,
                        luxeRoute(AgpeyaReaderView(hour: hour)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isRecommended ? p.goldSoft : p.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isRecommended ? p.accent : p.border,
                            width: isRecommended ? 1.4 : 1,
                          ),
                          boxShadow: p.isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: p.shadow,
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isRecommended ? p.accent : p.surfaceSubtle,
                                border: Border.all(
                                  color: isRecommended ? p.accent : p.border,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.amiri(
                                  color: isRecommended ? p.onAccent : p.ink,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 19,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          hour.nameAr,
                                          style: GoogleFonts.amiri(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: p.ink,
                                          ),
                                        ),
                                      ),
                                      if (isRecommended)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: p.accent,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'الآن',
                                            style: GoogleFonts.cairo(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: p.onAccent,
                                            ),
                                          ),
                                        )
                                      else if (hour.timeRange.isNotEmpty)
                                        Text(
                                          hour.timeRange,
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            color: p.inkMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hour.theme,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: p.inkSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_left_rounded,
                              color: isRecommended ? p.accent : p.inkMuted,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
