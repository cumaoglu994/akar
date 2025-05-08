import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Map<String, bool> _notificationSettings = {
    'الإشعارات العامة': true,
    'إشعارات المنتجات': true,
    'إشعارات الرسائل': true,
    'إشعارات الطلبات': true,
    'إشعارات العروض': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إعدادات الإشعارات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اختر أنواع الإشعارات التي تريد تلقيها',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _notificationSettings.length,
              itemBuilder: (context, index) {
                final setting = _notificationSettings.entries.elementAt(index);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SwitchListTile(
                    title: Text(
                      setting.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: setting.value,
                    onChanged: (value) {
                      setState(() {
                        _notificationSettings[setting.key] = value;
                      });
                      // TODO: Implement notification setting change
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 