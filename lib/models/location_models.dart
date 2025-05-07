import 'package:json_annotation/json_annotation.dart';

part 'location_models.g.dart';

@JsonSerializable()
class City {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  City({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);
  Map<String, dynamic> toJson() => _$CityToJson(this);
}

@JsonSerializable()
class District {
  final String id;
  final String cityId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  District({
    required this.id,
    required this.cityId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory District.fromJson(Map<String, dynamic> json) => _$DistrictFromJson(json);
  Map<String, dynamic> toJson() => _$DistrictToJson(this);
}

@JsonSerializable()
class Neighborhood {
  final String id;
  final String districtId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  Neighborhood({
    required this.id,
    required this.districtId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Neighborhood.fromJson(Map<String, dynamic> json) => _$NeighborhoodFromJson(json);
  Map<String, dynamic> toJson() => _$NeighborhoodToJson(this);
}

@JsonSerializable()
class Street {
  final String id;
  final String neighborhoodId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  Street({
    required this.id,
    required this.neighborhoodId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Street.fromJson(Map<String, dynamic> json) => _$StreetFromJson(json);
  Map<String, dynamic> toJson() => _$StreetToJson(this);
} 