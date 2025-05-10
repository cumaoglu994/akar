import 'package:akar/services/home_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ad_details_screen.dart';
import '../../utils/constants.dart';

class AdsListScreen extends StatefulWidget {
  const AdsListScreen({super.key});

  @override
  State<AdsListScreen> createState() => _AdsListScreenState();
}

class _AdsListScreenState extends State<AdsListScreen> {
  String _selectedCategory = 'الكل';
  String _selectedCity = 'الكل';
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _categories = [];
  List<dynamic> _cities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final homeService = HomeService();
    final categories = await homeService.getCategories();
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
        // Search and Filter Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن إعلان...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'الكل',
                          child: Text('كل الفئات'),
                        ),
                        ..._categories.map((category) {
                          return DropdownMenuItem(
                            value: category['name'],
                            child: Text(category['name']),
                          );
                        }),
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
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'الكل',
                          child: Text('كل المدن'),
                        ),
                        ..._cities.map((city) {
                          return DropdownMenuItem(
                            value: city['name'],
                            child: Text(city['name']),
                          );
                        }),
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
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from(AppConstants.adsTable)
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

              return RefreshIndicator(
                onRefresh: () async {
                  await _loadData();
                },
                child: ListView.builder(
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: ad['images'] != null && (ad['images'] as List).isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  ad['images'][0],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image_not_supported),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                        title: Text(ad['title'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ad['price'] ?? ''),
                            Text(ad['city'] ?? ''),
                            Text(
                              ad['status'] == 'yes' ? 'تم الموافقة' : 'في انتظار الموافقة',
                              style: TextStyle(
                                color: ad['status'] == 'yes' ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdDetailsScreen(ad: ad),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 