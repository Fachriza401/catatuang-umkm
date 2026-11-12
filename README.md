# CatatUang

A new Flutter project.

## Penyimpanan Offline-First

Semua transaksi ditulis lebih dulu ke SQLite melalui Drift. Penyimpanan transaksi
dan `transaction_outbox_entries` dilakukan di satu transaksi SQLite, sehingga
tidak ada perubahan lokal tanpa antrean sinkronisasi atau antrean tanpa datanya.
UUID transaksi stabil digunakan sebagai identitas server; setiap perubahan
outbox menyimpan UUID idempotency key sendiri. Retry memakai key outbox yang
sama, jadi respons yang hilang setelah commit server tidak membuat transaksi
duplikat.

`TransactionRepository` membaca dan menulis database lokal. `TransactionSyncService`
mengirim antrean ke Supabase melalui RPC `sync_transaction`, menarik perubahan
remote, dan tidak menunggu jaringan untuk menyelesaikan pencatatan lokal.
Connectivity Plus memicu percobaan saat jaringan berubah, tetapi sebelum
mengirim data service juga melakukan query Supabase dengan timeout 10 detik.
Indikator koneksi perangkat saja tidak dianggap bukti endpoint tersedia.

Kegagalan mempertahankan transaksi dan outbox di perangkat. Retry memakai
exponential backoff `2 * 2^attempt` detik, dibatasi maksimum 6 jam, ditambah
pemeriksaan berkala setiap 30 detik. Saat service dimulai, status `syncing` yang
tertinggal dikembalikan ke `pending`; request yang diulang menggunakan key
idempotency yang sama. Perubahan remote memakai optimistic concurrency dengan
`updated_at`; perbedaan versi berstatus `conflict` dan pengguna dapat memilih
data lokal atau server.

Status yang disimpan dan ditampilkan: Menunggu (`pending`), Menyinkronkan
(`syncing`), Tersinkron (`synced`), Gagal (`failed`), dan Konflik (`conflict`).
Transaksi lokal tidak dihapus ketika request gagal. Hapus transaksi menggunakan
soft delete dan ikut dikirim melalui outbox.

## Supabase

Terapkan semua migration di `supabase/migrations` berurutan berdasarkan nama
(misalnya dengan `supabase db push`). Migration terakhir,
`20261107040000_owner_only_business_access.sql`, menetapkan satu akun Owner per
usaha dan menghapus dukungan akses anggota tanpa menghapus akun Auth mereka.

RPC memeriksa identitas user, mencatat response untuk idempotency key dalam
transaksi database yang sama dengan perubahan transaksi, dan mengembalikan
snapshot remote ketika mendeteksi konflik. Jangan memberikan akses langsung
ke tabel internal `transaction_sync_requests`.

## Keamanan dan Paket

`transactions.user_id`, `debts.user_id`, dan `debt_payments.user_id` adalah ID
akun pemilik usaha. Aplikasi mobile dan web menggunakan akun Owner yang sama;
tidak ada akun atau peran Admin, Kasir, maupun Viewer. Setiap akun hanya dapat
membaca dan mengubah data usahanya sendiri. Mutasi transaksi wajib lewat RPC
dan otorisasi diperiksa di PostgreSQL.

Paket awal: Free memiliki 200 transaksi per bulan tanpa lampiran; Premium
memiliki 5.000 transaksi per bulan; Business memiliki transaksi tanpa batas.
Semua paket menggunakan satu akun Owner untuk tiap usaha. Premium dan Business
dapat memakai bukti transaksi privat. Batas transaksi dan upload ditegakkan
oleh RPC atau Storage RLS, bukan hanya kontrol UI. Entitlement berbayar hanya
aktif jika status server
`active` dan periode langganan belum berakhir. Client tidak dapat menulis tabel
langganan; backend provisioning hanya menerima role `service_role`.

Bucket `transaction-attachments` bersifat privat. Flutter menyimpan path object,
lalu meminta signed URL sementara untuk preview. Deploy penghapusan akun dengan
`supabase functions deploy delete-account`; fungsi memvalidasi JWT, menghapus
lampiran tenant owner, lalu menghapus user melalui Auth Admin API. Atur
`SUPABASE_SERVICE_ROLE_KEY` sebagai secret Edge Function di Supabase saja. Jangan
menaruhnya di `--dart-define`, asset, atau konfigurasi Flutter.

Paket berbayar dibeli melalui Midtrans Snap. `payment_orders` menyimpan order
pending beserta nominal dan token Snap; harga paket dibaca dari
`business_plans.price_amount`, bukan dari Flutter. `create-subscription-checkout`
memvalidasi JWT, memastikan pemanggil adalah owner, membuat order, lalu meminta
token Snap ke Midtrans. `midtrans-webhook` memverifikasi signature SHA-512,
mencocokkan nominal, dan memanggil `apply_payment_notification`. Fungsi SQL itu
mengunci order, memperpanjang `current_period_end` secara idempotent, dan baru
mengaktifkan paket setelah status pembayaran `paid`. Client tidak dapat
mengaktifkan Premium atau Business sendiri.

Deploy Edge Function dan atur secret Midtrans hanya di Supabase:

```bash
supabase functions deploy create-subscription-checkout
supabase functions deploy midtrans-webhook --no-verify-jwt
supabase secrets set MIDTRANS_SERVER_KEY=<server-key>
supabase secrets set MIDTRANS_IS_PRODUCTION=false
```

Daftarkan URL webhook `https://<project-ref>.supabase.co/functions/v1/midtrans-webhook`
pada dashboard Midtrans. Untuk production, ubah `MIDTRANS_IS_PRODUCTION`
menjadi `true` dan pakai server key production. Notifikasi `refund` penuh
menurunkan paket kembali ke Free; `partial_refund` diabaikan.

## Pengujian

Jalankan dengan versi Flutter/Dart yang memenuhi `environment.sdk` di
`pubspec.yaml`:

```powershell
flutter test test/features/transactions/transaction_outbox_test.dart
flutter test
```

Test outbox meliputi rollback atomik ketika enqueue gagal, data tetap lokal saat
endpoint gagal, batas waktu retry, serta proses ditutup ketika status masih
`syncing` lalu database dibuka kembali dan antrean dipulihkan. Test ini tidak
membutuhkan koneksi Supabase. Pengujian integrasi RPC membutuhkan proyek Supabase
uji dengan migration di atas dan sesi authenticated.

Security tests PostgreSQL ada di `supabase/tests/business_security.test.sql`.
Jalankan setelah migration pada Supabase lokal dengan `supabase test db`; tes ini
mencakup isolasi data per Owner, akses akun lama yang pernah menjadi anggota,
kuota Free, dan perubahan subscription yang ditolak dari client.

# catatuang-umkm
