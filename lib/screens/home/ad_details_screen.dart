import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:card_swiper/card_swiper.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'chat_screen.dart';

class AdDetailsScreen extends StatefulWidget {
  final QueryDocumentSnapshot ad;

  const AdDetailsScreen({super.key, required this.ad});

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.favoritesCollection)
          .doc(user.uid)
          .get();
      
      if (doc.exists && doc.data()?['ads'] != null) {
        setState(() {
          _isFavorite = doc.data()!['ads'].contains(widget.ad.id);
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final docRef = FirebaseFirestore.instance
          .collection(AppConstants.favoritesCollection)
          .doc(user.uid);
      
      final doc = await docRef.get();
      List<String> ads = [];
      
      if (doc.exists && doc.data()?['ads'] != null) {
        ads = List<String>.from(doc.data()!['ads']);
      }
      
      if (_isFavorite) {
        ads.remove(widget.ad.id);
      } else {
        ads.add(widget.ad.id);
      }
      
      await docRef.set({'ads': ads});
      
      setState(() {
        _isFavorite = !_isFavorite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adData = widget.ad.data() as Map<String, dynamic>;
    final theme = Theme.of(context);
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: adData['images'] != null && adData['images'].isNotEmpty
                    ? Swiper(
                        itemBuilder: (BuildContext context, int index) {
                          return Image.network(
                            adData['images'][index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 50),
                              );
                            },
                          );
                        },
                        itemCount: adData['images'].length,
                        pagination: const SwiperPagination(
                          builder: DotSwiperPaginationBuilder(
                            color: Colors.grey,
                            activeColor: Colors.white,
                            size: 8.0,
                            activeSize: 10.0,
                          ),
                        ),
                        control: const SwiperControl(
                          color: Colors.white,
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 50),
                      ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? theme.colorScheme.error : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ],
            ),
            
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            adData['title'] ?? '',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_formatPrice(adData['price'] ?? 0)} ل.س',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Details Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              Icons.location_on,
                              'المدينة',
                              adData['city'] ?? '',
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.category,
                              'الفئة',
                              adData['category'] ?? '',
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              Icons.calendar_today,
                              'تاريخ النشر',
                              _formatDate((adData['createdAt'] as Timestamp).toDate()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      'الوصف',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      adData['description'] ?? '',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          color: theme.scaffoldBackgroundColor,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    sellerId: adData['userId'],
                    adId: widget.ad.id,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'تواصل مع البائع',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
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

  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} مليون';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)} ألف';
    }
    return price.toString();
  }
} 