# Matriks Hak Akses dan RLS CatatUang

CatatUang menggunakan satu akun Owner untuk setiap usaha. Pemilik memakai akun
yang sama pada aplikasi mobile dan dashboard web. Tidak ada akun anggota atau
peran Admin, Kasir, dan Viewer. Migrasi
`20261107040000_owner_only_business_access.sql` menghapus relasi dan endpoint
anggota yang lama; akun Auth mereka tidak ikut dihapus.

## Dasar Otorisasi

- `current_business_id()` mengembalikan `auth.uid()`.
- `has_business_role()` hanya mengizinkan akun terautentikasi mengakses bisnis
  yang ID-nya sama dengan `auth.uid()` dan ketika peran yang diminta mencakup
  `owner`.
- Setiap usaha terhubung ke pemilik melalui `business_profiles.user_id`.
- Mutasi transaksi dilakukan melalui RPC, bukan penulisan langsung dari client.
- RLS tetap membatasi akses meskipun client mengirim `business_id` atau
  `user_id` yang berbeda.

## Ringkasan Hak Akses

| Data | Owner usaha | Akun lain | Tanpa autentikasi | Aturan utama |
|---|---:|---:|---:|---|
| `business_profiles` | Baca dan ubah milik sendiri | Ditolak | Ditolak | Profil terkait `auth.uid()`; perubahan melalui RPC |
| `transactions` | Baca dan mutasi milik sendiri | Ditolak | Ditolak | `sync_transaction`; edit dan hapus mengikuti otorisasi Owner |
| `debts` | Baca, tambah, dan ubah milik sendiri | Ditolak | Ditolak | RLS memeriksa ID usaha Owner |
| `debt_payments` | Baca; pembayaran melalui RPC | Ditolak | Ditolak | `record_debt_payment` memperbarui cicilan dan transaksi kas secara atomik |
| `categories` | Baca dan kelola milik sendiri | Ditolak | Ditolak | RLS menggunakan business ID dari sesi Owner |
| `business_subscriptions` | Baca milik sendiri | Ditolak | Ditolak | Perubahan entitlement hanya melalui backend |
| `payment_orders` | Baca milik sendiri | Ditolak | Ditolak | Dibuat dan diproses Edge Function/webhook |
| `transaction-attachments` | Akses sesuai paket dan kebijakan storage | Ditolak | Ditolak | Bucket privat; policy memeriksa business ID pada path |
| `business_plans` | Baca | Baca | Ditolak | Penulisan hanya melalui migrasi atau backend tepercaya |

`business_members` dan kolom batas jumlah anggota pada paket tidak lagi menjadi
bagian dari skema aktif. Setiap pendaftaran membuat akun Owner baru; akun lama
yang sebelumnya hanya menjadi anggota tidak lagi memperoleh akses ke data usaha
lain dan tetap dapat membuat usaha sendiri.

Validasi regresi basis data berada di
`supabase/tests/business_security.test.sql`; jalankan dengan `supabase test db`
setelah menerapkan semua migrasi.
