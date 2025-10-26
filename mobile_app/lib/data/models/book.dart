import 'package:json_annotation/json_annotation.dart';
import 'theme.dart';
import 'book_author.dart';

part 'book.g.dart';

/// Book model
@JsonSerializable()
class BookModel {
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'sort_order')
  final int? sortOrder;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'theme_id')
  final int? themeId;
  @JsonKey(name: 'author_id')
  final int? authorId;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  // Relations
  final AppThemeModel? theme;
  final BookAuthorModel? author;

  BookModel({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder,
    this.isActive,
    this.themeId,
    this.authorId,
    this.createdAt,
    this.updatedAt,
    this.theme,
    this.author,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) =>
      _$BookModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookModelToJson(this);
}
