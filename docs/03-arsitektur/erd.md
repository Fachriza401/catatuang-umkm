# Entity Relationship Diagram (ERD) - CatatUang

Dokumen ini mendokumentasikan skema aktif CatatUang yang didefinisikan dalam
`supabase/migrations/`. Akun yang sama menjadi Owner di aplikasi mobile dan
dashboard web; migrasi `20261107040000_owner_only_business_access.sql`
menghapus tabel keanggotaan dan batas jumlah anggota dari skema aktif.

---

## 1. Diagram Relasi Entitas (Mermaid ERD)

```mermaid
erDiagram
    auth_users ||--o| business_profiles : "owns (1:1)"
    business_profiles ||--o| business_subscriptions : "has subscription"
    business_plans ||--o{ business_subscriptions : "defines plan"
    business_plans ||--o{ payment_orders : "billed for"
    business_profiles ||--o{ payment_orders : "places order"
    business_profiles ||--o{ transactions : "owns records (user_id)"
    auth_users ||--o{ transactions : "created_by"
    business_profiles ||--o{ debts : "owns records (user_id)"
    auth_users ||--o{ debts : "created_by"
    debts ||--o{ debt_payments : "has installments"
    business_profiles ||--o{ debt_payments : "owns records (user_id)"
    transactions ||--o| debt_payments : "ledger link (1:1)"
    auth_users ||--o{ transaction_sync_requests : "sync audit log"

    auth_users {
        uuid id PK
        string email
    }

    business_profiles {
        uuid id PK "gen_random_uuid()"
        uuid user_id FK "unique, references auth.users(id)"
        string business_name "Nama usaha UMKM"
        string owner_name "Nama pemilik"
        string business_type "Jenis usaha (kuliner, retail, jasa, dll)"
        string phone "Nomor telepon"
        string address "Alamat usaha"
        timestamptz created_at
        timestamptz updated_at
    }

    business_plans {
        string plan PK "free | premium | business"
        int monthly_transaction_limit "Null jika unlimited"
        boolean attachments_enabled "True jika boleh upload bukti"
        bigint price_amount "Harga paket (IDR)"
        string currency "IDR"
        int billing_period_days "Durasi paket (30 hari)"
    }

    business_subscriptions {
        uuid business_id PK,FK "references business_profiles(user_id)"
        string plan FK "references business_plans(plan)"
        string status "active | past_due | cancelled | expired"
        timestamptz current_period_end
        string provider "manual | midtrans"
        string provider_reference UK
        uuid updated_by FK "references auth.users(id)"
        timestamptz created_at
        timestamptz updated_at
    }

    transactions {
        uuid id PK "Client-generated UUID"
        uuid user_id FK "references auth.users(id) - merepresentasikan business_id"
        uuid created_by FK "references auth.users(id) - pencatat baris"
        string type "income | expense"
        bigint amount "Nominal Rupiah (> 0)"
        string category_id "ID kategori (misal sales, raw_material, dll)"
        string payment_method_id "cash | transfer | ewallet | qris"
        timestamptz transaction_date "Waktu riil transaksi"
        string description "Catatan transaksi"
        string attachment_url "Path file di bucket storage"
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at "Soft delete marker"
    }

    debts {
        uuid id PK "Client-generated UUID"
        uuid user_id FK "references auth.users(id) - merepresentasikan business_id"
        uuid created_by FK "references auth.users(id)"
        string type "receivable (piutang) | payable (utang)"
        string contact_name "Nama debitur / kreditur"
        string phone "Nomor telepon kontak"
        bigint amount "Total pokok utang/piutang (> 0)"
        bigint paid_amount "Akumulasi yang sudah dibayar (0 <= paid <= amount)"
        timestamptz transaction_date "Tanggal mulai utang/piutang"
        timestamptz due_date "Tanggal jatuh tempo"
        string note "Catatan / keterangan"
        timestamptz created_at
        timestamptz updated_at
    }

    debt_payments {
        uuid id PK "Client-generated UUID"
        uuid debt_id FK "references debts(id) on delete cascade"
        uuid user_id FK "references auth.users(id) - merepresentasikan business_id"
        uuid created_by FK "references auth.users(id)"
        bigint amount "Nominal cicilan (> 0)"
        timestamptz payment_date "Tanggal pembayaran cicilan"
        string note "Catatan pembayaran"
        uuid ledger_transaction_id UK "unique, relasi 1:1 ke transactions.id"
        timestamptz created_at
    }

    payment_orders {
        uuid id PK "gen_random_uuid()"
        uuid business_id FK "references business_profiles(user_id)"
        string plan FK "references business_plans(plan)"
        bigint amount "Nominal pembayaran"
        string currency "IDR"
        string status "pending | paid | failed | expired | cancelled | refunded"
        string provider "midtrans"
        string provider_order_id UK "Order ID unik dari gateway"
        string provider_transaction_id "ID transaksi Midtrans"
        string snap_token "Token popup Midtrans Snap"
        string snap_redirect_url "URL pembayaran gateway"
        string payment_type "Metode (qris, bank_transfer, dll)"
        jsonb raw_notification "Payload webhook mentah"
        uuid created_by FK "references auth.users(id)"
        timestamptz paid_at
        timestamptz provisioned_at
        timestamptz expires_at
        timestamptz created_at
        timestamptz updated_at
    }

    transaction_sync_requests {
        uuid user_id PK,FK "references auth.users(id)"
        uuid idempotency_key PK "UUID kunci idempoten"
        jsonb request "Payload riwayat request"
        jsonb response "Payload riwayat response"
        timestamptz created_at
    }
```

---

## 2. Penjelasan Rinci Entitas & Hubungan Antar Tabel

### A. Konvensi `business_id` vs `user_id` (Kritis)
Dalam skema asli database CatatUang:
- Setiap akun yang membuat usaha memiliki entri di `public.business_profiles`. Kolom `business_profiles.user_id` bernilai identik dengan `auth.users.id` pemilik (`owner`).
- Tabel turunan seperti `transactions`, `debts`, dan `debt_payments` menggunakan nama kolom **`user_id`** untuk merujuk pada **ID pemilik usaha** (yang berfungsi sebagai `business_id` bagi entitas usaha tersebut).
- Kolom **`created_by`** merekam akun Owner yang membuat catatan.

### B. Daftar Entitas

1. **`business_profiles`**
   - Menyimpan informasi identitas profil usaha UMKM (nama usaha, jenis usaha, kontak pemilik, alamat).
   - Relasi: 1-to-1 dengan `auth.users` melalui `user_id`.

2. **`business_plans` & `business_subscriptions`**
   - Mengatur tingkatan paket usaha (`free`, `premium`, `business`).
   - Menyimpan batas transaksi bulanan (`monthly_transaction_limit`) dan izin lampiran (`attachments_enabled`).

3. **`transactions`**
   - Mencatat arus kas keuangan (`income` atau `expense`).
   - Menggunakan soft delete (`deleted_at`).
   - Relasi dengan storage melalui `attachment_url` yang menunjuk ke bucket `transaction-attachments`.

4. **`debts` & `debt_payments`**
   - `debts` mencatat kewajiban utang (`payable`) atau hak tagih piutang (`receivable`).
   - Status pelunasan dilacak dari nilai `paid_amount` terhadap `amount`. Jika `paid_amount = amount`, maka utang telah lunas.
   - `debt_payments` mencatat riwayat cicilan. Setiap pencatatan cicilan wajib terhubung secara atomik (1:1) ke tabel `transactions` melalui `ledger_transaction_id` agar arus kas pembukuan tetap sinkron.

5. **`transaction_sync_requests`**
   - Tabel audit idempotency untuk mencegah duplikasi pencatatan transaksi saat klien mengirimkan sinkronisasi ulang.

6. **`payment_orders`**
   - Menyimpan rekaman transaksi pembayaran langganan melalui payment gateway Midtrans.

## 3. Penjelasan Kolom dan Tipe Data

Skema utama CatatUang menggunakan PostgreSQL melalui Supabase. Tipe seperti
`uuid`, `bigint`, `timestamptz`, dan `jsonb` di bawah ini mengikuti deklarasi
migrasi database, bukan tipe SQLite. Aplikasi mobile juga menyimpan sebagian
data secara lokal menggunakan Drift/SQLite; pada penyimpanan lokal, ID disimpan
sebagai teks, nominal sebagai integer, dan tanggal/waktu melalui kolom tanggal
Drift.

| Tipe Data | Penggunaan pada CatatUang | Alasan |
| :--- | :--- | :--- |
| `UUID` | ID akun dan usaha, transaksi, utang, pembayaran, serta relasi antartabel. | Menyediakan identifier unik yang dapat dibuat klien dan digunakan untuk sinkronisasi data. |
| `TEXT` | Nama dan kontak usaha, jenis/status transaksi, ID kategori dan metode pembayaran, catatan, URL lampiran, kode paket, serta referensi penyedia pembayaran. | Menyimpan string dan nilai kategori/status yang dibatasi oleh aturan aplikasi atau constraint database. |
| `BIGINT` | Nominal transaksi, utang, cicilan, harga paket, dan pembayaran dalam Rupiah. | Menyimpan nominal Rupiah sebagai bilangan bulat tanpa pembulatan pecahan desimal. |
| `INTEGER` | Batas transaksi bulanan dan durasi paket dalam hari. | Sesuai untuk nilai hitungan dan batas berukuran integer. |
| `BOOLEAN` | Flag paket seperti `attachments_enabled` serta flag modul seperti `is_default` dan `is_active`. | Menyatakan kondisi benar/salah secara langsung di PostgreSQL. |
| `TIMESTAMPTZ` | Waktu transaksi, jatuh tempo, pembayaran, masa langganan, serta waktu pembuatan, pembaruan, dan penghapusan. | Menyimpan waktu beserta konteks zona waktu untuk konsistensi lintas perangkat dan layanan. |
| `JSONB` | Permintaan/respons sinkronisasi, notifikasi mentah payment gateway, dan hasil terstruktur dari fungsi database. | Menyimpan payload terstruktur yang bentuk propertinya dapat bervariasi. |

`REAL` tidak digunakan untuk nominal keuangan pada skema aktif. Nilai Rupiah
disimpan sebagai `BIGINT`, sehingga nominal tidak mengalami galat representasi
bilangan pecahan.

`PRIMARY KEY` dan `UNIQUE` adalah constraint, bukan tipe data. Primary key
mengidentifikasi record, sedangkan constraint unik mencegah nilai duplikat pada
kolom yang ditentukan. Contoh constraint unik pada skema aktif meliputi
`business_profiles.user_id`, `payment_orders.provider_order_id`,
`business_subscriptions.provider_reference`, dan
`debt_payments.ledger_transaction_id`. Tabel
`transaction_sync_requests` menggunakan primary key gabungan
(`user_id`, `idempotency_key`).

SQLite tidak menyediakan tipe `UUID`, `BOOLEAN`, atau `TIMESTAMPTZ` dengan
semantik yang sama seperti PostgreSQL. Pada database lokal, Drift memetakan ID
ke `TEXT`, kolom jenis dan status seperti `type` dan `syncStatus` ke `TEXT`,
nominal dan penghitung percobaan sinkronisasi ke `INTEGER`, serta waktu ke
kolom tanggal Drift. Karena itu, deskripsi tipe data database lokal tidak boleh
disamakan dengan deklarasi tipe pada skema Supabase.
