import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFF8A4FFF).withValues(alpha: 0.12),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: Color(0xFF8A4FFF)),
          label: '홈',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome, color: Color(0xFF8A4FFF)),
          label: '오늘의 운세',
        ),
        NavigationDestination(
          icon: Icon(Icons.text_fields_outlined),
          selectedIcon: Icon(Icons.text_fields, color: Color(0xFF8A4FFF)),
          label: '성명학',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: Color(0xFF8A4FFF)),
          label: '내 사주',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite, color: Color(0xFF8A4FFF)),
          label: '궁합',
        ),
      ],
    );
  }
}
