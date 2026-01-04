import 'package:bashakhojo/common/widgets/bottom_nav_bar.dart';
import 'package:bashakhojo/pages/home/home.dart';
import 'package:bashakhojo/pages/inbox/inbox.dart';
import 'package:bashakhojo/pages/profile/profile.dart';
import 'package:bashakhojo/pages/saved/saved.dart';
import 'package:flutter/material.dart';

/// Main shell widget that handles bottom navigation between screens.
/// This is the authenticated user's main interface.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SavedScreen(),
    const InboxScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _screens),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: BottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}
