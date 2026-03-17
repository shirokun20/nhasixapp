---
name: bloc-cubit
description: Panduan state management dengan flutter_bloc dan Cubit untuk NhasixApp
license: MIT
compatibility: opencode
metadata:
  audience: developers
  pattern: state-management
---

## BLoC & Cubit State Management Guide

### Kapan Menggunakan Apa?

| Skenario | Gunakan |
|----------|---------|
| State sederhana, sedikit events | **Cubit** |
| State kompleks, banyak events | **BLoC** |
| Form handling | **Cubit** |
| Real-time streams, complex transitions | **BLoC** |

### BaseCubit

Semua Cubit di NhasixApp harus extend `BaseCubit`:

```dart
abstract class BaseCubit<State> extends Cubit<State> {
  BaseCubit(super.initialState);
  
  final Logger _logger = Logger();
  
  @override
  void emit(State state) {
    _logger.d('${runtimeType}: $state');
    super.emit(state);
  }
  
  @override
  void onError(Object error, StackTrace stackTrace) {
    _logger.e('${runtimeType} Error', error: error, stackTrace: stackTrace);
    super.onError(error, stackTrace);
  }
}
```

### Cubit Implementation

#### 1. State Definition

Gunakan `freezed` untuk immutable states:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_state.freezed.dart';

@freezed
class UserState with _$UserState {
  const factory UserState.initial() = _Initial;
  const factory UserState.loading() = _Loading;
  const factory UserState.loaded(User user) = _Loaded;
  const factory UserState.error(String message) = _Error;
}
```

Atau manual dengan sealed class:

```dart
sealed class UserState {}

class UserInitial extends UserState {}
class UserLoading extends UserState {}
class UserLoaded extends UserState {
  final User user;
  UserLoaded(this.user);
}
class UserError extends UserState {
  final String message;
  UserError(this.message);
}
```

#### 2. Cubit Class

```dart
class UserCubit extends BaseCubit<UserState> {
  final GetUserUseCase _getUserUseCase;
  
  UserCubit(this._getUserUseCase) : super(const UserState.initial());
  
  Future<void> loadUser(String userId) async {
    emit(const UserState.loading());
    
    final result = await _getUserUseCase(userId);
    
    result.fold(
      (failure) => emit(UserState.error(failure.message)),
      (user) => emit(UserState.loaded(user)),
    );
  }
  
  Future<void> refreshUser(String userId) async {
    // Jangan emit loading untuk refresh (keep current state visible)
    final result = await _getUserUseCase(userId);
    
    result.fold(
      (failure) => emit(UserState.error(failure.message)),
      (user) => emit(UserState.loaded(user)),
    );
  }
}
```

### BLoC Implementation (untuk kasus kompleks)

#### 1. Events

```dart
@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.login(String email, String password) = _Login;
  const factory AuthEvent.logout() = _Logout;
  const factory AuthEvent.checkAuth() = _CheckAuth;
}
```

#### 2. BLoC Class

```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  
  AuthBloc(this._loginUseCase, this._logoutUseCase) 
      : super(const AuthState.initial()) {
    on<_Login>(_onLogin);
    on<_Logout>(_onLogout);
    on<_CheckAuth>(_onCheckAuth);
  }
  
  Future<void> _onLogin(_Login event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    
    final result = await _loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );
    
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }
  
  Future<void> _onLogout(_Logout event, Emitter<AuthState> emit) async {
    await _logoutUseCase();
    emit(const AuthState.unauthenticated());
  }
}
```

### UI Integration

#### BlocProvider

```dart
// Di page atau route
BlocProvider(
  create: (context) => sl<UserCubit>()..loadUser(userId),
  child: const UserPage(),
)

// Multiple providers
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => sl<AuthBloc>()),
    BlocProvider(create: (_) => sl<UserCubit>()),
  ],
  child: const MyApp(),
)
```

#### BlocBuilder

```dart
BlocBuilder<UserCubit, UserState>(
  builder: (context, state) {
    return state.when(
      initial: () => const SizedBox.shrink(),
      loading: () => const CircularProgressIndicator(),
      loaded: (user) => UserProfileWidget(user: user),
      error: (message) => ErrorWidget(message: message),
    );
  },
)
```

#### BlocListener

```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    state.maybeWhen(
      error: (message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      ),
      authenticated: (_) => context.go('/home'),
      orElse: () {},
    );
  },
  child: const LoginForm(),
)
```

#### BlocConsumer (Builder + Listener)

```dart
BlocConsumer<UserCubit, UserState>(
  listener: (context, state) {
    // Side effects (navigation, snackbar, etc.)
  },
  builder: (context, state) {
    // UI
    return ...;
  },
)
```

### Best Practices

1. **Satu Cubit per Feature** - Jangan campur concerns berbeda
2. **Immutable States** - Gunakan `freezed` atau sealed classes
3. **Error Handling** - Selalu handle error state
4. **Loading States** - Tampilkan loading indicator
5. **Initial Data** - Load data di constructor atau via method
6. **Dispose** - BlocProvider otomatis dispose, tapi close manual jika perlu

### Testing Cubit

```dart
void main() {
  late UserCubit cubit;
  late MockGetUserUseCase mockUseCase;
  
  setUp(() {
    mockUseCase = MockGetUserUseCase();
    cubit = UserCubit(mockUseCase);
  });
  
  tearDown(() => cubit.close());
  
  blocTest<UserCubit, UserState>(
    'emits [loading, loaded] when loadUser succeeds',
    build: () {
      when(() => mockUseCase(any())).thenAnswer(
        (_) async => Right(testUser),
      );
      return cubit;
    },
    act: (cubit) => cubit.loadUser('123'),
    expect: () => [
      const UserState.loading(),
      UserState.loaded(testUser),
    ],
  );
}
```
