import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ad_model.dart';
import '../models/category_model.dart';
import '../models/location_models.dart';

class HomeService {
  final SupabaseClient _supabase;

  HomeService(this._supabase);

  // Get all ads with related data
  Future<List<Ad>> getAds() async {
    final response = await _supabase
        .from('ads')
        .select('*')
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Ad.fromJson(json)).toList();
  }

  // Get all category
  Future<List<Category>> getCategory() async {
    final response = await _supabase
        .from('category')
        .select()
        .order('name');
    
    return (response as List).map((json) => Category.fromJson(json)).toList();
  }

  // Get all cities
  Future<List<City>> getCity() async {
    final response = await _supabase
        .from('city')
        .select()
        .order('name');
    
    return (response as List).map((json) => City.fromJson(json)).toList();
  }

  // Get ads by category
  Future<List<Ad>> getAdsByCategory(String categoryId) async {
    final response = await _supabase
        .from('ads')
        .select('''
          *,
          category:category(*),
          city:city(*),
          district:districts(*),
          neighborhood:neighborhoods(*),
          street:streets(*)
        ''')
        .eq('category_id', categoryId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Ad.fromJson(json)).toList();
  }

  // Get ads by city
  Future<List<Ad>> getAdsByCity(String cityId) async {
    final response = await _supabase
        .from('ads')
        .select('''
          *,
          category:category(*),
          city:cities(*),
          district:districts(*),
          neighborhood:neighborhoods(*),
          street:streets(*)
        ''')
        .eq('city_id', cityId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Ad.fromJson(json)).toList();
  }

  // Search ads
  Future<List<Ad>> searchAds(String query) async {
    final response = await _supabase
        .from('ads')
        .select('''
          *,
          category:category(*),
          city:cities(*),
          district:districts(*),
          neighborhood:neighborhoods(*),
          street:streets(*)
        ''')
        .or('title.ilike.%$query%,description.ilike.%$query%')
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Ad.fromJson(json)).toList();
  }
} 