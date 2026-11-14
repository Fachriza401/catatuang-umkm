import 'package:catat_uang/core/router/app_routes.dart';
import 'package:catat_uang/core/theme/app_theme.dart';
import 'package:catat_uang/features/belajar/data/learning_modules.dart';
import 'package:catat_uang/features/belajar/presentation/pages/belajar_screen.dart';
import 'package:catat_uang/features/belajar/presentation/pages/materi_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('materi dapat dibuka dan kembali ke daftar', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.belajar,
      routes: [
        GoRoute(
          path: AppRoutes.belajar,
          builder: (context, state) => const BelajarScreen(),
          routes: [
            GoRoute(
              path: ':slug',
              builder: (context, state) {
                final slug = state.pathParameters['slug'];
                final module = learningModules
                    .where((item) => item.slug == slug)
                    .firstOrNull;
                return MateriDetailScreen(module: module);
              },
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

    expect(find.text('Panduan usaha sehari-hari'), findsOneWidget);
    for (final module in learningModules) {
      await tester.ensureVisible(find.text(module.title));
      await tester.pumpAndSettle();
      await tester.tap(find.text(module.title));
      await tester.pumpAndSettle();
      expect(find.text(module.sections.first.heading), findsOneWidget);
      await tester.tap(find.byTooltip('Kembali ke Belajar'));
      await tester.pumpAndSettle();
      expect(find.text('Panduan usaha sehari-hari'), findsOneWidget);
    }

    await tester.ensureVisible(
      find.text('Dasar-Dasar Pencatatan Arus Kas Harian'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dasar-Dasar Pencatatan Arus Kas Harian'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Kembali ke daftar materi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kembali ke daftar materi'));
    await tester.pumpAndSettle();
    expect(find.text('Panduan usaha sehari-hari'), findsOneWidget);
  });

  testWidgets('detail yang tidak dikenal menunjukkan jalan kembali', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => const MateriDetailScreen(module: null),
        ),
      ),
    );

    expect(
      find.text('Materi ini tidak tersedia. Kembali ke daftar Belajar.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
