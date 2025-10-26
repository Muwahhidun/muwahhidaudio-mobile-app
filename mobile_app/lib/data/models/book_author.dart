import 'package:json_annotation/json_annotation.dart';

part 'book_author.g.dart';

/// Book Author model
@JsonSerializable()
class BookAuthorModel {
  final int id;
  final String name;
  final String? biography;
  @JsonKey(name: 'birth_year')
  final int? birthYear;
  @JsonKey(name: 'death_year')
  final int? deathYear;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  BookAuthorModel({
    required this.id,
    required this.name,
    this.biography,
    this.birthYear,
    this.deathYear,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory BookAuthorModel.fromJson(Map<String, dynamic> json) =>
      _$BookAuthorModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookAuthorModelToJson(this);
}
