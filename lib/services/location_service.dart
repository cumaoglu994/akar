import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location_models.dart';

class LocationService {
  final SupabaseClient _supabase;

  LocationService(this._supabase);

  // Get all city
  Future<List<City>> getCity() async {
    final response = await _supabase
        .from('city')
        .select()
        .order('name');
    
    return (response as List).map((json) => City.fromJson(json)).toList();
  }

  // Get districts by city
  Future<List<District>> getDistrictByCity(String cityId) async {
    final response = await _supabase
        .from('district')
        .select()
        .eq('city_id', cityId)
        .order('name');
    
    return (response as List).map((json) => District.fromJson(json)).toList();
  }

  // Get neighborhoods by district
  Future<List<Neighborhood>> getNeighborhoodByDistrict(String districtId) async {
    final response = await _supabase
        .from('neighborhood')
        .select()
        .eq('district_id', districtId)
        .order('name');
    
    return (response as List).map((json) => Neighborhood.fromJson(json)).toList();
  }

  // Get streets by neighborhood
  Future<List<Street>> getStreetsByNeighborhood(String neighborhoodId) async {
    final response = await _supabase
        .from('streets')
        .select()
        .eq('neighborhood_id', neighborhoodId)
        .order('name');
    
    return (response as List).map((json) => Street.fromJson(json)).toList();
  }

  // Get full address details
  Future<Map<String, dynamic>> getFullAddressDetails(String streetId) async {
    final response = await _supabase
        .from('streets')
        .select('''
          id,
          name,
          neighborhood:neighborhoods (
            id,
            name,
            district:districts (
              id,
              name,
              city:cities (
                id,
                name
              )
            )
          )
        ''')
        .eq('id', streetId)
        .single();
    
    return response;
  }
} 