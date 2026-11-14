import 'package:catat_uang/core/router/app_shell.dart';
import 'package:catat_uang/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('navigation bar tetap rapi pada layar sempit', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            height: 72,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: appNavigationDestinations,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final destination in appNavigationDestinations) {
      expect(find.text(destination.label), findsOneWidget);
    }
    expect(
      appNavigationDestinations.map((item) => item.label),
      contains('Belajar'),
    );
  });

  testWidgets('Belajar dan menu tambahan membuka cabang yang benar', (
    tester,
  ) async {
    const destinations = [
      ('/home', 'Beranda'),
      ('/transactions', 'Transaksi'),
      ('/debts', 'Utang'),
      ('/calculator', 'Kalkulator'),
      ('/reports', 'Laporan'),
      ('/settings', 'Profil'),
      ('/belajar', 'Belajar'),
    ];
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            for (final (path, label) in destinations)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (context, state) =>
                        Scaffold(body: Center(child: Text('$label screen'))),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lainnya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kalkulator'));
    await tester.pumpAndSettle();
    expect(find.text('Kalkulator screen'), findsOneWidget);

    await tester.tap(find.text('Belajar'));
    await tester.pumpAndSettle();
    expect(find.text('Belajar screen'), findsOneWidget);
  });
}
