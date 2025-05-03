import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.favoritesCollection)
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final favoriteAds = data?['ads'] as List<dynamic>? ?? [];

        if (favoriteAds.isEmpty) {
          return const Center(child: Text('لا توجد إعلانات في المفضلة'));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.adsCollection)
              .where(FieldPath.documentId, whereIn: favoriteAds)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final ads = snapshot.data!.docs;

            if (ads.isEmpty) {
              return const Center(child: Text('لا توجد إعلانات في المفضلة'));
            }

            return ListView.builder(
              itemCount: ads.length,
              itemBuilder: (context, index) {
                final ad = ads[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: ad['images'] != null && ad['images'].isNotEmpty
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
                          builder: (context) => AdDetailsScreen(ad: ad),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
} 