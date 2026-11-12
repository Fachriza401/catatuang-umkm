# Spesifikasi Kebutuhan Sistem - CatatUang

Dokumen ini menyelaraskan kebutuhan sistem dengan pengembangan proyek CatatUang pada folder `Blajar`. Aplikasi yang dikembangkan adalah **CatatUang**, sistem pembukuan digital untuk UMKM berbasis mobile (Flutter) dan web dashboard (React + TypeScript), dengan backend Supabase dan penyimpanan lokal offline-first.

---

## 1. Nama dan Gambaran Umum Aplikasi

Nama aplikasi adalah **CatatUang**. Aplikasi merupakan sistem pembukuan digital berbasis mobile dan web yang ditujukan untuk mempermudah pencatatan keuangan usaha kecil dan menengah (UMKM), khususnya pemasukan, pengeluaran, utang/piutang, dan laporan.

Pada sisi pengguna, sistem menyediakan splash/onboarding, autentikasi, dashboard ringkasan keuangan, pencatatan transaksi, pengelolaan kategori dan metode pembayaran, utang/piutang, laporan, kalkulator Rupiah, pengaturan profil usaha, langganan paket, dan sinkronisasi data. Aplikasi mobile dan dashboard web digunakan oleh pemilik usaha melalui akun Owner yang sama; dashboard web menyediakan tampilan pengelolaan yang lebih lengkap.

---

## 2. Lingkup Sistem

| Area | Fungsi Utama |
| :--- | :--- |
| Pemilik Usaha (Owner) | Satu-satunya pengguna untuk setiap usaha. Mengelola pembukuan melalui aplikasi mobile atau web dengan akun yang sama. |
| Aplikasi Mobile | Mencatat dan melihat transaksi, utang/piutang, laporan, serta fitur mobile lainnya; transaksi dapat dicatat saat offline. |
| Dashboard Web | Menyediakan tampilan browser yang lebih lengkap untuk melihat dan mengelola data usaha milik Owner. |
| Database | Menyimpan akun pemilik, profil usaha, transaksi, kategori, utang, pembayaran utang, langganan, order pembayaran, dan permintaan sinkronisasi. |

---

## 3. Aktor Sistem

| Aktor | Peran Detail | Contoh Skenario |
| :--- | :--- | :--- |
| Pemilik Usaha (Owner) | Pengguna terdaftar yang mengelola usahanya sendiri melalui satu akun. | Pemilik masuk ke aplikasi mobile atau web menggunakan akun yang sama, mencatat transaksi, mengelola utang/piutang, dan melihat laporan. |
---

## 4. Kebutuhan Fungsional

| Kode | Kebutuhan | Penjelasan Operasional |
| :--- | :--- | :--- |
| FR-01 | Autentikasi Pengguna | Pemilik usaha dapat mendaftar, masuk, keluar, memulihkan password, dan memverifikasi email. Akun Owner yang sama digunakan di aplikasi mobile dan web. |
| FR-02 | Onboarding & Profil Usaha | Pengguna dapat menyiapkan profil usaha (nama usaha, jenis, kontak, alamat) dan memperbaruinya sesuai hak akses. |
| FR-03 | Usaha Milik Pemilik | Setiap akun Owner mengelola profil dan data satu usaha miliknya sendiri; tidak ada pemilihan usaha anggota. |
| FR-04 | Dashboard & Ringkasan Keuangan | Sistem menampilkan saldo kas, total pemasukan/pengeluaran, grafik, filter periode, ringkasan utang/piutang, serta proteksi saldo dengan PIN. |
| FR-05 | Kelola Transaksi | Pengguna dapat menambah, mengubah, menghapus (soft delete), dan melihat transaksi pemasukan/pengeluaran beserta nominal, kategori, metode pembayaran, tanggal, catatan, dan lampiran. |
| FR-06 | Kategori & Metode Pembayaran | Pengguna dapat mengelola kategori transaksi dan metode pembayaran yang digunakan pada pencatatan. |
| FR-07 | Utang & Piutang | Sistem mencatat utang/piutang, detail, cicilan pembayaran, status pelunasan, dan pengingat jatuh tempo. |
| FR-08 | Laporan Keuangan | Sistem menyediakan laporan keuangan berdasarkan rentang tanggal dan mengekspor hasil ke PDF/Excel. |
| FR-09 | Kalkulator Rupiah | Pengguna dapat menggunakan kalkulator Rupiah untuk membantu perhitungan nominal transaksi. |
| FR-10 | Sinkronisasi Offline-First | Sistem menyimpan transaksi ke database lokal terlebih dahulu, mengantrekan sinkronisasi, melakukan retry dengan backoff, menarik perubahan remote, dan menangani konflik. |
| FR-11 | Akun Pemilik Usaha | Setiap usaha dikelola oleh satu akun Owner. Tidak tersedia pendaftaran atau pengelolaan akun anggota dan peran Admin/Kasir/Viewer. |
| FR-12 | Langganan & Pembayaran | Pengguna dapat melihat paket (Free/Premium/Business), membuat checkout pembayaran melalui Midtrans, dan status paket diperbarui melalui webhook. |
| FR-13 | Notifikasi & Pengingat | Sistem menyediakan pengingat jatuh tempo utang/piutang dan informasi status sinkronisasi. |
| FR-14 | Web Dashboard | Pemilik dapat menggunakan akun yang sama untuk mengelola data usaha melalui dashboard web dengan tampilan yang lebih lengkap. |
| FR-15 | Reset Password | Sistem menyimpan permintaan reset password untuk diproses melalui mekanisme autentikasi yang disediakan. |
| FR-16 | Audit & Riwayat | Tanggal pembuatan dan pembaruan transaksi, utang, pembayaran, dan permintaan sinkronisasi disimpan untuk penelusuran aktivitas. |

---

## 5. Kebutuhan Non-Fungsional

| Kode | Aspek | Kebutuhan |
| :--- | :--- | :--- |
| NFR-01 | Usability | Antarmuka mudah dipahami, konsisten, dan meminimalkan jumlah langkah pada pencatatan transaksi. |
| NFR-02 | Performance | Pencarian/filter transaksi, perpindahan halaman, dan akses data lokal harus responsif pada perangkat yang mendukung aplikasi. |
| NFR-03 | Security | Data setiap usaha hanya dapat diakses akun Owner terkait; password tidak disimpan dalam bentuk teks biasa; mutasi data wajib melalui RPC/kebijakan RLS. |
| NFR-04 | Integrity | Data transaksi dan item terkait harus konsisten; penghapusan transaksi menggunakan soft delete; pembayaran cicilan terhubung atomik ke transaksi kas. |
| NFR-05 | Availability | Fitur lokal dapat berjalan ketika database lokal tersedia; fitur jaringan mengikuti ketersediaan koneksi dan backend. |
| NFR-06 | Maintainability | Kode dan database dipisahkan berdasarkan model, provider, screen, service, dan helper agar mudah dirawat. |
| NFR-07 | Scalability | Struktur tabel dan relasi dibuat agar dapat dikembangkan untuk usaha, transaksi, dan langganan yang lebih banyak. |
| NFR-08 | Auditability | Tanggal pembuatan/pembaruan transaksi, utang, pembayaran, notifikasi, dan permintaan reset disimpan agar aktivitas dapat ditelusuri. |

---

## 6. Skenario Penggunaan Sehari-hari

**Skenario Pemilik Usaha:** Pemilik mendaftar dan masuk dengan satu akun, lalu menyiapkan profil usaha. Pemilik mencatat transaksi dan utang/piutang, mengelola kategori, serta melihat ringkasan dan laporan. Di aplikasi mobile, transaksi tetap tersimpan lokal ketika offline dan disinkronkan saat koneksi tersedia.

**Skenario Web Dashboard:** Pemilik masuk melalui browser menggunakan akun yang sama dengan aplikasi mobile. Web menyediakan tampilan yang lebih lengkap untuk memantau saldo, transaksi, kategori, utang/piutang, dan laporan usaha.
