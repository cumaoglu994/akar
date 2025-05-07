import 'package:json_annotation/json_annotation.dart';

part 'ad_model.g.dart';

@JsonSerializable()
class Ad {
  final String? id;
  final String? title;
  final String? description;
  final double? price;
  @JsonKey(name: 'images')
  final List<String>? images;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'category_id')
  final String? categoryId;
  @JsonKey(name: 'city_id')
  final String? cityId;
  @JsonKey(name: 'district_id')
  final String? districtId;
  @JsonKey(name: 'neighborhood_id')
  final String? neighborhoodId;
  @JsonKey(name: 'street_id')
  final String? streetId;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Ad({
    this.id,
    this.title,
    this.description,
    this.price,
    this.images,
    this.userId,
    this.categoryId,
    this.cityId,
    this.districtId,
    this.neighborhoodId,
    this.streetId,
    this.createdAt,
    this.updatedAt,
  });

  factory Ad.fromJson(Map<String, dynamic> json) => _$AdFromJson(json);
  Map<String, dynamic> toJson() => _$AdToJson(this);
} 