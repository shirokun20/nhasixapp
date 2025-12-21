import 'package:logger/logger.dart';

import '../../../core/di/service_locator.dart';
import '../../../domain/usecases/content/content_usecases.dart';
import '../../../domain/usecases/favorites/favorites_usecases.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../services/image_metadata_service.dart';
import 'detail_cubit.dart';

/// Factory class for creating DetailCubit instances
/// Since DetailCubit is screen-specific, it should be provided locally
/// rather than registered globally in the service locator
class DetailCubitFactory {
  /// Create a new DetailCubit instance with dependencies from service locator
  static DetailCubit create() {
    return DetailCubit(
      getContentDetailUseCase: getIt<GetContentDetailUseCase>(),
      addToFavoritesUseCase: getIt<AddToFavoritesUseCase>(),
      removeFromFavoritesUseCase: getIt<RemoveFromFavoritesUseCase>(),
      userDataRepository: getIt<UserDataRepository>(),
      imageMetadataService: getIt<ImageMetadataService>(),
      contentRepository: getIt<ContentRepository>(),
      logger: getIt<Logger>(),
    );
  }
}

/// Extension to make it easier to create DetailCubit in widgets
extension DetailCubitExtension on DetailCubit {
  /// Static factory method for convenience
  static DetailCubit create() => DetailCubitFactory.create();
}
