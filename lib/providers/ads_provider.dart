import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class AdsProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _ads = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get ads => _ads;
  bool get isLoading => _isLoading;

  Future<void> fetchAds() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase
          .from(AppConstants.adsTable)
          .select()
          .order('created_at', ascending: false);

      _ads = response;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching ads: $e');
    }
  }

  Future<void> createAd({
    required String title,
    required String description,
    required String price,
    required String city,
    required String category,
    required List<String> images,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase.from(AppConstants.adsTable).insert({
        'user_id': user.id,
        'title': title,
        'description': description,
        'price': price,
        'city': city,
        'category': category,
        'images': images,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      _ads.insert(0, response);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error creating ad: $e');
      rethrow;
    }
  }

  Future<void> deleteAd(String adId) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _supabase.from(AppConstants.adsTable).delete().eq('id', adId);
      _ads.removeWhere((ad) => ad['id'] == adId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error deleting ad: $e');
      rethrow;
    }
  }
} 