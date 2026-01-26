# BuildContext Setup for Cloudflare Bypass

## 🎯 Problem
Cloudflare bypass menggunakan **visible InAppWebView dialog** yang membutuhkan `BuildContext` untuk menampilkan dialog.

Namun, `CrotpediaSource` adalah dependency yang di-register di Service Locator (DI) dan tidak punya akses langsung ke widget tree.

## ✅ Solution

### Method 1: Call `setContext()` di Widget Root (Recommended)

Tambahkan di home screen atau content screen saat pertama kali build:

```dart
class HomeScreen extends StatefulWidget {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Set context untuk Cloudflare bypass
    final source = context.read<SourceCubit>().state.activeSource;
    if (source is CrotpediaSource) {
      source.setContext(context);
    }
  }
}
```

### Method 2: Via MultiBlocProvider Builder

Di `main.dart` MaterialApp builder:

```dart
builder: (context, child) {
  // Set context untuk semua sources yang membutuhkan
  final source = getIt<CrotpediaSource>();
  source.setContext(context);
  
  return child ?? const SizedBox.shrink();
},
```

### Method 3: Lazy Context via Navigator Key (Advanced)

Buat global navigator key dan gunakan di bypass:

```dart
// app_router.dart
static final navigatorKey = GlobalKey<NavigatorState>();

// crotpedia_cloudflare_bypass.dart
final context = navigatorKey.currentContext;
if (context != null) {
  await showDialog(...);
}
```

## 📝 Testing

Setelah setup, test dengan:

1. Buka Crotpedia source
2. Akses konten yang memicu 403
3. Dialog WebView harus muncul
4. Selesaikan challenge Cloudflare
5. Dialog auto-close dan request retry berhasil

## ⚠️ Important Notes

- **Context harus di-set SEBELUM** request 403 terjadi
- Context sebaiknya di-update saat source berubah
- Dialog akan gagal jika context null - cek log error
