import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../services/home_service.dart';
import 'ad_details_screen.dart';

class City {
  final String id;
  final String name;

  City({required this.id, required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'].toString(),
      name: json['name'].toString(),
    );
  }
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'].toString(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _searchQuery = '';
  String _selectedCity = 'all';
  String _selectedCategory = 'all';
  int? _minPrice;
  int? _maxPrice;
  bool _showFilters = false;
  final HomeService _homeService = HomeService();
  List<City> _city = [];
  List<Category> _category = [];
  bool _isLoading = true;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Şehirleri yükle
      final cityResponse = await Supabase.instance.client
          .from('city')
          .select()
          .order('id');

      // Kategorileri yükle
      final categoryResponse = await Supabase.instance.client
          .from('category')
          .select()
          .order('id');

      if (mounted) {
        setState(() {
          _city = (cityResponse as List).map((data) {
            return City(
              id: data['id'].toString(),
              name: data['name'].toString(),
            );
          }).toList();

          _category = (categoryResponse as List).map((data) {
            return Category(
              id: data['id'].toString(),
              name: data['name'].toString(),
            );
          }).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
    setState(() {});
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
                              child: _isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : DropdownButtonFormField<String>(
                                      value: _selectedCity,
                                      decoration: const InputDecoration(
                                        labelText: 'المدينة',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      ),
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      dropdownColor: Colors.white,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                      items: [
                                        const DropdownMenuItem(
                                          value: 'all',
                                          child: Text('كل المدن'),
                                        ),
                                        ..._city.map((city) {
                                          return DropdownMenuItem<String>(
                                            value: city.id,
                                            child: Text(
                                              city.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedCity = newValue;
                                          });
                                        }
                                      },
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : DropdownButtonFormField<String>(
                                      value: _selectedCategory,
                                      decoration: const InputDecoration(
                                        labelText: 'الفئة',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      ),
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      dropdownColor: Colors.white,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                      items: [
                                        const DropdownMenuItem(
                                          value: 'all',
                                          child: Text('كل الفئات'),
                                        ),
                                        ..._category.map((category) {
                                          return DropdownMenuItem<String>(
                                            value: category.id,
                                            child: Text(
                                              category.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedCategory = newValue;
                                          });
                                        }
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
          child: RefreshIndicator(
            key: _refreshKey,
            onRefresh: _refreshData,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from(AppConstants.adsTable)
                  .stream(primaryKey: ['id'])
                  .eq('status', 'yes')
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

                if (_selectedCity != 'all') {
                  final selectedCityName = _city.firstWhere(
                    (city) => city.id == _selectedCity,
                    orElse: () => City(id: '', name: ''),
                  ).name;
                  ads = ads.where((ad) => (ad['city']?.toString() ?? '') == selectedCityName).toList();
                }

                if (_selectedCategory != 'all') {
                  final selectedCategoryName = _category.firstWhere(
                    (category) => category.id == _selectedCategory,
                    orElse: () => Category(id: '', name: ''),
                  ).name;
                  ads = ads.where((ad) => (ad['category']?.toString() ?? '') == selectedCategoryName).toList();
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
                                  ad['images'][0].toString(),
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
                                  ad['city']?.toString() ?? '',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  ad['category']?.toString() ?? '',
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