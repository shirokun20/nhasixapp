# Source Config Templates

Template ini untuk developer yang mau bikin source baru, baik mode installable (via manifest app) maupun mode bundled/fallback.

## Alur pemakaian

1. Pilih jenis source:
- REST API source: pakai `source-config-rest-template.json`
- HTML scraper source: pakai `source-config-scraper-template.json`

2. Jika source mau installable (muncul di Source Manager):
- Tambahkan entry ke `manifest-installable-entry-template.json`
- Upload config ke jalur `app/config/<source>-config.json`

3. Jika source mau bundled/fallback (masuk APK):
- Simpan config ke `assets/configs/<source>-config.json`
- Daftarkan source id + asset path di `RemoteConfigService._bundledAssetPaths`

## Catatan penting

- `source` harus unik dan konsisten di seluruh app.
- Jangan edit file generated (`*.g.dart`, `*.freezed.dart`).
- Untuk search UI:
  - Bisa pakai `searchConfig` (query-string/form-based lama), atau
  - Pakai `searchForm` (dynamic form modern).
- Jika pakai `searchForm`, adapter scraper sudah support raw query (`raw:`), dan REST adapter juga sudah support raw query.

## Referensi implementasi aktif

- Installable manifest: `app/manifest.json`
- REST config contoh: `app/config/mangadex-config.json`
- Scraper config contoh: `app/config/hentaifox-config.json`
- Search form model: `lib/core/config/config_models.dart`
