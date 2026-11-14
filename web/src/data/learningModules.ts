export interface LearningSection {
  heading: string
  body: string
  points: string[]
}

export interface LearningModule {
  slug: string
  topic: string
  title: string
  summary: string
  sections: LearningSection[]
}

export const learningModules: LearningModule[] = [
  {
    slug: 'arus-kas-harian',
    topic: 'Pencatatan',
    title: 'Dasar-Dasar Pencatatan Arus Kas Harian',
    summary: 'Catat uang yang benar-benar masuk dan keluar agar saldo usaha mudah diperiksa.',
    sections: [
      {
        heading: 'Catat saat transaksi terjadi',
        body: 'Tuliskan tanggal, keterangan, kategori, dan nominal setiap penerimaan atau pembayaran. Catatan yang dibuat pada hari yang sama lebih mudah dicocokkan dengan bukti transaksi.',
        points: [
          'Pisahkan pemasukan dari penjualan dan tambahan modal.',
          'Catat pengeluaran usaha, bukan pengeluaran pribadi.',
          'Simpan bukti pembayaran untuk membantu pemeriksaan.',
        ],
      },
      {
        heading: 'Pisahkan uang usaha',
        body: 'Gunakan tempat penyimpanan atau rekening yang berbeda untuk uang usaha dan uang pribadi. Pemisahan ini membuat saldo usaha tidak tercampur dengan kebutuhan rumah tangga.',
        points: [
          'Tentukan cara mengambil uang untuk kebutuhan pribadi.',
          'Catat pengambilan tersebut agar saldo tetap dapat dijelaskan.',
        ],
      },
      {
        heading: 'Cocokkan saldo secara berkala',
        body: 'Bandingkan saldo menurut catatan dengan uang tunai dan saldo rekening. Jika berbeda, telusuri transaksi yang belum dicatat atau salah dimasukkan.',
        points: [
          'Periksa kas dan rekening secara terpisah.',
          'Perbaiki catatan berdasarkan bukti, bukan perkiraan.',
        ],
      },
    ],
  },
  {
    slug: 'utang-piutang-usaha',
    topic: 'Utang dan piutang',
    title: 'Tips Mengelola Utang Piutang Usaha agar Lancar',
    summary: 'Buat kesepakatan yang jelas dan pantau kewajiban sebelum jatuh tempo.',
    sections: [
      {
        heading: 'Tuliskan setiap kesepakatan',
        body: 'Catat pihak terkait, nilai, tanggal, tujuan, jadwal pembayaran, dan bukti kesepakatan. Informasi yang sama membantu pemilik usaha dan pelanggan atau pemasok menghindari salah paham.',
        points: [
          'Simpan bukti transaksi dan komunikasi penting.',
          'Pastikan kedua pihak memahami jadwal pembayaran.',
        ],
      },
      {
        heading: 'Pantau piutang pelanggan',
        body: 'Periksa daftar tagihan secara rutin dan hubungi pelanggan dengan bahasa yang sopan sebelum atau saat jatuh tempo. Perbarui status segera setelah pembayaran diterima.',
        points: [
          'Catat pembayaran sebagian sebagai pengurang sisa tagihan.',
          'Jangan mencatat piutang sebagai uang tunai yang sudah tersedia.',
        ],
      },
      {
        heading: 'Rencanakan pembayaran utang',
        body: 'Susun kewajiban berdasarkan tanggal jatuh tempo dan kemampuan kas. Sebelum mengambil utang baru, pastikan arus kas usaha dapat mendukung pembayarannya.',
        points: [
          'Catat pokok, biaya, dan pembayaran secara terpisah.',
          'Hubungi pemberi pinjaman lebih awal jika ada kendala pembayaran.',
        ],
      },
    ],
  },
  {
    slug: 'harga-jual-produk',
    topic: 'Harga jual',
    title: 'Strategi Menentukan Harga Jual Produk UMKM',
    summary: 'Hitung biaya produk secara menyeluruh, lalu tentukan harga yang sesuai dengan pasar dan tujuan usaha.',
    sections: [
      {
        heading: 'Hitung biaya per produk',
        body: 'Mulai dari bahan baku dan kemasan. Tambahkan biaya produksi lain yang terkait, seperti tenaga kerja dan bagian biaya operasional, supaya biaya produk tidak terlihat lebih rendah dari keadaan sebenarnya.',
        points: [
          'Gunakan biaya yang benar-benar dikeluarkan usaha.',
          'Tinjau kembali biaya saat harga bahan atau proses berubah.',
        ],
      },
      {
        heading: 'Tentukan ruang keuntungan',
        body: 'Harga jual perlu menutup biaya dan menyisakan keuntungan yang direncanakan. Jangan menyamakan omzet dengan laba, karena omzet belum dikurangi biaya.',
        points: [
          'Hitung biaya layanan atau komisi jika menjual melalui perantara.',
          'Bedakan diskon dari perubahan biaya pokok produk.',
        ],
      },
      {
        heading: 'Bandingkan dengan kondisi pasar',
        body: 'Periksa harga produk sejenis dan nilai yang diterima pelanggan. Jika harga perlu disesuaikan, pertimbangkan ukuran produk, kemasan, layanan, atau proses produksi, bukan hanya menurunkan harga.',
        points: [
          'Uji perubahan harga dan catat dampaknya pada penjualan.',
          'Jaga agar setiap keputusan tetap menutup biaya usaha.',
        ],
      },
    ],
  },
  {
    slug: 'laporan-laba-rugi',
    topic: 'Laporan keuangan',
    title: 'Cara Membaca Laporan Laba Rugi Sederhana',
    summary: 'Pahami hubungan penjualan, biaya produk, beban usaha, dan laba dalam satu periode.',
    sections: [
      {
        heading: 'Mulai dari pendapatan',
        body: 'Pendapatan menunjukkan nilai penjualan dalam periode laporan. Periksa apakah transaksi yang dicatat memang terjadi pada periode tersebut dan tidak tercampur dengan setoran modal atau pinjaman.',
        points: [
          'Bedakan pendapatan usaha dari penerimaan non-penjualan.',
          'Gunakan rentang tanggal yang konsisten saat membandingkan laporan.',
        ],
      },
      {
        heading: 'Kurangi biaya produk dan beban',
        body: 'Kurangi pendapatan dengan biaya produk untuk melihat laba kotor. Setelah itu perhitungkan beban operasional, seperti sewa atau biaya pengiriman, untuk memahami hasil usaha lebih lanjut.',
        points: [
          'Jangan menghitung biaya yang sama lebih dari satu kali.',
          'Tinjau kategori biaya yang berubah dari periode sebelumnya.',
        ],
      },
      {
        heading: 'Gunakan hasil untuk mengambil keputusan',
        body: 'Laba rugi membantu menilai apakah kegiatan usaha menghasilkan laba pada periode yang dipilih. Laporan ini berbeda dari arus kas karena penjualan yang belum dibayar dapat memengaruhi laba tanpa menambah uang tunai.',
        points: [
          'Baca laporan bersama catatan arus kas dan piutang.',
          'Selidiki penyebab perubahan sebelum mengubah harga atau biaya.',
        ],
      },
    ],
  },
]
