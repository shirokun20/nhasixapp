# BLoC/Cubit Pattern Skill

## 📚 Overview

This project uses **flutter_bloc** (v9.1.1) for state management, following the **Cubit** pattern for simplicity and the **BLoC** pattern for complex event-driven scenarios.

---

## 🎯 When to Use What

| Pattern | Use Case | Example |
|---------|----------|---------|
| **Cubit** | Simple state, direct method calls | Theme toggle, language switch |
| **BLoC** | Complex state, event streams | Search with debounce, form validation |
| **BaseCubit** | All cubits (extends this) | Standardized error handling, logging |

---

## 🏗️ Cubit Structure

### Base Cubit (Required)

All cubits MUST extend `BaseCubit` for consistency:

```dart
// presentation/cubits/base_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

abstract class BaseCubit<State> extends Cubit<State> {
  final Logger _logger;
  
  BaseCubit(State initialState) : super(initialState) {
    _logger = Logger();
  }

  @override
  void emit(State state) {
    _logger.d('Emitting state: ${state.runtimeType}');
    super.emit(state);
  }

  @override
  Future<void> close() {
    _logger.d('Cubit closed: ${runtimeType}');
    return super.close();
  }

  /// Safe emit that handles disposed cubits
  void safeEmit(State state) {
    if (!isClosed) {
      emit(state);
    }
  }
}
```

### Simple Cubit Example

```dart
// presentation/cubits/theme/theme_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import '../base_cubit.dart';

// State
class ThemeState extends Equatable {
  final bool isDark;
  final ThemeMode mode;

  const ThemeState({
    required this.isDark,
    required this.mode,
  });

  ThemeState copyWith({bool? isDark, ThemeMode? mode}) {
    return ThemeState(
      isDark: isDark ?? this.isDark,
      mode: mode ?? this.mode,
    );
  }

  @override
  List<Object> get props => [isDark, mode];
}

// Cubit
class ThemeCubit extends BaseCubit<ThemeState> {
  final Logger _logger;

  ThemeCubit({required Logger logger})
      : _logger = logger,
        super(const ThemeState(isDark: false, mode: ThemeMode.light));

  void toggleTheme() {
    _logger.d('Toggling theme');
    final newMode = state.isDark ? ThemeMode.light : ThemeMode.dark;
    safeEmit(state.copyWith(
      isDark: !state.isDark,
      mode: newMode,
    ));
  }

  void setDarkMode(bool isDark) {
    _logger.d('Setting dark mode: $isDark');
    safeEmit(state.copyWith(
      isDark: isDark,
      mode: isDark ? ThemeMode.dark : ThemeMode.light,
    ));
  }
}
```

---

## 🎪 BLoC Example (Complex Events)

Use BLoC when you need event streams, debouncing, or complex event handling:

```dart
// presentation/cubits/search/search_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

// Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class SearchTriggered extends SearchEvent {}

class SearchCancelled extends SearchEvent {}

// State
class SearchState extends Equatable {
  final String query;
  final bool isLoading;
  final List<SearchResult> results;
  final String? error;

  const SearchState({
    this.query = '',
    this.isLoading = false,
    this.results = const [],
    this.error,
  });

  SearchState copyWith({
    String? query,
    bool? isLoading,
    List<SearchResult>? results,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      error: error,
    );
  }

  @override
  List<Object?> get props => [query, isLoading, results, error];
}

// BLoC
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchUseCase searchUseCase;
  final Logger _logger;

  SearchBloc({
    required this.searchUseCase,
    required Logger logger,
  })  : _logger = logger,
        super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchTriggered>(_onTriggered);
    on<SearchCancelled>(_onCancelled);
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    _logger.d('Query changed: ${event.query}');
    emit(state.copyWith(query: event.query, isLoading: false));
  }

  Future<void> _onTriggered(
    SearchTriggered event,
    Emitter<SearchState> emit,
  ) async {
    _logger.d('Search triggered for: ${state.query}');
    
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final results = await searchUseCase.execute(state.query);
      safeEmit(state.copyWith(
        isLoading: false,
        results: results,
      ));
    } catch (e) {
      _logger.e('Search failed', error: e);
      safeEmit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCancelled(
    SearchCancelled event,
    Emitter<SearchState> emit,
  ) async {
    _logger.d('Search cancelled');
    emit(const SearchState());
  }

  /// Safe emit for async operations
  void safeEmit(SearchState state) {
    if (!isClosed) {
      emit(state);
    }
  }
}
```

---

## 🎨 Usage in Widgets

### With BlocProvider (Inline)

```dart
// presentation/screens/comic_list_screen.dart
class ComicListScreen extends StatelessWidget {
  const ComicListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ComicCubit>()..loadComics(),
      child: const _ComicListView(),
    );
  }
}

class _ComicListView extends StatelessWidget {
  const _ComicListView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ComicCubit, ComicState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const SpinKitFadingCircle(color: Colors.blue);
        }

        if (state.error != null) {
          return ErrorWidget(message: state.error!);
        }

        return ListView.builder(
          itemCount: state.comics.length,
          itemBuilder: (context, index) {
            final comic = state.comics[index];
            return ComicTile(comic: comic);
          },
        );
      },
    );
  }
}
```

### With BlocProvider (Multi)

```dart
class MultiBlocScreen extends StatelessWidget {
  const MultiBlocScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ComicCubit>()),
        BlocProvider(create: (_) => getIt<ThemeCubit>()),
        BlocProvider(create: (_) => getIt<LanguageCubit>()),
      ],
      child: const _MultiBlocView(),
    );
  }
}
```

### With BlocListener (Side Effects)

```dart
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LoginCubit>(),
      child: BlocListener<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state.isSuccess) {
            Navigator.of(context).pushReplacementNamed('/home');
          }

          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        child: const _LoginView(),
      ),
    );
  }
}
```

---

## 🧪 Testing Cubits

### Using bloc_test

```dart
// test/presentation/cubits/comic_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetComics extends Mock implements GetComics {}

void main() {
  group('ComicCubit', () {
    late ComicCubit cubit;
    late MockGetComics mockGetComics;

    setUp(() {
      mockGetComics = MockGetComics();
      cubit = ComicCubit(getComics: mockGetComics);
    });

    tearDown(() {
      cubit.close();
    });

    group('loadComics', () {
      final tComics = [
        Comic(id: '1', title: 'Comic 1', createdAt: DateTime.now()),
        Comic(id: '2', title: 'Comic 2', createdAt: DateTime.now()),
      ];

      blocTest<ComicCubit, ComicState>(
        'emits [loading, success] when loadComics is successful',
        build: () {
          when(() => mockGetComics(any())).thenAnswer(
            (_) async => tComics,
          );
          return cubit;
        },
        act: (cubit) => cubit.loadComics(),
        expect: () => [
          const ComicState(isLoading: true),
          ComicState(isLoading: false, comics: tComics),
        ],
        verify: (_) {
          verify(() => mockGetComics(any())).called(1);
        },
      );

      blocTest<ComicCubit, ComicState>(
        'emits [loading, error] when loadComics fails',
        build: () {
          when(() => mockGetComics(any())).thenThrow(Exception('Failed'));
          return cubit;
        },
        act: (cubit) => cubit.loadComics(),
        expect: () => [
          const ComicState(isLoading: true),
          isA<ComicState>().having(
            (s) => s.error,
            'error',
            isNotNull,
          ),
        ],
      );
    });
  });
}
```

---

## 📋 Best Practices

### DO ✅
- Extend `BaseCubit` for all cubits
- Use `Equatable` for state comparison
- Use `safeEmit()` for async operations
- Keep states immutable (use `copyWith`)
- Handle errors in cubit, not UI
- Use `BlocObserver` for global logging
- Close streams in `close()` method

### DON'T ❌
- Don't emit state in constructor
- Don't pass BuildContext to cubit
- Don't call UI methods (showDialog, navigate) from cubit
- Don't use cubits for simple data passing
- Don't forget to close cubits (use BlocProvider)
- Don't put business logic in UI layer

---

## 🔧 Common Patterns

### Loading + Data + Error Pattern

```dart
class BaseState extends Equatable {
  final bool isLoading;
  final String? error;

  const BaseState({
    this.isLoading = false,
    this.error,
  });

  BaseState copyWith({bool? isLoading, String? error});

  @override
  List<Object?> get props => [isLoading, error];
}
```

### Pagination Pattern

```dart
class PaginatedState extends Equatable {
  final List<Item> items;
  final int page;
  final bool hasMore;
  final bool isLoading;

  const PaginatedState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoading = false,
  });

  PaginatedState copyWith({
    List<Item>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
  }) {
    return PaginatedState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [items, page, hasMore, isLoading];
}

// In Cubit
Future<void> loadMore() async {
  if (state.isLoading || !state.hasMore) return;

  safeEmit(state.copyWith(isLoading: true));

  try {
    final newItems = await repository.getItems(page: state.page + 1);
    safeEmit(state.copyWith(
      items: [...state.items, ...newItems],
      page: state.page + 1,
      hasMore: newItems.isNotEmpty,
      isLoading: false,
    ));
  } catch (e) {
    safeEmit(state.copyWith(isLoading: false, error: e.toString()));
  }
}
```

### Form Validation Pattern

```dart
class FormState extends Equatable {
  final String email;
  final String password;
  final String? emailError;
  final String? passwordError;
  final bool isSubmitting;

  const FormState({
    this.email = '',
    this.password = '',
    this.emailError,
    this.passwordError,
    this.isSubmitting = false,
  });

  bool get isValid => emailError == null && passwordError == null;
  bool get canSubmit => email.isNotEmpty && password.isNotEmpty && !isSubmitting;

  FormState copyWith({
    String? email,
    String? password,
    String? emailError,
    String? passwordError,
    bool? isSubmitting,
  }) {
    return FormState(
      email: email ?? this.email,
      password: password ?? this.password,
      emailError: emailError ?? this.emailError,
      passwordError: passwordError ?? this.passwordError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [email, password, emailError, passwordError, isSubmitting];
}

// In Cubit
void emailChanged(String value) {
  final error = value.isValidEmail() ? null : 'Invalid email';
  safeEmit(state.copyWith(email: value, emailError: error));
}

Future<void> submit() async {
  if (!state.canSubmit) return;

  safeEmit(state.copyWith(isSubmitting: true));

  try {
    await repository.login(state.email, state.password);
    safeEmit(state.copyWith(isSubmitting: false));
    // Handle success via BlocListener
  } catch (e) {
    safeEmit(state.copyWith(isSubmitting: false, error: e.toString()));
  }
}
```

---

## 📚 References

- [flutter_bloc Package](https://pub.dev/packages/flutter_bloc)
- [BLoC Library Documentation](https://bloclibrary.dev/)
- [Very Good BLoC](https://github.com/VeryGoodOpenSource/very_good_bloc)
- [Reso Coder BLoC Tutorial](https://resocoder.com/flutter-bloc-tutorial/)
