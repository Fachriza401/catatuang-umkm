# Kebijakan Privasi CatatUang

**Status dokumen:** DRAFT. Jangan dipublikasikan sebelum semua placeholder, alur data production, dan kontak pengendali data dikonfirmasi.

**Berlaku sejak:** [TANGGAL BERLAKU]

CatatUang dikelola oleh **[NAMA BADAN USAHA / PENGEMBANG]** ("kami"). Kebijakan ini menjelaskan data yang diproses ketika Anda menggunakan aplikasi CatatUang.

## Data yang diproses

- Data akun: alamat email, nama yang Anda masukkan, dan status autentikasi.
- Data usaha: nama usaha dan informasi profil yang Anda isi, termasuk alamat atau nomor telepon bila disediakan.
- Data pembukuan: transaksi, kategori, metode pembayaran, utang/piutang, nama dan nomor telepon pihak terkait bila Anda memasukkannya, serta tanggal dan catatan.
- Lampiran: gambar bukti transaksi yang Anda pilih untuk diunggah. Lampiran disimpan pada penyimpanan privat dan hanya tersedia sesuai izin akun dan paket.
- Data teknis layanan: data yang diperlukan penyedia autentikasi, database, penyimpanan, dan distribusi aplikasi untuk mengoperasikan layanan.

CatatUang menyimpan data pembukuan secara lokal pada perangkat dan menyinkronkannya ke Supabase ketika koneksi tersedia. Jangan masukkan data pribadi pihak lain kecuali Anda memiliki dasar dan izin yang sesuai.

## Tujuan penggunaan

Kami menggunakan data untuk menyediakan autentikasi, pencatatan dan sinkronisasi pembukuan, pengelolaan anggota usaha, lampiran bukti transaksi, keamanan, dukungan, serta pemenuhan kewajiban hukum yang berlaku.

## Penyedia layanan dan pembagian data

Data yang disinkronkan diproses oleh Supabase sebagai penyedia layanan backend dan oleh Google Play untuk distribusi aplikasi. **[KONFIRMASI NAMA, LOKASI PEMROSESAN, DAN SUB-PROSESOR YANG AKTIF DI PRODUCTION.]** Kami tidak menjual data pribadi. Kami tidak memasukkan kunci `service_role` Supabase ke aplikasi.

## Penyimpanan dan keamanan

Data lokal disimpan pada perangkat. Data cloud disimpan selama akun/layanan aktif dan sesuai konfigurasi retensi production. Kami menerapkan pembatasan akses berbasis akun dan usaha, Row Level Security, serta penyimpanan lampiran privat. Tidak ada metode transmisi atau penyimpanan yang dapat dijamin sepenuhnya aman.

**[TENTUKAN JADWAL RETENSI, MASA RETENSI BACKUP, REGION SUPABASE, DAN PROSEDUR RESPONS INSIDEN SEBELUM PUBLIKASI.]**

## Hak pengguna dan penghapusan akun

Anda dapat meminta penghapusan akun melalui menu pengaturan akun di aplikasi. Penghapusan akan menghapus akun dan data terkait sesuai kemampuan sistem; sebagian data dapat tetap disimpan jika diwajibkan hukum atau berada dalam backup sementara sesuai jadwal retensi. Hubungi **[EMAIL PRIVASI / DUKUNGAN]** untuk permintaan akses, koreksi, penghapusan, atau pertanyaan privasi.

**[UJI ALUR PENGHAPUSAN AKUN DAN LAMPIRAN DI PROJECT PRODUCTION SEBELUM MENYATAKAN KEBIJAKAN INI BERLAKU.]**

## Anak-anak

**[TENTUKAN TARGET USIA DAN KEBIJAKAN UNTUK ANAK. JANGAN MENGISI PERNYATAAN INI BERDASARKAN ASUMSI.]**

## Perubahan kebijakan

Kebijakan yang diperbarui akan dipublikasikan pada **[URL KEBIJAKAN PRIVASI PUBLIK]** dengan tanggal berlaku yang baru.

## Kontak

Pengendali data: **[NAMA BADAN USAHA / PENGEMBANG]**  
Alamat: **[ALAMAT KONTAK, JIKA DIPERLUKAN]**  
Email privasi: **[EMAIL PRIVASI]**  
URL: **[URL WEBSITE / KEBIJAKAN PRIVASI]**
