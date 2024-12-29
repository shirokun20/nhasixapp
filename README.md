# nhasixapp

A new Flutter project.

lib/
├── data/
│   ├── datasources/    # API atau SQLite handlers
│   ├── models/         # Model data
│   ├── repositories/   # Repositori untuk logika data
├── domain/
│   ├── entities/       # Entitas utama aplikasi
│   ├── usecases/       # Logika bisnis
├── presentation/
│   ├── blocs/          # Logika BLoC
│   ├── pages/          # Halaman UI
│   ├── widgets/        # Widget Reusable
├── core/
│   ├── utils/          # Fungsi utilitas
│   ├── constants/      # Konstanta
│   ├── di/             # Dependency Injection setup
└── main.dart           # Entry point aplikasi