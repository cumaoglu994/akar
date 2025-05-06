import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'add_ad_screen.dart';
import 'my_ads_screen.dart';
import '../profile/profile_screen.dart';
import 'ad_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  String _selectedCity = 'الكل';
  String _selectedCategory = 'الكل';
  int? _minPrice;
  int? _maxPrice;
  bool _showFilters = false;

  final List<String> _cities = [
    'الكل',
    'دمشق',
    'حلب',
    'حمص',
    'اللاذقية',
    'حماة',
    'طرطوس',
    'دير الزور',
    'الحسكة',
    'الرقة',
  ];

  final List<String> _categories = [
    'الكل',
    'سيارات',
    'عقارات',
    'موبايلات',
    'أثاث',
    'أجهزة كهربائية',
    'ملابس',
    'ألعاب',
    'حيوانات',
    'أخرى',
  ];

  Query<Map<String, dynamic>> _getFilteredQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection(AppConstants.adsCollection);

    // Önce sıralama yap
    query = query.orderBy('createdAt', descending: true);

    // Arama sorgusu
    if (_searchQuery.isNotEmpty) {
      query = query.where('title', isGreaterThanOrEqualTo: _searchQuery)
          .where('title', isLessThanOrEqualTo: _searchQuery + '\uf8ff');
    }

    // Şehir filtresi
    if (_selectedCity != 'الكل') {
      query = query.where('city', isEqualTo: _selectedCity);
    }

    // Kategori filtresi
    if (_selectedCategory != 'الكل') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    // Fiyat aralığı
    if (_minPrice != null && _maxPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: _minPrice)
          .where('price', isLessThanOrEqualTo: _maxPrice);
    } else if (_minPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: _minPrice);
    } else if (_maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: _maxPrice);
    }

    return query;
  }

  Future<void> _addSampleAds() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final ads = [
      {
        'title': 'سيارة تويوتا كامري 2020',
        'description': 'سيارة تويوتا كامري موديل 2020، لون أبيض، حالة ممتازة، مكفولة من الوكيل',
        'price': 85000000,
        'city': 'دمشق',
        'category': 'سيارات',
        'images': [
          'https://images.pexels.com/photos/170811/pexels-photo-170811.jpeg',
        ],
        'userId': user.uid,
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'شقة للبيع في المزة',
        'description': 'شقة للبيع في حي المزة، مساحة 120م، طابق ثالث، 3 غرف نوم، 2 حمام',
        'price': 5000000,
        'city': 'دمشق',
        'category': 'عقارات',
        'images': [
          'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg',
        ],
        'userId': user.uid,
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'آيفون 13 برو ماكس',
        'description': 'آيفون 13 برو ماكس، 256 جيجا، لون أزرق، حالة ممتازة، مع علبته الأصلية',
        'price': 12000000,
        'city': 'حلب',
        'category': 'موبايلات',
        'images': [
          'https://images.pexels.com/photos/699122/pexels-photo-699122.jpeg',
        ],
        'userId': user.uid,
        'createdAt': Timestamp.now(),
      },
    ];

    for (var ad in ads) {
      await FirebaseFirestore.instance.collection(AppConstants.adsCollection).add(ad);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppConstants.appName),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            Column(
              children: [
                // Search and Filter Bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Search Bar
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
                          // Filter Button
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
                      // Filter Options
                      if (_showFilters)
                        Card(
                          margin: const EdgeInsets.only(top: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // City Filter
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedCity,
                                        decoration: const InputDecoration(
                                          labelText: 'المدينة',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: _cities.map((String city) {
                                          return DropdownMenuItem<String>(
                                            value: city,
                                            child: Text(city),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _selectedCity = newValue!;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Category Filter
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedCategory,
                                        decoration: const InputDecoration(
                                          labelText: 'الفئة',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: _categories.map((String category) {
                                          return DropdownMenuItem<String>(
                                            value: category,
                                            child: Text(category),
                                          );
                                        }).toList(),
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
                                // Price Range
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
                // Ads List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _getFilteredQuery().snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final ads = snapshot.data?.docs ?? [];

                      if (ads.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.announcement, size: 50, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد إعلانات',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _addSampleAds,
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة عينات'),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: ads.length,
                        itemBuilder: (context, index) {
                          final ad = ads[index];
                          final adData = ad.data() as Map<String, dynamic>;
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdDetailsScreen(ad: ad),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: adData['images'] != null && adData['images'].isNotEmpty
                                          ? Image.network(
                                              adData['images'][0],
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.image, size: 40),
                                                );
                                              },
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.image, size: 40),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            adData['title'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            adData['description'] ?? '',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    adData['city'] ?? '',
                                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    adData['category'] ?? '',
                                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Price and Date
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${_formatPrice(adData['price'] ?? 0)} ل.س',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate((adData['createdAt'] as Timestamp).toDate()),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            AddAdScreen(),
            MyAdsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.grey),
              selectedIcon: Icon(Icons.home, color: Colors.green),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline, color: Colors.grey),
              selectedIcon: Icon(Icons.add_circle, color: Colors.green),
              label: 'إضافة إعلان',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined, color: Colors.grey),
              selectedIcon: Icon(Icons.list_alt, color: Colors.green),
              label: 'إعلاناتي',
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} مليون';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)} ألف';
    }
    return price.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'قبل ${difference.inMinutes} دقيقة';
      }
      return 'قبل ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'بالأمس';
    } else if (difference.inDays < 7) {
      return 'قبل ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}