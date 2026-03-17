# BLoC/Cubit State Management

Patterns for state management in NhasixApp using `flutter_bloc`.

## Decision Matrix

| Use BLoC when | Use Cubit when |
|---------------|----------------|
| Complex state, multiple events | Simple state changes |
| Event transformations (debounce/throttle) | Few actions/methods |
| Complex async workflows | Direct state mutations |
| Real-time streams | Simple async operations |

## BaseCubit (REQUIRED)

All Cubits MUST extend `BaseCubit`:
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

## Cubit with Freezed States

```dart
// State
@freezed
class UserState with _$UserState {
  const factory UserState.initial() = _Initial;
  const factory UserState.loading() = _Loading;
  const factory UserState.loaded(User user) = _Loaded;
  const factory UserState.error(String message) = _Error;
}

// Cubit
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
}
```

## BLoC with Freezed Events

```dart
// Events
@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.login(String email, String password) = _Login;
  const factory AuthEvent.logout() = _Logout;
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._loginUseCase) : super(const AuthState.initial()) {
    on<_Login>(_onLogin);
    on<_Logout>(_onLogout);
  }

  Future<void> _onLogin(_Login event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    final result = await _loginUseCase(LoginParams(email: event.email, password: event.password));
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }
}
```

## UI Integration

```dart
// Provider
BlocProvider(create: (_) => getIt<UserCubit>()..loadUser(id), child: const UserView())

// Builder (with freezed .when)
BlocBuilder<UserCubit, UserState>(
  builder: (context, state) => state.when(
    initial: () => const SizedBox.shrink(),
    loading: () => const CircularProgressIndicator(),
    loaded: (user) => UserProfile(user: user),
    error: (msg) => ErrorDisplay(message: msg),
  ),
)

// Listener (side effects)
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) => state.maybeWhen(
    error: (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))),
    authenticated: (_) => context.go('/home'),
    orElse: () {},
  ),
)
```

## Testing

```dart
blocTest<UserCubit, UserState>(
  'emits [loading, loaded] when loadUser succeeds',
  build: () {
    when(() => mockUseCase(any())).thenAnswer((_) async => DataSuccess(testUser));
    return UserCubit(mockUseCase);
  },
  act: (cubit) => cubit.loadUser('123'),
  expect: () => [const UserState.loading(), UserState.loaded(testUser)],
);
```

## Best Practices
1. One Cubit per feature — don't mix concerns
2. Immutable states — use `freezed` or sealed classes
3. Always handle error + loading states
4. Don't emit loading on refresh (keep current state visible)
5. BlocProvider auto-disposes — no manual close needed
