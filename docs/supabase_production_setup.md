# Supabase Production Setup

## 1) Buat akun dan project Supabase

> Saya tidak dapat membuat akun Supabase untuk Anda dari lingkungan ini karena ini memerlukan akses browser/akun Google dan otorisasi dari owner aplikasi.

Langkah yang harus dilakukan:

1. Buka https://supabase.com
2. Login menggunakan akun Google / GitHub / email yang berhak.
3. Buat project baru.
4. Pilih region yang dekat dengan pengguna utama.
5. Simpan Project URL dan publishable/anon key untuk konfigurasi client.
6. Jangan kirim atau menempelkan `service_role` key ke chat, Flutter, atau Git. Atur key itu langsung sebagai Supabase secret hanya bila Edge Function membutuhkannya.

## 2) Jalankan migration

Install Supabase CLI, login secara lokal, lalu link project production yang benar. Review migration sebelum deploy. Dari root repo:

```bash
supabase login
supabase link --project-ref <project-ref>
supabase migration list
supabase db push
```

Jangan gunakan `supabase db reset` terhadap project production. Untuk uji lokal, mulai stack lokal lalu jalankan security test:

```bash
supabase start
supabase test db
```

Pastikan urutan eksekusi:

1. `supabase/migrations/20261031000000_init_catat_uang.sql`
2. `supabase/migrations/20261031010000_debts_and_payments.sql`
3. `supabase/migrations/20261101000000_transaction_sync_rpc.sql`
4. `supabase/migrations/20261101020000_business_security_and_plans.sql`

## 3) Konfigurasi aplikasi production

Build aplikasi di lingkungan release dengan URL dan publishable key:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

Masukkan keduanya langsung sebagai environment PowerShell lokal, lalu jalankan `scripts/build_release_android.ps1`. Jangan commit file konfigurasi yang memuat key.

Untuk Edge Function, set secret yang dibutuhkan melalui Supabase CLI atau dashboard, bukan sebagai variabel client:

```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<secret>
```

## 4) RLS dan security checklist

- Pastikan tenant ID hanya berasal dari sesi user yang valid.
- Gunakan `auth.uid()` dan query ke `business_members` / `business_access`.
- Pastikan `transaction_sync_requests` tidak bisa diakses langsung dari client.
- Batasi file upload ke bucket `transaction-attachments` dengan private policy.
- Gunakan Edge Function `delete-account` untuk penghapusan akun aman.

## 5) Build app dengan konfigurasi Supabase

```powershell
flutter run --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<anon-or-publishable-key>
```

Untuk release:

```powershell
flutter build appbundle --release --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<anon-or-publishable-key>
```

## 5.1) Template email verifikasi (kode OTP)

Aplikasi mendukung verifikasi dengan kode OTP 6 digit agar tidak bergantung pada deep link/browser. Di dashboard Supabase buka **Authentication > Emails > Confirm signup**, lalu tambahkan kode ke template:

```html
Kode verifikasi Anda: {{ .Token }}
```

Biarkan `{{ .ConfirmationURL }}` tetap ada jika tautan juga ingin dipertahankan. Setelah template diubah, gunakan tombol "Kirim Ulang Email" pada halaman verifikasi lalu masukkan kode 6 digit di aplikasi.

## 6) Validasi akhir

- [ ] auth login berhasil
- [ ] insert transaksi lokal dan sync berhasil
- [ ] role owner/admin/cashier/viewer sesuai
- [ ] RLS gagal saat cross-tenant
- [ ] upload attachment berhasil dengan signed URL
- [ ] delete-account utility berjalan aman

## 7) Pengingat keamanan

- `SUPABASE_SERVICE_ROLE_KEY` tidak boleh dikirim ke Flutter.
- `SUPABASE_PUBLISHABLE_KEY` hanya untuk client-side.
- Secret backend harus disimpan di Supabase Secrets / managed environment.
