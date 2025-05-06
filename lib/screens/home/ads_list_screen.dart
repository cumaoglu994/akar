import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/constants.dart';
import 'ad_details_screen.dart';

class AdsListScreen extends StatefulWidget {
  const AdsListScreen({super.key});

  @override
  State<AdsListScreen> createState() => _AdsListScreenState();
}

class _AdsListScreenState extends State<AdsListScreen> {
  String _selectedCategory = 'الكل';
  String _selectedCity = 'الكل';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن إعلان',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: ['الكل', ...AppConstants.categories]
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
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
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: ['الكل', ...AppConstants.cities]
                      .map((city) => DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.adsCollection)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('حدث خطأ: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var ads = snapshot.data!.docs;
              
              // Apply filters
              if (_selectedCategory != 'الكل') {
                ads = ads.where((doc) => 
                  doc['category'] == _selectedCategory).toList();
              }
              
              if (_selectedCity != 'الكل') {
                ads = ads.where((doc) => 
                  doc['city'] == _selectedCity).toList();
              }
              
              if (_searchController.text.isNotEmpty) {
                ads = ads.where((doc) => 
                  doc['title'].toString().toLowerCase()
                    .contains(_searchController.text.toLowerCase()) ||
                  doc['description'].toString().toLowerCase()
                    .contains(_searchController.text.toLowerCase())
                ).toList();
              }

              if (ads.isEmpty) {
                return const Center(child: Text('لا توجد إعلانات'));
              }

              return ListView.builder(
                itemCount: ads.length,
                itemBuilder: (context, index) {
                  var ad = ads[index];
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
          ),
        ),
      ],
    );
  }
} 