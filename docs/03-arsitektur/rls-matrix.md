# Matriks Hak Akses & Kebijakan Row Level Security (RLS) - CatatUang

Dokumen ini mendokumentasikan pemetaan hak akses per peran pengguna dan per tabel pada database Supabase CatatUang, hasil audit langsung dari berkas migrasi `supabase/migrations/`.

---

## 1. Pemetaan Peran (Role Mapping)

Terdapat perbedaan nomenklatur antara spesifikasi kebutuhan bisnis dengan implementasi skema database:
- **Spesifikasi Dokumen:** `owner`, `manager`, `cashier`, `viewer`.
- **Implementasi Database Asli (`public.business_members`):** Nilai kolom `role` dibatasi oleh constraint:
  ```sql
  check (role in ('admin', 'cashier', 'viewer'))
  ```
- **Kesimpulan:** Peran **`manager`** pada dokumen kebutuhan bisnis bersesuaian 1:1 dengan peran **`admin`** pada skema database. Pemilik usaha berstatus **`owner`** (tercatat di `business_profiles.user_id = auth.uid()`).

---

## 2. Matriks Hak Akses Tabel & Aksi (RLS Matrix)

| Tabel Database | Operasi | Owner | Admin (Manager) | Cashier | Viewer | Mekanisme Enkapsulasi / Catatan |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **`business_profiles`** | `SELECT` | ✅ Ya | ✅ Ya | ✅ Ya | ✅ Ya | RLS: `has_business_role(user_id, ['owner', 'admin', 'cashier', 'viewer'])` |
| | `INSERT` | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | Revoked dari role `authenticated`. Dibuat via Auth trigger / setup akun. |
| | `UPDATE` | ✅ Ya | ✅ Ya | ❌ Ditolak | ❌ Ditolak | Direct update revoked. **Wajib lewat RPC `update_business_profile()`**. |
| | `DELETE` | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | Revoked dari role `authenticated`. Hapus akun via edge function khusus. |
| **`business_members`** | `SELECT` | ✅ Ya | ✅ Ya | ✅ Ya | ✅ Ya | RLS: `has_business_role(business_id, ['owner', 'admin', 'cashier', 'viewer'])` |
| | `INSERT` | ✅ Ya | ✅ Ya | ❌ Ditolak | ❌ Ditolak | Direct insert revoked. **Wajib lewat RPC `add_business_member()`**. |
| | `UPDATE` | ✅ Ya | ✅ Ya | ❌ Ditolak | ❌ Ditolak | Direct update revoked. **Wajib lewat RPC `update_business_member_role()`**. |
| | `DELETE` | ✅ Ya | ✅ Ya | ❌ Ditolak | ❌ Ditolak | Direct delete revoked. **Wajib lewat RPC `remove_business_member()`**. |
| **`transactions`** | `SELECT` | ✅ Ya | ✅ Ya | ✅ Ya | ✅ Ya | RLS: `has_business_role(user_id, ['owner', 'admin', 'cashier', 'viewer'])` |
| | `INSERT` | ✅ Ya | ✅ Ya | ✅ Ya | ❌ Ditolak | Direct insert revoked. **Wajib lewat RPC `sync_transaction(operation='create')`**. |
| | `UPDATE` | ✅ Ya | ✅ Ya | ❌ Ditolak* | ❌ Ditolak | Direct update revoked. **Wajib lewat RPC `sync_transaction(operation='update')`**. (*Kasir dilarang mengubah transaksi lampau). |
| | `DELETE` | ✅ Ya | ✅ Ya | ❌ Ditolak | ❌ Ditolak | Direct delete revoked. **Wajib lewat RPC `sync_transaction(operation='delete')`** (soft delete). |
| **`debts`** | `SELECT` | ✅ Ya | ✅ Ya | ✅ Ya | ✅ Ya | RLS: `has_business_role(user_id, ['owner', 'admin', 'cashier', 'viewer'])` |
| | `INSERT` | ✅ Ya | ✅ Ya | ❌ Ditolak | ❌ Ditolak | Direct insert diizinkan oleh RLS policy: `"Managers can create debts"`. |
| | `UPDATE` | ✅ Ya | ✅ Ya | ❌ Ditolak | ❌ Ditolak | Direct update diizinkan oleh RLS policy: `"Managers can update debts"`. |
| | `DELETE` | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | Revoked dari role `authenticated`. Data utang tidak dapat dihapus permanen. |
| **`debt_payments`** | `SELECT` | ✅ Ya | ✅ Ya | ✅ Ya | ✅ Ya | RLS: `has_business_role(user_id, ['owner', 'admin', 'cashier', 'viewer'])` |
| | `INSERT` | ✅ Ya | ✅ Ya | ✅ Ya | ❌ Ditolak | Direct insert revoked. **Wajib lewat RPC `record_debt_payment()`**. |
| | `UPDATE` | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | Revoked dari role `authenticated`. Pembayaran bersifat immutable. |
| | `DELETE` | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | Revoked dari role `authenticated`. |
| **`business_plans`** | `SELECT` | ✅ Ya | ✅ Ya | ✅ Ya | ✅ Ya | Public read untuk role `authenticated`. |
| | `INSERT / UPDATE / DELETE` | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | Revoked dari role `authenticated`. Hanya via migrasi/service_role. |
| **`business_subscriptions`** | `SELECT` | ✅ Ya | ✅ Ya | ✅ Ya | ✅ Ya | RLS: `has_business_role(business_id, ['owner', 'admin', 'cashier', 'viewer'])` |
| | `INSERT / UPDATE / DELETE` | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | Revoked dari role `authenticated`. Diatur oleh sistem & webhook. |
| **`payment_orders`** | `SELECT` | ✅ Ya | ✅ Ya | ❌ Ditolak | ❌ Ditolak | RLS: `has_business_role(business_id, ['owner', 'admin'])` |
| | `INSERT / UPDATE / DELETE` | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | ❌ Ditolak | Dibuat dan dikelola lewat Supabase Edge Functions (`service_role`). |
| **`storage.objects` (`transaction-attachments`)** | `SELECT` | ✅ Ya | ✅ Ya | ✅ Ya | ✅ Ya | Public bucket (`public = true`). File URL dapat diakses. |
| | `INSERT / UPDATE / DELETE` | ✅ Ya | ⚠️ Celah | ⚠️ Celah | ❌ Ditolak | RLS Storage saat ini mengikat `auth.uid() = foldername[1]` (Lihat Temuan di bawah). |

---

## 3. Temuan Kejanggalan & Catatan Keamanan RLS

Berikut adalah temuan penting dari hasil audit skema migrasi:

1. **Enkapsulasi Ketat Melalui Security Definer RPC:**  
   Arsitektur backend CatatUang secara eksplisit melakukan `REVOKE insert, update, delete` pada tabel utama (`transactions`, `debt_payments`, `business_members`, `business_profiles`). Ini merupakan praktik keamanan yang sangat baik (*defense-in-depth*), mencegah manipulasi data bypass dari klien PostgREST secara langsung. Semua mutasi data wajib dipanggil melalui RPC terkait (`sync_transaction`, `record_debt_payment`, `add_business_member`, `update_business_profile`).
2. **Kejanggalan pada Policy Storage Bucket `transaction-attachments`:**  
   Pada migrasi `20261031000000_init_catat_uang.sql`, policy upload penyimpanan didefinisikan sebagai:
   ```sql
   auth.uid()::text = (storage.foldername(name))[1]
   ```
   **Dampaknya:** Policy ini hanya mengizinkan user mengunggah jika folder pertama pada path file adalah `auth.uid()` dirinya sendiri. Jika anggota tim (misal kasir atau admin) mencoba mengunggah bukti transaksi dengan prefix folder `business_id` (ID pemilik usaha), upload akan **ditolak oleh RLS storage** karena `auth.uid() != business_id`.  
   *Rekomendasi Web:* Saat upload, gunakan path `auth.uid()/<file_name>` atau susun migrasi aditif untuk memperbolehkan anggota bisnis mengunggah ke folder `business_id`.
3. **Pencatatan Cicilan oleh Kasir:**  
   Pada tabel `debts`, kasir tidak memiliki izin `INSERT` atau `UPDATE` langsung. Namun melalui RPC `record_debt_payment()` (yang berstatus `SECURITY DEFINER`), kasir yang memiliki akses ke bisnis tersebut dapat mencatat pembayaran cicilan, dan sistem otomatis memperbarui `paid_amount` pada `debts` serta membuat baris kas di `transactions`. Hal ini 100% konsisten dengan aturan bisnis.
4. **Soft Delete pada `transactions`:**  
   Kolom `deleted_at` digunakan untuk penanda penghapusan. Query pembacaan kas, ringkasan saldo, dan laporan dasbor di web **wajib** selalu menyertakan filter `.is('deleted_at', null)` agar transaksi yang sudah dihapus tidak terhitung.

