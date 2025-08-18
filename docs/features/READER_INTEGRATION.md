# Reader Screen Integration Documentation

## Overview

`ReaderScreen` telah terintegrasi dengan sempurna ke dalam aplikasi nhentai clone. Dokumen ini menjelaskan bagaimana ReaderScreen dipanggil dan digunakan dalam aplikasi.

## Integration Points

### 1. Router Configuration ✅

**File**: `lib/core/routing/app_router.dart`

```dart
// Import ReaderScreen
import 'package:nhasixapp/presentation/pages/reader/reader_screen.dart';

// Route configuration
GoRoute(
  path: AppRoute.reader, // '/reader/:id'
  name: AppRoute.readerName,
  builder: (context, state) {
    final contentId = state.pathParameters['id']!;
    final page = int.tryParse(state.uri.queryParameters['page'] ?? '1') ?? 1;
    return ReaderScreen(
      contentId: contentId,
      initialPage: page,
    );
  },
),

// Helper method
static void goToReader(BuildContext context, String contentId, {int page = 1}) {
  context.push('/reader/$contentId?page=$page');
}
```

### 2. Navigation from Detail Screen ✅

**File**: `lib/presentation/pages/detail/detail_screen.dart`

```dart
// Read button in action buttons
ElevatedButton.icon(
  onPressed: () => _readContent(content),
  icon: const Icon(Icons.menu_book, size: 24),
  label: Text('Read Now'),
  // ... styling
),

// Navigation method
void _readContent(Content content) {
  AppRouter.goToReader(context, content.id);
}
```

### 3. Route Constants ✅

**File**: `lib/core/routing/app_route.dart`

```dart
class AppRoute {
  static const String reader = '/reader/:id';
  static const String readerName = 'reader';
  // ... other routes
}
```

## Navigation Flow

### Primary Navigation Path

1. **Home Screen** → Browse content
2. **Content Card** → Tap to view details
3. **Detail Screen** → Shows content metadata
4. **"Read Now" Button** → Navigate to ReaderScreen
5. **ReaderScreen** → Reading experience with settings

### URL Structure

- **Base URL**: `/reader/:id`
- **With Page**: `/reader/:id?page=5`
- **Example**: `/reader/123456?page=1`

### Parameters

- **contentId** (required): String - ID konten yang akan dibaca
- **initialPage** (optional): int - Halaman awal (default: 1)

## Usage Examples

### 1. Navigate from Code

```dart
// Basic navigation
AppRouter.goToReader(context, 'content-123');

// Navigate to specific page
AppRouter.goToReader(context, 'content-123', page: 5);

// Direct navigation
context.push('/reader/content-123?page=3');
```

### 2. Deep Linking

```dart
// URL yang bisa dibuka langsung
nhasixapp://reader/123456?page=5
```

### 3. Navigation with GoRouter

```dart
// Using GoRouter directly
context.pushNamed(
  AppRoute.readerName,
  pathParameters: {'id': 'content-123'},
  queryParameters: {'page': '5'},
);
```

## Integration Status

### ✅ Completed Integrations

1. **Router Configuration** - ReaderScreen terdaftar di app router
2. **Navigation Helper** - `AppRouter.goToReader()` method tersedia
3. **Detail Screen Integration** - Tombol "Read Now" berfungsi
4. **URL Parameters** - Support untuk contentId dan page parameter
5. **Deep Linking** - URL dapat diakses langsung

### 🔄 Potential Future Integrations

1. **History Screen** - Navigate to continue reading
2. **Favorites Screen** - Quick access to favorite content
3. **Search Results** - Direct read from search
4. **Downloads Screen** - Read offline content
5. **Bookmarks** - Jump to bookmarked pages

## Error Handling

### Navigation Errors

```dart
// Error handling in router
errorBuilder: (context, state) => Scaffold(
  appBar: AppBar(title: const Text('Page Not Found')),
  body: Center(
    child: Column(
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        Text('Page not found: ${state.uri}'),
        ElevatedButton(
          onPressed: () => context.go(AppRoute.home),
          child: const Text('Go Home'),
        ),
      ],
    ),
  ),
),
```

### Content Loading Errors

ReaderScreen memiliki error handling internal:

```dart
if (state is ReaderError) {
  return Center(
    child: AppErrorWidget(
      title: 'Loading Error',
      message: state.message,
      onRetry: () => context.read<ReaderCubit>().loadContent(
        widget.contentId,
        initialPage: widget.initialPage,
      ),
    ),
  );
}
```

## Testing

### Navigation Tests

```dart
testWidgets('Should navigate to ReaderScreen from DetailScreen', (tester) async {
  // Test navigation from detail screen
  await tester.tap(find.text('Read Now'));
  await tester.pumpAndSettle();
  expect(find.byType(ReaderScreen), findsOneWidget);
});
```

### URL Tests

```dart
test('Should generate correct reader URL', () {
  const contentId = 'test-123';
  const page = 5;
  const expectedUrl = '/reader/test-123?page=5';
  expect('/reader/$contentId?page=$page', equals(expectedUrl));
});
```

## Performance Considerations

### 1. Lazy Loading
- ReaderScreen hanya dimuat saat dibutuhkan
- Content dimuat secara asinkron setelah navigasi

### 2. Memory Management
- ReaderCubit di-dispose otomatis saat keluar dari screen
- Image preloading dibatasi untuk menghemat memory

### 3. Navigation Optimization
- Menggunakan `context.push()` untuk navigation stack yang efisien
- Parameter passing melalui URL untuk state restoration

## Conclusion

ReaderScreen telah terintegrasi dengan sempurna ke dalam aplikasi:

- ✅ **Router Configuration** - Terdaftar dan dikonfigurasi dengan benar
- ✅ **Navigation Flow** - Dapat diakses dari Detail Screen
- ✅ **URL Support** - Mendukung deep linking dan parameter
- ✅ **Error Handling** - Memiliki error handling yang robust
- ✅ **Testing** - Dapat ditest dengan mudah

Tidak ada yang kurang dari segi integrasi. ReaderScreen siap digunakan dan dapat diakses melalui tombol "Read Now" di Detail Screen atau melalui URL langsung.