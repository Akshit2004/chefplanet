import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:chef_plannet/providers/auth_provider.dart';
import 'package:chef_plannet/theme/app_theme.dart';

enum ChefPlanetNavTab { home, menu, search, orders, profile }

class ChefPlanetBottomNavV2 extends StatelessWidget {
  const ChefPlanetBottomNavV2({
    super.key,
    required this.currentTab,
    this.onSearchTap,
  });

  final ChefPlanetNavTab currentTab;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: SizedBox(
        height: 104,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: Container(
                height: 74,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFF1E6DB)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x1A0F172A),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        isSelected: currentTab == ChefPlanetNavTab.home,
                        onTap: () => _goTo(context, ChefPlanetNavTab.home),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.restaurant_menu_rounded,
                        label: 'Menu',
                        isSelected: currentTab == ChefPlanetNavTab.menu,
                        onTap: () => _goTo(context, ChefPlanetNavTab.menu),
                      ),
                    ),
                    const SizedBox(width: 82),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Orders',
                        isSelected: currentTab == ChefPlanetNavTab.orders,
                        onTap: () => _goTo(context, ChefPlanetNavTab.orders),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        isSelected: currentTab == ChefPlanetNavTab.profile,
                        onTap: () => _goTo(context, ChefPlanetNavTab.profile),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 2,
              child: _SearchButton(
                isSelected: currentTab == ChefPlanetNavTab.search,
                onTap: () {
                  if (onSearchTap != null) {
                    onSearchTap!();
                    return;
                  }
                  _goTo(context, ChefPlanetNavTab.search);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goTo(BuildContext context, ChefPlanetNavTab tab) {
    switch (tab) {
      case ChefPlanetNavTab.home:
        context.go('/');
        break;
      case ChefPlanetNavTab.menu:
        context.go('/menu');
        break;
      case ChefPlanetNavTab.search:
        context.go('/search');
        break;
      case ChefPlanetNavTab.orders:
        context.go('/orders');
        break;
      case ChefPlanetNavTab.profile:
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        context.go(authProvider.isAuthenticated ? '/profile' : '/login');
        break;
    }
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF1E7) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: isSelected
                  ? Border.all(color: const Color(0xFFFFD8BF))
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.textPrimaryColor
                        : AppTheme.textSecondaryColor,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onTap, this.isSelected = false});

  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(isSelected ? 0.24 : 0.18),
            blurRadius: isSelected ? 22 : 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? const Color(0xFFE56F10) : AppTheme.primaryColor,
          border: Border.all(color: AppTheme.surfaceColor, width: 5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Center(
              child: Icon(Icons.search_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
