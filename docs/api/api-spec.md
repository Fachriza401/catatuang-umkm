# Spesifikasi API (API Spec) - CatatUang Web Dashboard

Dokumen ini mendefinisikan seluruh kontrak antarmuka API antara Web Dasbor CatatUang dan backend Supabase (PostgREST, RPC, Storage, dan Auth).

---

## 1. Konfigurasi Lingkungan & Headers Standar

Seluruh request ke PostgREST dan RPC wajib menyertakan header standar berikut:

```http
apikey: {{ANON_KEY}}
Authorization: Bearer {{ACCESS_TOKEN}}
Content-Type: application/json
```

Variabel Lingkungan yang Digunakan:
- `{{SUPABASE_URL}}` : URL project Supabase (misal `https://xyzcompany.supabase.co`)
- `{{ANON_KEY}}` : Public anon key Supabase
- `{{ACCESS_TOKEN}}` : JWT token hasil login pengguna

---

## 2. Modul Autentikasi (Supabase GoTrue)

### 2.1 Login Email & Password
- **Tujuan:** Autentikasi pengguna untuk mendapatkan session token dan refresh token.
- **Method & Path:** `POST {{SUPABASE_URL}}/auth/v1/token?grant_type=password`
- **Peran yang Diizinkan:** Publik / Semua pengguna terdaftar.
- **Request Body:**
  ```json
  {
    "email": "owner@warung.com",
    "password": "Password123!"
  }
  ```
- **Response Sukses (200 OK):**
  ```json
  {
    "access_token": "eyJhbGciOi...",
    "token_type": "bearer",
    "expires_in": 3600,
    "refresh_token": "dGhpcy1pcy1...",
    "user": {
      "id": "11111111-1111-1111-1111-111111111111",
      "email": "owner@warung.com"
    }
  }
  ```
- **Kode Error:** `400 Bad Request` (Invalid login credentials).

### 2.2 Register Pengguna Baru
- **Tujuan:** Mendaftarkan akun pemilik usaha baru.
- **Method & Path:** `POST {{SUPABASE_URL}}/auth/v1/signup`
- **Request Body:**
  ```json
  {
    "email": "baru@warung.com",
    "password": "Password123!",
    "data": {
      "full_name": "Budi Santoso"
    }
  }
  ```
- **Response Sukses (200 OK):** Objek `user` dan status konfirmasi email.

### 2.3 Lupa Password (Password Recovery)
- **Method & Path:** `POST {{SUPABASE_URL}}/auth/v1/recover`
- **Request Body:**
  ```json
  {
    "email": "owner@warung.com"
  }
  ```

---

## 3. Modul Profil Usaha & Akses Bisnis

### 3.1 Dapatkan Hak Akses & Status Bisnis (`get_my_business_access`)
- **Tujuan:** Memeriksa akses akun Owner, paket aktif, dan kuota transaksi usaha milik akun.
- **Method & Path:** `POST {{SUPABASE_URL}}/rest/v1/rpc/get_my_business_access`
- **Peran:** Owner dari akun yang sedang terautentikasi.
- **Request Body:** `{}` (kosong).
- **Response Sukses (200 OK):**
  ```json
  {
    "business_id": "11111111-1111-1111-1111-111111111111",
    "role": "owner",
    "plan": "free",
    "subscription_status": "active",
    "current_period_end": null,
    "transactions_used": 24,
    "monthly_transaction_limit": null,
    "attachments_enabled": true,
    "can_manage_settings": true,
    "can_create_transactions": true
  }
  ```

### 3.2 Ambil Profil Bisnis
- **Method & Path:** `GET {{SUPABASE_URL}}/rest/v1/business_profiles?user_id=eq.{{BUSINESS_ID}}&select=*`
- **Headers Tambahan:** `Accept: application/vnd.pgrst.object+json`
- **Response Sukses (200 OK):**
  ```json
  {
    "id": "22222222-2222-2222-2222-222222222222",
    "user_id": "11111111-1111-1111-1111-111111111111",
    "business_name": "Warung Berkah Jaya",
    "owner_name": "Budi Santoso",
    "business_type": "Kuliner",
    "phone": "081234567890",
    "address": "Jl. Mawar No. 12, Jakarta",
    "created_at": "2026-11-01T00:00:00Z",
    "updated_at": "2026-11-01T00:00:00Z"
  }
  ```

### 3.3 Update Profil Bisnis (`update_business_profile`)
- **Method & Path:** `POST {{SUPABASE_URL}}/rest/v1/rpc/update_business_profile`
- **Peran:** Owner dari akun yang sedang terautentikasi.
- **Request Body:**
  ```json
  {
    "p_business_name": "Warung Berkah Makmur",
    "p_owner_name": "Budi Santoso",
    "p_business_type": "Kuliner",
    "p_phone": "081234567890",
    "p_address": "Jl. Melati No. 5"
  }
  ```

---

## 4. Modul Transaksi & Dasbor

### 4.1 Query Daftar Transaksi (Pagination & Filter)
- **Tujuan:** Menampilkan tabel transaksi dengan filter tanggal, kategori, dan pencarian catatan.
- **Method & Path:**  
  `GET {{SUPABASE_URL}}/rest/v1/transactions?user_id=eq.{{BUSINESS_ID}}&deleted_at=is.null&order=transaction_date.desc&offset=0&limit=20&select=*`
- **Headers:** `Prefer: count=exact`
- **Peran:** Owner dari usaha yang datanya diminta.
- **Response Sukses (200 OK):**
  ```json
  [
    {
      "id": "33333333-3333-3333-3333-333333333333",
      "user_id": "11111111-1111-1111-1111-111111111111",
      "created_by": "11111111-1111-1111-1111-111111111111",
      "type": "income",
      "amount": 150000,
      "category_id": "sales",
      "payment_method_id": "cash",
      "transaction_date": "2026-11-06T09:00:00Z",
      "description": "Penjualan paket catering",
      "attachment_url": null,
      "created_at": "2026-11-06T09:00:00Z",
      "updated_at": "2026-11-06T09:00:00Z",
      "deleted_at": null
    }
  ]
  ```

### 4.2 Tambah / Ubah / Hapus Transaksi (`sync_transaction`)
- **Tujuan:** Membuat transaksi baru secara aman dan idempoten.
- **Method & Path:** `POST {{SUPABASE_URL}}/rest/v1/rpc/sync_transaction`
- **Peran:** Owner dari usaha yang datanya diubah.
- **Request Body (Contoh Tambah Transaksi):**
  ```json
  {
    "p_transaction": {
      "id": "33333333-3333-3333-3333-333333333333",
      "user_id": "11111111-1111-1111-1111-111111111111",
      "type": "income",
      "amount": 150000,
      "category_id": "sales",
      "payment_method_id": "cash",
      "transaction_date": "2026-11-06T09:00:00Z",
      "description": "Penjualan paket catering",
      "attachment_url": null,
      "created_at": "2026-11-06T09:00:00Z",
      "deleted_at": null
    },
    "p_operation": "create",
    "p_idempotency_key": "44444444-4444-4444-4444-444444444444"
  }
  ```
- **Response Sukses (200 OK):**
  ```json
  {
    "status": "synced",
    "transaction": {
      "id": "33333333-3333-3333-3333-333333333333",
      "amount": 150000,
      "type": "income"
    }
  }
  ```

### 4.3 Ringkasan Dasbor (`get_web_dashboard_summary`)
- **Tujuan:** Mengembalikan agregat kas, piutang/utang tersisa, titik grafik, dan maksimal lima transaksi terbaru tanpa mengirim seluruh riwayat transaksi ke browser.
- **Method & Path:** `POST {{SUPABASE_URL}}/rest/v1/rpc/get_web_dashboard_summary`
- **Peran:** Owner dari usaha yang diminta; akses tetap dibatasi RLS.
- **Request Body:**
  ```json
  {
    "p_business_id": "11111111-1111-1111-1111-111111111111",
    "p_start": "2026-10-31T17:00:00Z",
    "p_end": "2026-11-30T17:00:00Z",
    "p_chart_start": "2026-05-31T17:00:00Z",
    "p_chart_end": "2026-11-30T17:00:00Z",
    "p_chart_unit": "month",
    "p_timezone": "Asia/Jakarta"
  }
  ```
- **Response Sukses (200 OK):**
  ```json
  {
    "cash_balance": 1250000,
    "period_income": 500000,
    "period_expense": 125000,
    "receivable_outstanding": 300000,
    "payable_outstanding": 100000,
    "chart_points": [
      {
        "bucket_start": "2026-11-01T00:00:00",
        "income": 500000,
        "expense": 125000
      }
    ],
    "recent_transactions": [
      {
        "id": "33333333-3333-3333-3333-333333333333",
        "type": "income",
        "amount": 150000,
        "transaction_date": "2026-11-06T09:00:00Z",
        "description": "Penjualan paket catering",
        "category_id": "sales",
        "payment_method_id": "cash"
      }
    ]
  }
  ```
- **Perhitungan:** `cash_balance` adalah jumlah masuk dikurangi jumlah keluar dari seluruh transaksi yang `deleted_at`-nya null; total periode dan grafik memakai rentang awal inklusif/akhir eksklusif; saldo utang/piutang adalah `amount - paid_amount`.
- **Validasi & Error:** `42501` untuk sesi tanpa akses bisnis; `22023` untuk tanggal, satuan grafik, atau zona waktu tidak valid. Fungsi berjalan sebagai `SECURITY INVOKER`, tidak melonggarkan policy, dan tidak memerlukan `service_role`.

---

## 5. Modul Utang & Piutang

### 5.1 Query Daftar Utang / Piutang
- **Method & Path:**  
  `GET {{SUPABASE_URL}}/rest/v1/debts?user_id=eq.{{BUSINESS_ID}}&order=due_date.asc&select=*`
- **Peran:** Owner dari usaha yang datanya diminta.
- **Response Sukses (200 OK):**
  ```json
  [
    {
      "id": "55555555-5555-5555-5555-555555555555",
      "user_id": "11111111-1111-1111-1111-111111111111",
      "created_by": "11111111-1111-1111-1111-111111111111",
      "type": "receivable",
      "contact_name": "Pak RT Joko",
      "phone": "081298765432",
      "amount": 500000,
      "paid_amount": 200000,
      "transaction_date": "2026-11-01T00:00:00Z",
      "due_date": "2026-11-15T00:00:00Z",
      "note": "Pesanan konsumsi rapat",
      "created_at": "2026-11-01T00:00:00Z",
      "updated_at": "2026-11-03T10:00:00Z"
    }
  ]
  ```

### 5.2 Catat Pembayaran Cicilan (`record_debt_payment`)
- **Tujuan:** Mencatat cicilan utang/piutang secara atomik, otomatis mengupdate `paid_amount` dan memasukkan mutasi ke buku kas `transactions`.
- **Method & Path:** `POST {{SUPABASE_URL}}/rest/v1/rpc/record_debt_payment`
- **Peran:** Owner dari usaha yang datanya diubah.
- **Request Body:**
  ```json
  {
    "p_payment_id": "66666666-6666-6666-6666-666666666666",
    "p_debt_id": "55555555-5555-5555-5555-555555555555",
    "p_amount": 100000,
    "p_payment_date": "2026-11-06T10:00:00Z",
    "p_note": "Cicilan ke-2 transfer",
    "p_ledger_transaction_id": "77777777-7777-7777-7777-777777777777",
    "p_ledger_description": "Pembayaran piutang: Pak RT Joko"
  }
  ```
- **Response Sukses (200 OK):** `"66666666-6666-6666-6666-666666666666"` (UUID payment id).
- **Error Handled:**
  - `400`: *"Payment exceeds the outstanding balance"* (Cicilan melebihi sisa utang).
  - `400`: *"Debt not found"*.

---

## 6. Modul Storage (Bukti Transaksi)

### 6.1 Upload Bukti Transaksi
- **Method & Path:** `POST {{SUPABASE_URL}}/storage/v1/object/transaction-attachments/{{USER_ID}}/bukti_{{TIMESTAMP}}.jpg`
- **Headers:** `Content-Type: image/jpeg` (atau `image/png`, `application/pdf`)
- **Request Body:** Raw binary file bytes.
- **Response Sukses (200 OK):**
  ```json
  {
    "Key": "transaction-attachments/11111111-1111-1111-1111-111111111111/bukti_1730865600.jpg"
  }
  ```
- **URL Publik untuk Menampilkan Gambar:**  
  `{{SUPABASE_URL}}/storage/v1/object/public/transaction-attachments/11111111-1111-1111-1111-111111111111/bukti_1730865600.jpg`
