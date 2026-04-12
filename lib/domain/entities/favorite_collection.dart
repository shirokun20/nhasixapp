import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_collection.freezed.dart';
part 'favorite_collection.g.dart';

@freezed
abstract class FavoriteCollection with _$FavoriteCollection {
  const factory FavoriteCollection({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(0) int itemCount,
  }) = _FavoriteCollection;

  factory FavoriteCollection.fromJson(Map<String, dynamic> json) =>
      _$FavoriteCollectionFromJson(json);
}
