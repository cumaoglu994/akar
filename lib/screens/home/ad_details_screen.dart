import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:card_swiper/card_swiper.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'chat_screen.dart';
import '../../providers/theme_provider.dart';

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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الإعلان'),
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.ad['images'] != null && widget.ad['images'].isNotEmpty)
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Swiper(
                    itemBuilder: (BuildContext context, int index) {
                      return Image.network(
                        widget.ad['images'][index],
                        fit: BoxFit.cover,
                      );
                    },
                    itemCount: widget.ad['images'].length,
                    pagination: const SwiperPagination(
                      builder: DotSwiperPaginationBuilder(
                        color: Colors.grey,
                        activeColor: ThemeProvider.primaryColor,
                        size: 8.0,
                        activeSize: 10.0,
                      ),
                    ),
                    control: const SwiperControl(
                      color: ThemeProvider.primaryColor,
                    ),
                    autoplay: true,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ad['title'],
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.ad['price']} ريال',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: ThemeProvider.successColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الوصف',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.ad['description'],
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'معلومات الإعلان',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('المدينة', widget.ad['city']),
                            _buildInfoRow('الفئة', widget.ad['category']),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection(AppConstants.usersCollection)
                              .doc(widget.ad['userId'])
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final userData = snapshot.data!.data() as Map<String, dynamic>;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'معلومات البائع',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('الاسم', userData['name']),
                                  _buildInfoRow('البريد الإلكتروني', userData['email']),
                                ],
                              );
                            }
                            return const Center(child: CircularProgressIndicator());
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
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
                    sellerId: widget.ad['userId'],
                    adId: widget.ad.id,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: ThemeProvider.secondaryTextColor,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
} 