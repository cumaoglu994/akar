// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ad_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ad _$AdFromJson(Map<String, dynamic> json) => Ad(
  id: json['id'] as String?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  price: (json['price'] as num?)?.toDouble(),
 // imageUrl: json['image_url'] as String?,
  userId: json['user_id'] as String?,
  categoryId: json['category_id'] as String?,
  cityId: json['city_id'] as String?,
  districtId: json['district_id'] as String?,
  neighborhoodId: json['neighborhood_id'] as String?,
  streetId: json['street_id'] as String?,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$AdToJson(Ad instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'price': instance.price,
  //'image_url': instance.imageUrl,
  'user_id': instance.userId,
  'category_id': instance.categoryId,
  'city_id': instance.cityId,
  'district_id': instance.districtId,
  'neighborhood_id': instance.neighborhoodId,
  'street_id': instance.streetId,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
