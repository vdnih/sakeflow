import 'package:flutter/material.dart';
import '../home/home_tab.dart';
import '../map/map_tab.dart';
import '../analysis/analysis_tab.dart';
import '../collection/collection_tab.dart';
import '../record/ai_label_screen.dart';
import 'widgets/floating_bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static final List<Widget> _tabs = [
    const HomeTab(),
    MapTab(),
    const AnalysisTab(),
    const CollectionTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: _selectedIndex,
        onTabChanged: (i) => setState(() => _selectedIndex = i),
        onFabTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiLabelScreen()),
        ),
      ),
    );
  }
}
