import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../exchange/screens/connections_screen.dart';
import '../../exchange/screens/requests_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    RequestsScreen(),
    ConnectionsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Screen View Stack
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // CashMate Floating Pill Navigation Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomInset + 12,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 396),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.home_rounded,
                        unselectedIcon: Icons.home_outlined,
                        label: 'Home',
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.swap_horiz_rounded,
                        unselectedIcon: Icons.swap_horiz_outlined,
                        label: 'Requests',
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.handshake_rounded,
                        unselectedIcon: Icons.handshake_outlined,
                        label: 'Connections',
                      ),
                      _buildNavItem(
                        index: 3,
                        icon: Icons.person_rounded,
                        unselectedIcon: Icons.person_outline,
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData unselectedIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? icon : unselectedIcon,
                  size: 22,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.65),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: -0.2,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

