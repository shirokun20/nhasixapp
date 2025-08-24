# PDF Conversion Offline Support

## Problem
Sebelumnya, PDF conversion selalu membutuhkan koneksi internet karena memanggil API untuk mendapatkan content details (title, dll), bahkan ketika file sudah terdownload lengkap dan metadata.json sudah tersedia lokal.

## Solution
Telah dibuat perubahan pada `DownloadBloc._onConvertToPdf()` untuk:

1. **Prioritas pada metadata lokal**: Sebelum memanggil API, coba baca metadata.json dari folder download lokal
2. **Fallback ke API**: Jika metadata lokal tidak ada atau tidak valid, baru panggil API 
3. **Fallback title**: Jika semua gagal, gunakan contentId sebagai title

## Changes Made

### 1. Helper Method `_readLocalMetadata()`
```dart
Future<Map<String, dynamic>?> _readLocalMetadata(String contentId) async {
  // Membaca metadata.json dari folder download lokal
  // Return null jika file tidak ada atau corrupt
}
```

### 2. Refactor `_onConvertToPdf()`
```dart
// Coba baca metadata lokal dulu
final localMetadata = await _readLocalMetadata(event.contentId);

if (localMetadata != null) {
  // Gunakan metadata lokal untuk offline support
  contentTitle = localMetadata['title'] as String? ?? event.contentId;
} else {
  // Fallback ke API jika tidak ada metadata lokal
  try {
    final content = await _getContentDetailUseCase.call(...);
    contentTitle = content.title;
  } catch (e) {
    // Gunakan contentId sebagai fallback title
  }
}
```

## Metadata.json Structure
File metadata.json yang disimpan saat download berisi:
```json
{
  "content_id": "298547",
  "title": "Content Title",
  "download_date": "2025-01-24T16:27:32.921Z",
  "total_pages": 62,
  "downloaded_files": 62,
  "files": ["page_001.jpg", "page_002.jpg", ...],
  "tags": ["tag1", "tag2"],
  "artists": ["artist1", "artist2"],
  "language": "english",
  "cover_url": "https://..."
}
```

## Benefits
- ✅ PDF conversion bekerja di offline mode
- ✅ Tidak perlu koneksi internet jika metadata sudah ada
- ✅ Tetap backward compatible dengan online mode
- ✅ Robust error handling dengan multiple fallbacks

## Testing
Untuk testing offline mode:
1. Pastikan ada file download dengan metadata.json
2. Matikan internet
3. Coba convert to PDF
4. Seharusnya berhasil menggunakan metadata lokal

## File Location
- `/Download/nhasix/{contentId}/metadata.json`
- `/Download/nhasix/{contentId}/images/page_XXX.jpg`
