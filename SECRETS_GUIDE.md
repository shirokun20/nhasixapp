# 🔐 Panduan Setup GitHub Secrets

Agar GitHub Action bisa menandatangani aplikasi dengan kunci yang sama setiap saat, Anda perlu menambahkan "Secrets" di repo GitHub Anda.

## 1. Dapatkan Nilai Kunci (Base64)
Saya sudah membuatkan file `keystore_base64.txt` di folder project ini.
Isinya adalah text panjang acak (enkripsi dari kunci keystore).

- Buka file `keystore_base64.txt`.
- Copy **seluruh isinya**.

## 2. Masukkan ke GitHub
1.  Buka Repo: **Sequence > Settings > Secrets and variables > Actions**.
    ([Direct Link](https://github.com/shirokun20/nhasixapp/settings/secrets/actions))
2.  Klik **New repository secret**.
3.  Tambahkan secret berikut satu per satu:

| Name | Secret (Value) |
| :--- | :--- |
| `KEYSTORE_BASE64` | (Paste isi dari file `keystore_base64.txt` tadi) |
| `KEY_PASSWORD` | `android` |
| `STORE_PASSWORD` | `android` |
| `ALIAS_NAME` | `upload` |

## 3. Selesai
Setelah ini ditambahkan:
1.  Hapus file `keystore_base64.txt` (Opsional, demi keamanan).
2.  Simpan file `android/app/upload-keystore.jks` di tempat aman (Backup). **JANGAN HILANG**.
3.  Coba trigger rilis baru, GitHub akan otomatis menggunakan kunci ini.
