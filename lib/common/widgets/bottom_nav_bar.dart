import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _buildNavItems(),
      ),
    );
  }

  List<Widget> _buildNavItems() {
    List<Widget> items = [];

    items.add(NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: "Home",
      isActive: selectedIndex == 0,
      onTap: () {
        onItemTapped(0);
      },
    ));

    items.add(NavItem(
      icon: Icons.bookmark_border,
      activeIcon: Icons.bookmark,
      label: "Saved",
      isActive: selectedIndex == 1,
      onTap: () {
        onItemTapped(1);
      },
    ));

    items.add(NavItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: "Inbox",
      isActive: selectedIndex == 2,
      onTap: () {
        onItemTapped(2);
      },
    ));

    items.add(NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: "Profile",
      isActive: selectedIndex == 3,
      onTap: () {
        onItemTapped(3);
      },
    ));

    return items;
  }
}

class NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    IconData displayIcon;
    if (isActive) {
      displayIcon = activeIcon;
    } else {
      displayIcon = icon;
    }

    Color iconColor;
    if (isActive) {
      iconColor = colorScheme.primary;
    } else {
      iconColor = colorScheme.onSurfaceVariant;
    }

    FontWeight fontWeight;
    if (isActive) {
      fontWeight = FontWeight.bold;
    } else {
      fontWeight = FontWeight.w500;
    }

    Color textColor;
    if (isActive) {
      textColor = colorScheme.primary;
    } else {
      textColor = colorScheme.onSurfaceVariant;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(displayIcon, color: iconColor, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
