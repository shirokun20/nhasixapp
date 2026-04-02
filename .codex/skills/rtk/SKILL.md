---
name: rtk
description: Token-optimized CLI proxy for developer operations (60-90% savings)
---

# RTK - Rust Token Killer

Gunakan skill ini untuk mengoptimalkan penggunaan token saat menjalankan perintah terminal. RTK menyaring "noise" dari output terminal sehingga Codex hanya menerima informasi yang relevan untuk penalaran.

## 🚀 Aturan Penggunaan

1. **Selalu gunakan awalan `rtk`**: Untuk semua perintah terminal yang menghasilkan output signifikan.
2. **Perintah yang didukung**:
   - `git`: `rtk git status`, `rtk git diff`, `rtk git log`
   - `flutter`: `rtk flutter test`, `rtk flutter analyze`, `rtk flutter pub get`
   - `file system`: `rtk ls -la`, `rtk find .`
   - `other`: `rtk npm test`, `rtk cargo test`

## 📊 Meta Commands

- `rtk gain`: Cek statistik penghematan token sesi saat ini.
- `rtk gain --history`: Lihat riwayat penggunaan dan penghematan.
- `rtk proxy <cmd>`: Jalankan perintah tanpa filter (hanya untuk debugging jika output RTK terlalu sedikit).

## 💡 Contoh Transformasi

| Perintah Asli | Perintah RTK | Manfaat |
| :--- | :--- | :--- |
| `git status` | `rtk git status` | Menghilangkan instruksi bantuan git yang panjang. |
| `flutter test` | `rtk flutter test` | Meringkas hasil tes yang berhasil, hanya fokus pada yang gagal. |
| `ls -R` | `rtk ls -R` | Mengelompokkan struktur folder dengan ringkas. |

> [!IMPORTANT]
> Jangan berasumsi bahwa output yang singkat berarti perintah gagal. RTK sengaja membuang teks boilerplate agar konteks AI tetap bersih dan murah.
