import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ad_details_screen.dart';
import '../../models/ad_model.dart';
import '../../services/home_service.dart';
import '../../models/category_model.dart';
import '../../models/location_models.dart';

class AdsListScreen extends StatefulWidget {
  const AdsListScreen({super.key});

  @override
  State<AdsListScreen> createState() => _AdsListScreenState();
}

class _AdsListScreenState extends State<AdsListScreen> {
  String _selectedCategory = 'الكل';
  String _selectedCity = 'الكل';
  final TextEditingController _searchController = TextEditingController();
  List<Category> _categories = [];
  List<City> _cities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final homeService = HomeService(Supabase.instance.client);
    final categories = await homeService.getCategory();
    final cities = await homeService.getCity();
    setState(() {
      _categories = categories;
      _cities = cities;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن إعلان',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: 'الكل',
                      child: Text('الكل'),
                    ),
                    ..._categories.map((category) => DropdownMenuItem<String>(
                          value: category.id ?? '',
                          child: Text(category.name ?? ''),
                        ))
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: 'الكل',
                      child: Text('الكل'),
                    ),
                    ..._cities.map((city) => DropdownMenuItem<String>(
                          value: city.id,
                          child: Text(city.name),
                        ))
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('ads')
                .stream(primaryKey: ['id'])
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('حدث خطأ: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var ads = snapshot.data ?? [];
              
              // Apply filters
              if (_selectedCategory != 'الكل') {
                ads = ads.where((ad) => 
                  ad['category'] == _selectedCategory).toList();
              }
              
              if (_selectedCity != 'الكل') {
                ads = ads.where((ad) => 
                  ad['city'] == _selectedCity).toList();
              }
              
              if (_searchController.text.isNotEmpty) {
                ads = ads.where((ad) => 
                  ad['title'].toString().toLowerCase()
                    .contains(_searchController.text.toLowerCase()) ||
                  ad['description'].toString().toLowerCase()
                    .contains(_searchController.text.toLowerCase())
                ).toList();
              }

              if (ads.isEmpty) {
                return const Center(child: Text('لا توجد إعلانات'));
              }

              return ListView.builder(
                itemCount: ads.length,
                itemBuilder: (context, index) {
                  var ad = ads[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: ad['images'] != null && (ad['images'] as List).isNotEmpty
                          ? Image.network(
                              ad['images'][0],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image),
                      title: Text(ad['title']),
                      subtitle: Text('${ad['price']} ريال - ${ad['city']}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdDetailsScreen(
                              ad: ad,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
} 