import '../../entities/user_preferences.dart';
import '../../repositories/settings_repository.dart';

class GetUserPreferencesUseCase {
  final SettingsRepository repository;
  GetUserPreferencesUseCase(this.repository);

  Future<UserPreferences> call() async {
    return await repository.getUserPreferences();
  }
}
