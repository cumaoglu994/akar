import 'package:flutter/material.dart';
import '../home/home_content_screen.dart';
import '../home/my_ads_screen.dart';
import '../home/add_ad_screen.dart';
import '../home/chats_list_screen.dart';
import '../profile/profile_screen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeContentScreen(),
          MyAdsScreen(),
          AddAdScreen(),
          ChatsListScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: Colors.black,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        items: NavigationItems.items,
      ),
    );
  }
} 

class NavigationItems {
  static const List<BottomNavigationBarItem> items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'الرئيسية',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.list),
      label: 'إعلاناتي',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle_outline),
      label: 'إضافة إعلان',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat),
      label: 'المحادثات',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'حسابي',
    ),
  ];
} 