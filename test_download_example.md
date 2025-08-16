# Contoh Penggunaan Download System Baru

## 1. Download dari Detail Screen

Ketika user menekan tombol "Download" di detail screen:

```dart
void _downloadContent(Content content) {
  // Queue download
  context.read<DownloadBloc>().add(DownloadQueueEvent(content: content));
  
  // Start download immediately
  context.read<DownloadBloc>().add(DownloadStartEvent(content.id));
}
```

**Yang terjadi:**
1. ✅ Local notification muncul: "Download Started - Downloading: [title]"
2. ✅ File didownload ke: `Download/nhasix/[content_id]/images/`
3. ✅ Progress notification update setiap 10%
4. ✅ Notification completion: "Download Complete - Downloaded: [title]"

## 2. Download dengan PDF Conversion

```dart
void _downloadAsPdf(Content content) {
  final params = DownloadContentParams.pdf(content);
  context.read<DownloadBloc>().add(DownloadQueueEvent(content: content));
  context.read<DownloadBloc>().add(DownloadStartEvent(content.id));
}
```

**Yang terjadi:**
1. ✅ Download images seperti biasa
2. ✅ Convert images ke PDF: `Download/nhasix/[content_id]_[title].pdf`
3. ✅ Notification: "PDF created successfully"

## 3. Monitoring Progress

```dart
BlocBuilder<DownloadBloc, DownloadBlocState>(
  builder: (context, state) {
    if (state is DownloadLoaded) {
      final download = state.downloads
          .where((d) => d.contentId == contentId)
          .firstOrNull;
          
      if (download != null) {
        return Text('Progress: ${download.progressPercentage}%');
      }
    }
    return Text('Not downloading');
  },
)
```

## 4. Notification Actions

User dapat:
- ✅ Pause download dari notification
- ✅ Resume download dari notification  
- ✅ Cancel download dari notification
- ✅ Open downloaded content dari notification

## 5. File Structure

```
Download/
└── nhasix/
    └── [content_id]/
        ├── images/
        │   ├── page_001.jpg
        │   ├── page_002.jpg
        │   └── ...
        ├── metadata.json
        └── [content_id]_[title].pdf (optional)
```

## 6. Error Handling

- ✅ Network error → Auto retry dengan exponential backoff
- ✅ Storage full → Error notification dengan cleanup suggestion
- ✅ Permission denied → Request permission automatically
- ✅ Invalid URL → Skip image dan continue dengan yang lain

## 7. Background Download

- ✅ Download berjalan di background
- ✅ Persistent notification
- ✅ Resume setelah app restart
- ✅ Handle network changes

## Testing Checklist

### Basic Download
- [ ] Download single content
- [ ] Progress notification muncul
- [ ] File tersimpan di path yang benar
- [ ] Completion notification muncul

### PDF Conversion  
- [ ] Download dengan PDF option
- [ ] PDF file terbuat
- [ ] PDF bisa dibuka
- [ ] Metadata PDF benar

### Error Scenarios
- [ ] Network error handling
- [ ] Storage permission
- [ ] Insufficient storage
- [ ] Invalid image URLs

### Background Operations
- [ ] Download di background
- [ ] Notification actions work
- [ ] Resume after app kill
- [ ] Multiple concurrent downloads

### Performance
- [ ] Memory usage reasonable
- [ ] No memory leaks
- [ ] Smooth UI during download
- [ ] Proper resource cleanup