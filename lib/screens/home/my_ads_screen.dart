import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'ad_details_screen.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _refreshData() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  String _formatPrice(num price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} مليون';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)} ألف';
    }
    return price.toString();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Center(child: Text('يرجى تسجيل الدخول'));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from(AppConstants.adsTable)
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final ads = snapshot.data ?? [];

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
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add-ad');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة إعلان جديد'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          key: _refreshKey,
          onRefresh: _refreshData,
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
                            ad['images'][0].toString(),
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
                  title: Text(ad['title']?.toString() ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_formatPrice(ad['price'] ?? 0)} ليرة سورية'),
                      Text(ad['city']?.toString() ?? ''),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ad['status'] == 'yes' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
  ad['status'] == 'yes'
      ? 'تمت الموافقة'
      : ad['status'] == 'no'
          ? 'تم الرفض'
          : 'في انتظار الموافقة',
  style: TextStyle(
    color: ad['status'] == 'yes'
        ? Colors.green
        : ad['status'] == 'no'
            ? Colors.red
            : Colors.orange,
    fontWeight: FontWeight.bold,
    fontSize: 12,
  ),
),


                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('تأكيد الحذف'),
                          content: const Text('هل أنت متأكد من حذف هذا الإعلان؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('حذف'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        try {
                          if (ad['images'] != null && (ad['images'] as List).isNotEmpty) {
                            for (var imageUrl in ad['images']) {
                              try {
                                final imagePath = imageUrl.toString().split('/').last;
                                await Supabase.instance.client.storage
                                    .from(AppConstants.adsImagesBucket)
                                    .remove([imagePath]);
                              } catch (e) {
                                debugPrint('خطأ في حذف الصورة: $e');
                              }
                            }
                          }

                          final response = await Supabase.instance.client
                              .from(AppConstants.adsTable)
                              .delete()
                              .eq('id', ad['id'].toString())
                              .select();

                          // Yükleme dialogunu kapat
                          if (context.mounted) {
                            Navigator.pop(context);
                          }

                          if (response != null && response.isNotEmpty) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم حذف الإعلان بنجاح'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _refreshKey.currentState?.show();
                            }
                          } else {
                            throw Exception('فشل حذف الإعلان');
                          }
                        } catch (e) {
                          // Yükleme dialogunu kapat
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('حدث خطأ أثناء حذف الإعلان: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
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
  }
} 