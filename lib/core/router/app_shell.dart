import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

const appNavigationDestinations = <NavigationDestination>[
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home_rounded),
    label: 'Beranda',
  ),
  NavigationDestination(
    icon: Icon(Icons.receipt_long_outlined),
    selectedIcon: Icon(Icons.receipt_long_rounded),
    label: 'Transaksi',
  ),
  NavigationDestination(
    icon: Icon(Icons.handshake_outlined),
    selectedIcon: Icon(Icons.handshake_rounded),
    label: 'Utang',
  ),
  NavigationDestination(
    icon: Icon(Icons.menu_book_outlined),
    selectedIcon: Icon(Icons.menu_book_rounded),
    label: 'Belajar',
  ),
  NavigationDestination(
    icon: Icon(Icons.more_horiz),
    selectedIcon: Icon(Icons.more_horiz),
    label: 'Lainnya',
  ),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = switch (navigationShell.currentIndex) {
      0 => 0,
      1 => 1,
      2 => 2,
      6 => 3,
      _ => 4,
    };

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        height: 72,
        indicatorColor: AppColors.primarySoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: appNavigationDestinations,
        onDestinationSelected: (index) {
          if (index == 3) {
            navigationShell.goBranch(
              6,
              initialLocation: navigationShell.currentIndex == 6,
            );
            return;
          }
          if (index == 4) {
            _showMoreDestinations(context);
            return;
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }

  void _showMoreDestinations(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MoreDestinationTile(
              icon: Icons.calculate_outlined,
              label: 'Kalkulator',
              onTap: () => _selectMoreDestination(sheetContext, 3),
            ),
            _MoreDestinationTile(
              icon: Icons.analytics_outlined,
              label: 'Laporan',
              onTap: () => _selectMoreDestination(sheetContext, 4),
            ),
            _MoreDestinationTile(
              icon: Icons.storefront_outlined,
              label: 'Profil',
              onTap: () => _selectMoreDestination(sheetContext, 5),
            ),
          ],
        ),
      ),
    );
  }

  void _selectMoreDestination(BuildContext context, int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: navigationShell.currentIndex == branchIndex,
    );
    Navigator.of(context).pop();
  }
}

class _MoreDestinationTile extends StatelessWidget {
  const _MoreDestinationTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
  }
}
