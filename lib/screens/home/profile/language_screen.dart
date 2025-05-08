import 'package:flutter/material.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'العربية';

  final List<Map<String, String>> _languages = [
    {'name': 'العربية', 'code': 'ar'},
    {'name': 'English', 'code': 'en'},
    {'name': 'Français', 'code': 'fr'},
    {'name': 'Español', 'code': 'es'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اللغة'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: _languages.length,
        itemBuilder: (context, index) {
          final language = _languages[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: RadioListTile<String>(
              title: Text(
                language['name']!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: language['name']!,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                // TODO: Implement language change
              },
              activeColor: Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }
} 