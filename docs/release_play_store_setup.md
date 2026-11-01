# Persiapan Release Aplikasi ke Play Store

## 1) Buat keystore release

Jalankan script berikut di Windows PowerShell dari repo:

```powershell
Set-Location D:\Blajar
.\scripts\generate_android_keystore.ps1
```

Script akan membuat:

- `android/upload-keystore.jks`
- `android/key.properties`

Pastikan file itu tidak masuk Git. Saat ini file sudah di-ignore di `.gitignore`.

## 2) Validasi konfigurasi release

Setelah keystore dibuat, jalankan:

```powershell
Set-Location D:\Blajar
flutter build appbundle --release
```

Jika sukses, file AAB akan dibuat di:

- `build/app/outputs/bundle/release/app-release.aab`

## 3) Upload ke Play Console

1. Buka Google Play Console.
2. Buat app baru atau pilih app existing.
3. Masuk ke Setup > App integrity.
4. Upload key dan upload certificate.
5. Pastikan package name sesuai: `com.catatuang.catat_uang`.
6. Siapkan data app: privacy policy, store listing, contact details, ads disclosure, dan content rating.

## 4) Variabel runtime Supabase

Script build release membaca `SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY` dari environment, lalu menjalankan analyzer, test, dan build AAB. Isi variabel di PowerShell tanpa memasukkan `service_role` key:

```powershell
$env:SUPABASE_URL = 'https://<project-ref>.supabase.co'
$env:SUPABASE_PUBLISHABLE_KEY = '<publishable-key>'
Set-Location D:\Blajar
.\scripts\build_release_android.ps1
```

> Jangan menaruh `SUPABASE_SERVICE_ROLE_KEY` di Flutter, asset, atau build config.

## 5) Checklist akhir sebelum rilis

- [ ] keystore release valid
- [ ] `android/key.properties` ada dan aman
- [ ] privacy policy final
- [ ] store listing siap
- [ ] Data safety dan content rating sesuai implementasi production
- [ ] Play Console app complete
- [ ] Supabase production project aktif
- [ ] RLS dan tenant policy telah diuji
- [ ] app bundle berhasil dibuat
- [ ] smoke test manual di device real
