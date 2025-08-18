# Flutter BLoC & Dependency Injection (DI) Best Practices

## Kapan Menggunakan `context.read` / `BlocProvider.of`
- Untuk Cubit/BLoC yang state-nya ingin dihubungkan ke UI (widget tree)
- Jika ingin event/state update otomatis memicu rebuild widget (BlocBuilder/BlocListener)
- Contoh: DownloadBloc, SettingsCubit, AuthCubit, dsb yang di-provide lewat BlocProvider

## Kapan Menggunakan `getIt`
- Untuk service/helper class yang tidak perlu terhubung ke widget tree (misal: LocalDataSource, ApiService, Logger, dsb)
- Untuk Cubit/BLoC yang memang tidak dihubungkan ke UI (misal: background worker, singleton global, dsb)
- Untuk dependency injection di layer data/domain/service

## Ringkasan
- State management untuk UI → pakai `context.read`
- Service/helper/dependency injection → pakai `getIt`

Dengan pola ini, state aplikasi tetap sinkron dan arsitektur tetap bersih.
