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

// Not: Bu widget'i kullanmak için uygulamanızın MaterialApp'inde 
// locale ve textDirection ayarlarını yapmayı unutmayın:
// MaterialApp(
//   locale: const Locale('ar', 'SA'),
//   localizationsDelegates: const [
//     GlobalMaterialLocalizations.delegate,
//     GlobalWidgetsLocalizations.delegate,
//     GlobalCupertinoLocalizations.delegate,
//   ],
//   supportedLocales: const [
//     Locale('ar', 'SA'),
//   ],
// )

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
  String? _selectedCity = 'all';
  String _selectedCategory = 'all';
  int? _minPrice;
  int? _maxPrice;
  bool _showFilters = false;
  final HomeService _homeService = HomeService();
  List<City> _city = [];
  List<Category> _category = [];
  bool _isLoading = true;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  List<Map<String, dynamic>> _ads = [];
  RealtimeChannel? _channel;
  List<String> _countries = [];
  String? _selectedCountry;
  List<dynamic> _filteredCities = [];
  List<dynamic> _cities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeSubscription();
    _loadCities();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _channel = Supabase.instance.client
        .channel('public:${AppConstants.adsTable}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: AppConstants.adsTable,
          callback: (payload) {
            _loadData();
          },
        )
        .subscribe();
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

      // İlanları yükle
      final adsResponse = await Supabase.instance.client
          .from(AppConstants.adsTable)
          .select()
          .eq('status', 'yes')
          .order('created_at', ascending: false);

      debugPrint('Supabase ads response: ' + adsResponse.toString());

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

          // Parse ads and handle images array
          _ads = (adsResponse as List).map((ad) {
            // Parse images string to List
            if (ad['images'] != null) {
              try {
                final imagesStr = ad['images'].toString();
                debugPrint('Processing images for ad ${ad['title']}: $imagesStr');
                
                if (imagesStr.startsWith('"') && imagesStr.endsWith('"')) {
                  // Remove the outer quotes and parse the JSON array
                  final cleanStr = imagesStr.substring(1, imagesStr.length - 1);
                  final images = List<String>.from(
                    (cleanStr as String).split(',').map((url) => url.trim().replaceAll('"', '')),
                  );
                  debugPrint('Parsed images: $images');
                  ad['images'] = images;
                }
              } catch (e) {
                debugPrint('Error parsing images for ad ${ad['title']}: $e');
                ad['images'] = [];
              }
            }
            return ad as Map<String, dynamic>;
          }).toList();

          debugPrint('Total ads loaded: ${_ads.length}');
          debugPrint('Ads titles: ${_ads.map((ad) => ad['title']).toList()}');

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error in _loadData: $e');
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

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _applyFilters() {
    setState(() {
      _showFilters = false;
    });
    // Filtrelerin uygulandığı görsel bir onay
    ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
        content: Text('تم تطبيق الفلاتر'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedCity = 'all';
      _selectedCategory = 'all';
      _minPrice = null;
      _maxPrice = null;
      _selectedCountry = _countries.isNotEmpty ? _countries[0] : null;
      _filteredCities = _cities.where((city) => city['country'] == _selectedCountry).toList();
    });
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _homeService.getCity();
      setState(() {
        _cities = cities;
        // Ülkeleri benzersiz olarak çıkar
        _countries = _cities.map((city) => city['country'].toString()).toSet().toList();
        if (_countries.isNotEmpty) {
          _selectedCountry = _countries[0];
          _filteredCities = _cities.where((city) => city['country'] == _selectedCountry).toList();
          if (_filteredCities.isNotEmpty) {
            _selectedCity = _filteredCities[0]['name']?.toString();
          }
        }
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('خطأ في تحميل المدن: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Arapça için sağdan sola yazım yönü ayarı
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _buildMainContent(context),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Modern Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'ابحث عن إعلان...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _showFilters ? Icons.close : Icons.tune,
                      color: Colors.white,
                    ),
                    onPressed: _toggleFilters,
                  ),
                ),
              ],
            ),
          ),

          // Kompakt Filtreler
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? 170 : 0,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    // İlk satır: Ülke ve Şehir
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedCountry,
                            hint: 'الدولة',
                            icon: Icons.flag,
                            items: _countries.map((country) {
                              return DropdownMenuItem<String>(
                                value: country,
                                child: Text(country),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCountry = value;
                                  _filteredCities = _cities.where((city) => city['country'] == value).toList();
                                  _selectedCity = _filteredCities.isNotEmpty ? _filteredCities[0]['name']?.toString() : null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: (() {
                            final cityNames = _filteredCities
                                .map((city) => city['name']?.toString())
                                .where((name) => name != null && name.isNotEmpty)
                                .toSet()
                                .toList();
                            final dropdownCityValue = cityNames.contains(_selectedCity) ? _selectedCity : null;
                            return _buildDropdown(
                              value: dropdownCityValue,
                              hint: 'المدينة',
                              icon: Icons.location_city,
                              items: cityNames.map((name) {
                                return DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(name ?? ''),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedCity = value);
                                }
                              },
                            );
                          })(),
                        ), const SizedBox(width: 10),
                         Expanded(
                           child: _buildCategoryDropdown(),
                         ),
                      ],
                    ),
                    
                    const SizedBox(height: 10),
                    // İkinci satır: Fiyat aralığı
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            hint: 'الحد الأدنى للسعر',
                            icon: Icons.money,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _minPrice = int.tryParse(value);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            hint: 'الحد الأقصى للسعر',
                            icon: Icons.money,
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
                    const SizedBox(height: 10),
                    // Üçüncü satır: Butonlar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة تعيين'),
                          onPressed: _resetFilters,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('تطبيق'),
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // İlan Listesi
          Expanded(
            child: RefreshIndicator(
              key: _refreshKey,
              onRefresh: _loadData,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildAdsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
          hintText: hint,
          border: InputBorder.none,
        ),
        items: items,
        onChanged: onChanged,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        isDense: true,
        isExpanded: true,
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
          hintText: hint,
          border: InputBorder.none,
        ),
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAdsList() {
    var filteredAds = _ads.where((ad) {
      // Arama filtresi
      if (_searchQuery.isNotEmpty) {
        final title = ad['title']?.toString().toLowerCase() ?? '';
        final description = ad['description']?.toString().toLowerCase() ?? '';
        if (!title.contains(_searchQuery.toLowerCase()) && 
            !description.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // Şehir filtresi
      if (_selectedCity != null && _selectedCity != 'all') {
        final adCity = ad['city']?.toString() ?? '';
        if (adCity != _selectedCity) {
          return false;
        }
      }

      // Kategori filtresi
      if (_selectedCategory != 'all') {
        final adCategory = ad['category']?.toString() ?? '';
        if (adCategory != _selectedCategory) {
          return false;
        }
      }

      // Fiyat filtresi
      final price = ad['price'] as num? ?? 0;
      if (_minPrice != null && price < _minPrice!) {
        return false;
      }
      if (_maxPrice != null && price > _maxPrice!) {
        return false;
      }

      return true;
    }).toList();

    if (filteredAds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredAds.length,
      itemBuilder: (context, index) {
        final ad = filteredAds[index];
        return _buildAdCard(context, ad);
      },
    );
  }

  Widget _buildAdCard(BuildContext context, Map<String, dynamic> ad) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdDetailsScreen(ad: ad),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İlan resmi
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: ad['images'] != null && (ad['images'] as List).isNotEmpty
                    ? Image.network(
                        ad['images'][0].toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.error, size: 50, color: Colors.grey[600]),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[600]),
                      ),
              ),
            ),
            
            // İlan bilgileri
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ad['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 18,),
                      Text(
                        '${_formatPrice(ad['price'] ?? 0)} ل.س',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        ad['city']?.toString() ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.category, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ad['category']?.toString() ?? '',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildCategoryDropdown() {
    return _buildDropdown(
      value: _selectedCategory,
      hint: 'الفئة',
      icon: Icons.category,
      items: [
        const DropdownMenuItem(
          value: 'all',
          child: Text('الكل'),
        ),
        ..._category.map((category) {
          return DropdownMenuItem<String>(
            value: category.name,
            child: Text(category.name),
          );
        }).toList(),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
    );
  }
}