import '../../entities/user_preferences.dart';
import '../../repositories/settings_repository.dart';

class SaveUserPreferencesUseCase {
  final SettingsRepository repository;
  SaveUserPreferencesUseCase(this.repository);

  Future<void> call(UserPreferences preferences) async {
    await repository.updateUserPreferences(preferences);
  }
}
