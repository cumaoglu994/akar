import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'ad_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      return const Center(child: Text('الرجاء تسجيل الدخول'));
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: Supabase.instance.client
          .from(AppConstants.favoritesTable)
          .stream(primaryKey: ['user_id'])
          .eq('user_id', user.id)
          .map((event) => event.first),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data;
        final favoriteAds = data?['ads'] as List<dynamic>? ?? [];

        if (favoriteAds.isEmpty) {
          return const Center(child: Text('لا توجد إعلانات في المفضلة'));
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from(AppConstants.adsTable)
              .stream(primaryKey: ['id'])
              .eq('id', favoriteAds),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final ads = snapshot.data ?? [];

            if (ads.isEmpty) {
              return const Center(child: Text('لا توجد إعلانات في المفضلة'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                // The stream will automatically update the UI
                await Future.delayed(const Duration(milliseconds: 500));
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
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () async {
                          try {
                            final response = await Supabase.instance.client
                                .from(AppConstants.favoritesTable)
                                .select('ads')
                                .eq('user_id', user.id)
                                .single();

                            List<String> ads = [];
                            if (response != null && response['ads'] != null) {
                              ads = List<String>.from(response['ads']);
                            }

                            ads.remove(ad['id']);

                            await Supabase.instance.client
                                .from(AppConstants.favoritesTable)
                                .upsert({'user_id': user.id, 'ads': ads});
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('حدث خطأ: $e')),
                              );
                            }
                          }
                        },
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
        );
      },
    );
  }
} 