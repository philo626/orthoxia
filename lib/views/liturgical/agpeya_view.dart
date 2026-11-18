import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../models/agpeya_model.dart';
import 'agpeya_reader_view.dart';

class AgpeyaView extends StatefulWidget {
  const AgpeyaView({super.key});

  @override
  State<AgpeyaView> createState() => _AgpeyaViewState();
}

class _AgpeyaViewState extends State<AgpeyaView> {
  static const String _alarmsKey = 'agpeya_optional_alarms_v1';
  List<AgpeyaHour> _hours = [];
  bool _isLoading = true;
  Set<String> _enabledAlarmIds = {};

  static const List<Map<String, String>> _alarmSlots = [
    {'id': 'prime', 'title': 'صلاة باكر (٦:٠٠ ص)', 'time': '06:00'},
    {'id': 'terce', 'title': 'صلاة الساعة الثالثة (٩:٠٠ ص)', 'time': '09:00'},
    {'id': 'sext', 'title': 'صلاة الساعة السادسة (١٢:٠٠ ظ)', 'time': '12:00'},
    {'id': 'none', 'title': 'صلاة الساعة التاسعة (٣:٠٠ ع)', 'time': '15:00'},
    {'id': 'vespers', 'title': 'صلاة الغروب (٥:٠٠ م)', 'time': '17:00'},
    {'id': 'compline', 'title': 'صلاة النوم (٩:٠٠ م)', 'time': '21:00'},
    {'id': 'midnight', 'title': 'صلاة نصف الليل (١١:٣٠ م)', 'time': '23:30'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHours();
  }

  Future<void> _loadHours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabledAlarmIds = (prefs.getStringList(_alarmsKey) ?? []).toSet();

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

  void _openAgpeyaAlarmsSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
            decoration: const BoxDecoration(
              color: Color(0xFF13151D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              border: Border(top: BorderSide(color: AppColors.primaryGold, width: 1.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '⏰ منبّه سواعي الأجبية (اختياري)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
                Text(
                  'اختر الساعات التي تحب أن يذكرك التطبيق بصلاوتها يومياً (يمكنك إيقافها في أي وقت)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                ..._alarmSlots.map((slot) {
                  final id = slot['id']!;
                  final isOn = _enabledAlarmIds.contains(id);
                  return SwitchListTile(
                    dense: true,
                    activeThumbColor: AppColors.primaryGold,
                    title: Text(
                      slot['title']!,
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isOn ? AppColors.primaryGoldLight : Colors.white,
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
                      await prefs.setStringList(_alarmsKey, _enabledAlarmIds.toList());
                      if (val) {
                        await NotificationService().requestPermission();
                      }
                    },
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Optional Agpeya Alarms Top Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF281F12), Color(0xFF15161E)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                const Icon(Icons.alarm_rounded, color: AppColors.primaryGold, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'منبّه سواعي الأجبية الاختياري',
                        style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGoldLight,
                        ),
                      ),
                      Text(
                        _enabledAlarmIds.isEmpty
                            ? 'اضغط لتحديد الساعات التي تحب التذكير بها'
                            : 'تم تفعيل التذكير لـ ${_enabledAlarmIds.length} من سواعي الأجبية',
                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _openAgpeyaAlarmsSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'ضبط المنبّه',
                    style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _hours.length,
              itemBuilder: (context, index) {
                final hour = _hours[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardNavy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.2)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.sacredBurgundy.withValues(alpha: 0.3),
                          border: Border.all(color: AppColors.primaryGold, width: 1.2),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.cairo(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        hour.nameAr,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hour.nameCoptic,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.primaryGoldLight,
                            ),
                          ),
                          Text(
                            hour.theme,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primaryGold),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AgpeyaReaderView(hour: hour)),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
