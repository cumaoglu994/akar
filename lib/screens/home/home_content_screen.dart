import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../services/home_service.dart';
import '../../models/ad_model.dart';
import '../../models/category_model.dart';
import '../../models/location_models.dart';
import 'ad_details_screen.dart';

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  String _searchQuery = '';
  String _selectedCity = 'الكل';
  String _selectedCategory = 'الكل';
  int? _minPrice;
  int? _maxPrice;
  bool _showFilters = false;
  final HomeService _homeService = HomeService(Supabase.instance.client);
  List<City> _city = [];
  List<Category> _category = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final city = await _homeService.getCity();
      final category = await _homeService.getCategory();
      setState(() {
        _city = city;
        _category = category;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
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
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    icon: const Icon(Icons.filter_list),
                    label: const Text('تصفية'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ],
              ),
              if (_showFilters)
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCity,
                                decoration: const InputDecoration(
                                  labelText: 'المدينة',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: 'الكل',
                                    child: Text('الكل'),
                                  ),
                                  ..._city.map((city) {
                                    return DropdownMenuItem<String>(
                                      value: city.id,
                                      child: Text(city.name),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedCity = newValue!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'الفئة',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: 'الكل',
                                    child: Text('الكل'),
                                  ),
                                  ..._category.map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category.id ?? '',
                                      child: Text(category.name ?? ''),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedCategory = newValue!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'الحد الأدنى للسعر',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _minPrice = int.tryParse(value);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'الحد الأقصى للسعر',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _maxPrice = int.tryParse(value);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
              if (_searchQuery.isNotEmpty) {
                ads = ads.where((ad) => 
                  (ad['title'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
                ).toList();
              }

              if (_selectedCity != 'الكل') {
                ads = ads.where((ad) => ad['city_id'] == _selectedCity).toList();
              }

              if (_selectedCategory != 'الكل') {
                ads = ads.where((ad) => ad['category_id'] == _selectedCategory).toList();
              }

              if (_minPrice != null) {
                ads = ads.where((ad) => (ad['price'] ?? 0) >= _minPrice!).toList();
              }

              if (_maxPrice != null) {
                ads = ads.where((ad) => (ad['price'] ?? 0) <= _maxPrice!).toList();
              }

              if (ads.isEmpty) {
                return const Center(
                  child: Text('لا توجد إعلانات'),
                );
              }

              return ListView.builder(
                itemCount: ads.length,
                itemBuilder: (context, index) {
                  final ad = ads[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ad['images'] != null && (ad['images'] as List).isNotEmpty
                            ? Image.network(
                                ad['images'][0],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error),
                                  );
                                },
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image),
                              ),
                      ),
                      title: Text(ad['title'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_formatPrice(ad['price'] ?? 0)} ل.س',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                _city.firstWhere(
                                  (city) => city.id == ad['city_id'],
                                  orElse: () => City(
                                    id: '',
                                    name: 'غير محدد',
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  ),
                                ).name,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.category, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                _category.firstWhere(
                                  (category) => category.id == ad['category_id'],
                                  orElse: () => Category(id: '', name: 'غير محدد'),
                                ).name ?? 'غير محدد',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
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
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatPrice(num price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} مليون';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)} ألف';
    }
    return price.toString();
  }
} 