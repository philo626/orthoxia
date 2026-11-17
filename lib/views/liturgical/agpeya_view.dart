import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _loadHours();
  }

  Future<void> _loadHours() async {
    try {
      final raw = await rootBundle.loadString('assets/data/agpeya.json');
      final list = jsonDecode(raw) as List;
      _hours = list.map((item) => AgpeyaHour.fromJson(item)).toList();
    } catch (e) {
      // Graceful error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  color: AppColors.sacredBurgundy.withOpacity(0.3),
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
    );
  }
}
