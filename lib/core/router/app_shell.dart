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
    icon: Icon(Icons.calculate_outlined),
    selectedIcon: Icon(Icons.calculate_rounded),
    label: 'Kalkulator',
  ),
  NavigationDestination(
    icon: Icon(Icons.analytics_outlined),
    selectedIcon: Icon(Icons.analytics_rounded),
    label: 'Laporan',
  ),
  NavigationDestination(
    icon: Icon(Icons.storefront_outlined),
    selectedIcon: Icon(Icons.storefront_rounded),
    label: 'Profil',
  ),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        height: 72,
        indicatorColor: AppColors.primarySoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: appNavigationDestinations,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
