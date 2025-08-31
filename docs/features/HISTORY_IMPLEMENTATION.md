# History Feature Implementation

## Overview
Implementasi lengkap fitur History dengan auto-cleanup sesuai permintaan user untuk mengelola riwayat pembacaan dengan cleanup otomatis berdasarkan inactivity atau interval waktu (harian/6 jam).

## Features Implemented

### 1. Core History Management ✅
- **GetHistoryUseCase**: Pagination untuk riwayat dengan limit dan offset
- **ClearHistoryUseCase**: Hapus semua riwayat
- **RemoveHistoryItemUseCase**: Hapus item riwayat spesifik
- **GetHistoryCountUseCase**: Hitung total item riwayat

### 2. Auto-Cleanup Service ✅
- **HistoryCleanupService**: Service untuk auto-cleanup berdasarkan:
  - Interval waktu (harian, 6 jam, mingguan, dll)
  - Inactivity period (1 hari, 3 hari, 1 minggu, dll)
  - Manual cleanup
- **UserPreferences Extension**: Tambahan field untuk cleanup settings
- **Initialization**: Auto-start pada app startup di `main.dart`

### 3. UI Components ✅
- **HistoryScreen**: Main screen dengan pagination, pull-to-refresh, dan menu actions
- **HistoryItemWidget**: Display item riwayat dengan progress, last read, dan remove button
- **HistoryEmptyWidget**: Empty state dengan guidance untuk user
- **HistoryCleanupInfoWidget**: Bottom sheet untuk cleanup settings dan info

### 4. State Management ✅
- **HistoryCubit**: Cubit untuk history management dengan BaseCubit inheritance
- **HistoryState**: State dengan loading, success, error, dan pagination support
- **HistoryCubitFactory**: Factory pattern untuk DI

### 5. Integration ✅
- **Service Locator**: Semua dependencies terdaftar
- **App Router**: History screen terintegrasi ke routing dengan `/history`
- **Navigation Helper**: `AppRouter.goToHistory(context)`

## Auto-Cleanup Logic

### Cleanup Intervals
```dart
enum CleanupInterval {
  disabled,      // Tidak ada auto cleanup
  sixHours,      // Setiap 6 jam
  daily,         // Setiap hari
  weekly,        // Setiap minggu
  monthly,       // Setiap bulan
}
```

### Inactivity Settings
```dart
enum InactivityPeriod {
  never,         // Tidak pernah cleanup
  oneDay,        // 1 hari tidak aktif
  threeDays,     // 3 hari tidak aktif
  oneWeek,       // 1 minggu tidak aktif
  oneMonth,      // 1 bulan tidak aktif
}
```

### How It Works
1. **App Startup**: HistoryCleanupService diinisialisasi
2. **Background Timer**: Timer untuk interval cleanup
3. **App Lifecycle**: Check inactivity saat app resume
4. **User Preferences**: Sync dengan pengaturan user

## UI Features

### History Screen
- **Pagination**: Load more dengan infinite scroll
- **Pull-to-Refresh**: Refresh data terbaru
- **Search**: Filter riwayat (untuk future enhancement)
- **Menu Actions**:
  - Clear All History
  - Cleanup Settings
  - Sort Options

### History Item
- **Thumbnail**: Progressive image loading
- **Metadata**: Title, tags, last viewed time
- **Progress**: Reading progress bar
- **Time Spent**: Total waktu baca
- **Remove Button**: Hapus item individual

### Empty State
- **Guidance**: Petunjuk untuk mulai membaca
- **Navigation**: Link ke content discovery

## Navigation Integration

### Routes
```dart
// App Route
static const String history = '/history';
static const String historyName = 'history';

// Router Configuration
GoRoute(
  path: AppRoute.history,
  name: AppRoute.historyName,
  builder: (context, state) => const HistoryScreen(),
),
```

### Navigation Helper
```dart
// Helper method
static void goToHistory(BuildContext context) {
  context.go(AppRoute.history);
}

// Usage
AppRouter.goToHistory(context);
```

## Service Locator Configuration

### Dependencies Registered
```dart
// Use Cases
getIt.registerLazySingleton<GetHistoryUseCase>(() => GetHistoryUseCase(getIt()));
getIt.registerLazySingleton<ClearHistoryUseCase>(() => ClearHistoryUseCase(getIt()));
getIt.registerLazySingleton<RemoveHistoryItemUseCase>(() => RemoveHistoryItemUseCase(getIt()));
getIt.registerLazySingleton<GetHistoryCountUseCase>(() => GetHistoryCountUseCase(getIt()));

// Service
getIt.registerLazySingleton<HistoryCleanupService>(() => HistoryCleanupService(
  userDataRepository: getIt<UserDataRepository>(),
  clearHistoryUseCase: getIt<ClearHistoryUseCase>(),
  getHistoryCountUseCase: getIt<GetHistoryCountUseCase>(),
  logger: getIt<Logger>(),
));

// Cubit
getIt.registerFactory<HistoryCubit>(() => HistoryCubitFactory.create());
```

## Usage Examples

### Navigate to History
```dart
// From any widget
AppRouter.goToHistory(context);

// Or using GoRouter directly
context.go('/history');
```

### Cubit Usage in Widget
```dart
class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<HistoryCubit>(),
      child: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          // Handle states: loading, success, error, empty
        },
      ),
    );
  }
}
```

### Manual Cleanup Trigger
```dart
// Trigger cleanup from settings
final cleanupService = getIt<HistoryCleanupService>();
await cleanupService.performCleanup();
```

## Testing Strategy

### Unit Tests
- Use case tests untuk semua history operations
- Service tests untuk cleanup logic
- Cubit tests untuk state management

### Integration Tests
- Screen navigation tests
- Cleanup service integration
- Database operations

### Widget Tests
- History screen UI tests
- Empty state tests
- Item widget tests

## Performance Considerations

### Pagination
- Default limit: 20 items per page
- Lazy loading untuk scroll performance
- Efficient database queries

### Memory Management
- Dispose timers dengan benar
- Cleanup resources di cubit dispose
- Optimize image loading

### Background Processing
- Non-blocking cleanup operations
- Efficient timer scheduling
- Battery-friendly intervals

## Future Enhancements

### Search & Filter
- Search dalam riwayat
- Filter by content type
- Sort by various criteria

### Analytics
- Reading patterns analysis
- Time spent analytics
- Popular content tracking

### Sync & Backup
- Cloud sync untuk riwayat
- Backup/restore functionality
- Cross-device synchronization

## Files Created/Modified

### New Files
```
lib/domain/usecases/history/
├── get_history_usecase.dart
├── clear_history_usecase.dart
├── remove_history_item_usecase.dart
└── get_history_count_usecase.dart

lib/services/
└── history_cleanup_service.dart

lib/presentation/cubits/history/
├── history_cubit.dart
├── history_state.dart
└── history_cubit_factory.dart

lib/presentation/pages/history/
├── history_screen.dart
└── widgets/
    ├── history_empty_widget.dart
    ├── history_item_widget.dart
    └── history_cleanup_info_widget.dart
```

### Modified Files
```
lib/domain/entities/user_preferences.dart     # Extended with cleanup fields
lib/core/di/service_locator.dart              # Added history dependencies
lib/core/routing/app_router.dart              # Added history route
lib/presentation/cubits/cubits.dart           # Export history cubit
lib/main.dart                                 # Initialize cleanup service
```

## Summary

History feature telah berhasil diimplementasikan dengan:
- ✅ Complete backend dengan use cases
- ✅ Auto-cleanup service dengan interval dan inactivity settings
- ✅ Rich UI dengan pagination dan interactive elements
- ✅ Proper state management dengan cubit pattern
- ✅ Full integration dengan routing dan DI
- ✅ Performance optimization dan error handling

Fitur ini siap untuk production use dan dapat diperluas dengan enhancement yang disebutkan di future roadmap.
