---
name: bloc-pattern
description: Implement BLoC and Cubit state management following NhasixApp patterns
license: MIT
compatibility: opencode
metadata:
  category: state-management
  framework: flutter
  project: nhasixapp
---

# BLoC/Cubit Pattern Skill for NhasixApp

This skill guides you through implementing state management using flutter_bloc.

## When to Use BLoC vs Cubit

### Use BLoC when:
- Complex state with multiple events
- Need event transformations (debounce, throttle)
- Complex async workflows
- Multiple event types

### Use Cubit when:
- Simple state changes
- Few actions/methods
- Direct state mutations
- Simple async operations

## Creating a Cubit (Simple State)

```dart
// presentation/cubit/user_cubit.dart
class UserCubit extends BaseCubit<UserState> {
  final GetUserUseCase getUserUseCase;

  UserCubit({required this.getUserUseCase}) : super(const UserInitial());

  Future<void> loadUser(String id) async {
    emit(const UserLoading());
    
    final result = await getUserUseCase(GetUserParams(id));
    
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (user) => emit(UserLoaded(user)),
    );
  }

  void refresh() {
    // Reload current user
    final currentState = state;
    if (currentState is UserLoaded) {
      loadUser(currentState.user.id);
    }
  }
}
```

## Creating Cubit States

```dart
// presentation/cubit/user_state.dart
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UserLoaded extends UserState {
  final User user;
  const UserLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class UserError extends UserState {
  final String message;
  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}
```

## Creating a BLoC (Complex State)

```dart
// presentation/bloc/user_bloc.dart
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserUseCase getUserUseCase;
  final UpdateUserUseCase updateUserUseCase;

  UserBloc({
    required this.getUserUseCase,
    required this.updateUserUseCase,
  }) : super(const UserInitial()) {
    on<LoadUserEvent>(_onLoadUser);
    on<UpdateUserEvent>(_onUpdateUser);
    on<RefreshUserEvent>(_onRefreshUser, transformer: debounce());
  }

  Future<void> _onLoadUser(
    LoadUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(const UserLoading());
    
    final result = await getUserUseCase(GetUserParams(event.userId));
    
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (user) => emit(UserLoaded(user)),
    );
  }

  Future<void> _onUpdateUser(
    UpdateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    final currentState = state;
    if (currentState is UserLoaded) {
      emit(const UserUpdating());
      
      final result = await updateUserUseCase(
        UpdateUserParams(event.user),
      );
      
      result.fold(
        (failure) => emit(UserUpdateError(failure.message)),
        (user) => emit(UserLoaded(user)),
      );
    }
  }
}
```

## Creating BLoC Events

```dart
// presentation/bloc/user_event.dart
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserEvent extends UserEvent {
  final String userId;
  const LoadUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateUserEvent extends UserEvent {
  final User user;
  const UpdateUserEvent(this.user);

  @override
  List<Object?> get props => [user];
}

class RefreshUserEvent extends UserEvent {
  const RefreshUserEvent();
}
```

## Using in UI

```dart
// presentation/pages/user_page.dart
class UserPage extends StatelessWidget {
  final String userId;
  
  const UserPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UserCubit>()..loadUser(userId),
      child: Scaffold(
        appBar: AppBar(title: const Text('User')),
        body: BlocBuilder<UserCubit, UserState>(
          builder: (context, state) {
            return switch (state) {
              UserInitial() => const SizedBox.shrink(),
              UserLoading() => const Center(child: CircularProgressIndicator()),
              UserLoaded(:final user) => UserProfile(user: user),
              UserError(:final message) => ErrorWidget(message: message),
            };
          },
        ),
      ),
    );
  }
}
```

## Best Practices

1. **Immutable States**: Always create new state objects, never mutate
2. **Equatable**: Extend Equatable for proper comparison
3. **Single Responsibility**: One BLoC/Cubit per feature
4. **Error States**: Always handle error states explicitly
5. **Loading States**: Show loading indicators during async operations
6. **Const Constructors**: Use const for state classes when possible

## Common Patterns

### Pull-to-Refresh
```dart
RefreshIndicator(
  onRefresh: () => context.read<UserCubit>().refresh(),
  child: ListView(...),
)
```

### Error Retry
```dart
if (state is UserError) {
  return ErrorWidget(
    message: state.message,
    onRetry: () => context.read<UserCubit>().loadUser(userId),
  );
}
```

### Multiple States with copyWith
```dart
class UserState extends Equatable {
  final User? user;
  final bool isLoading;
  final String? error;

  const UserState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
```

## When to Use

- Implementing new features
- Refactoring from setState
- Code reviews
- State management decisions
