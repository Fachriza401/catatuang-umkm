# React + TypeScript + Vite

This template provides a minimal setup to get React working in Vite with HMR and some Oxlint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Oxc](https://oxc.rs)
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/)

## React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the Oxlint configuration

If you are developing a production application, we recommend enabling type-aware lint rules by installing `oxlint-tsgolint` and editing `.oxlintrc.json`:

```json
{
  "$schema": "./node_modules/oxlint/configuration_schema.json",
  "plugins": ["react", "typescript", "oxc"],
  "options": {
    "typeAware": true
  },
  "rules": {
    "react/rules-of-hooks": "error",
    "react/only-export-components": ["warn", { "allowConstantExport": true }]
  }
}
```

See the [Oxlint rules documentation](https://oxc.rs/docs/guide/usage/linter/rules) for the full list of rules and categories.

## Lingkup Sistem CatatUang

CatatUang adalah sistem pembukuan usaha yang terdiri dari aplikasi mobile Flutter dan dashboard web React. Keduanya menggunakan Supabase sebagai backend bersama.

| Area | Fungsi utama |
|---|---|
| **Owner (pemilik usaha)** | Mendaftar dan masuk dengan satu akun, membuat profil usaha, serta mengelola data pembukuan. Akun yang sama digunakan di aplikasi mobile dan dashboard web; sistem tidak membagi pengguna ke peran Admin, Kasir, atau Viewer. |
| **Aplikasi mobile** | Menyediakan pencatatan transaksi, dashboard, pengelolaan utang/piutang, laporan, kalkulator Rupiah, dan pengaturan usaha. Transaksi dapat disimpan di perangkat ketika offline dan disinkronkan saat koneksi tersedia. |
| **Dashboard web** | Menyediakan tampilan yang lebih luas melalui browser, termasuk ringkasan keuangan, transaksi, kategori, utang/piutang, laporan, profil usaha, dan pengaturan. Dashboard menggunakan akun Owner yang sama dengan aplikasi mobile. |
| **Database dan backend** | Supabase menangani autentikasi, profil usaha, transaksi, utang, pembayaran utang, paket, dan data terkait. Akses data dibatasi agar Owner hanya dapat mengakses usahanya sendiri. |
| **Penyimpanan lampiran** | Menyimpan bukti transaksi yang diunggah. Ketersediaannya mengikuti dukungan aplikasi dan ketentuan paket. |

### Alur penggunaan

Owner mendaftar atau masuk melalui aplikasi mobile atau web, kemudian membuat profil usaha. Setelah itu, Owner mengelola pembukuan melalui fitur yang tersedia pada masing-masing platform. Mobile mendukung pencatatan offline dan sinkronisasi; dashboard web mengakses data melalui backend Supabase.

### Batasan keterangan

Uraian ini menjelaskan lingkup berdasarkan implementasi yang terlihat di repositori. Keberadaan kode atau konfigurasi, termasuk fitur paket dan pembayaran, tidak dengan sendirinya memastikan bahwa alurnya telah diaktifkan atau diuji di production.
