import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'prayer_wall_view.dart';
import 'trivia_game_view.dart';

class CommunityHubView extends StatelessWidget {
  const CommunityHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'المسابقات اللانهائية ومجتمع الصلاة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          bottom: TabBar(
            labelColor: AppColors.primaryGold,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primaryGold,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(
                icon: Icon(Icons.emoji_events_rounded, size: 20),
                text: 'المسابقات والأسئلة اللانهائية ♾️',
              ),
              Tab(
                icon: Icon(Icons.volunteer_activism_rounded, size: 20),
                text: 'حائط الصلوات',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TriviaGameView(),
            PrayerWallView(),
          ],
        ),
      ),
    );
  }
}
