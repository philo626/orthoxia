import 'package:flutter/material.dart';
import 'bible_explorer_view.dart';

/// Redirects directly to the complete 66-Book Holy Bible Explorer
/// (without commentaries or the 3 sample passages, as requested by the user).
class ScriptureTafseerReadingView extends StatelessWidget {
  final int initialIndex;

  const ScriptureTafseerReadingView({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return const BibleExplorerView();
  }
}
