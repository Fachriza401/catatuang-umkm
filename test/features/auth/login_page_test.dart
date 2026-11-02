import 'package:catat_uang/core/theme/app_theme.dart';
import 'package:catat_uang/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LoginPage merender formulir login dan komponen pendukung dengan benar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi judul dan pesan sambutan
    expect(find.text('Selamat Datang Kembali 👋'), findsOneWidget);
    expect(find.text('Supabase Cloud Aktif'), findsOneWidget);

    // Verifikasi field formulir
    expect(find.text('Email Usaha'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Ingat email saya'), findsOneWidget);
    expect(find.text('Lupa password?'), findsOneWidget);
    expect(find.text('Masuk ke Akun'), findsOneWidget);
    expect(find.text('Daftar Sekarang'), findsOneWidget);

    // Coba tekan Masuk tanpa mengisi form untuk memicu validasi
    await tester.ensureVisible(find.text('Masuk ke Akun'));
    await tester.tap(find.text('Masuk ke Akun'));
    await tester.pumpAndSettle();

    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Kata Sandi wajib diisi.'), findsOneWidget);
  });
}
