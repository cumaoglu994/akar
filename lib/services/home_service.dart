import 'package:supabase_flutter/supabase_flutter.dart';


class HomeService {

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<dynamic>> getAds() async {
    final response = await _supabase.from('ads') .select('*')
        .order('created_at', ascending: false);
    return response as List<dynamic>;
  }
  Future<List<dynamic>> getCategories() async {
    final response = await _supabase.from('categories').select();
    return response as List<dynamic>;
  } Future<List<dynamic>> getchat() async {
    final response = await _supabase.from('chats').select();
    return response as List<dynamic>;
  } Future<List<dynamic>> getCity() async {
    final response = await _supabase.from('cities')..select()
        .order('name');
    return response as List<dynamic>;
  } Future<List<dynamic>> getFavorites() async {
    final response = await _supabase.from('favorites').select();
    return response as List<dynamic>;
  }
  Future<List<dynamic>> getUser() async {
    final response = await _supabase.from('users').select();
    return response as List<dynamic>;
  
}











  // Search ads

} 