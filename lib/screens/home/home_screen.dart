import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../services/home_service.dart';
import '../../models/ad_model.dart';
import '../../models/category_model.dart';
import '../../models/location_models.dart';
import '../navigation/navigation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(AppConstants.appName),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.asset(
                    'assets/icons/AppLogo.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
        body:NavigationScreen(),);
  }
}
