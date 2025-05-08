import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعدة والدعم'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContactCard(context),
              const SizedBox(height: 24),
              const Text(
                'الأسئلة الشائعة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildFAQSection(),
              const SizedBox(height: 24),
              _buildSupportOptions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.support_agent,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'نحن هنا للمساعدة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك التواصل معنا على مدار الساعة',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement chat support
              },
              icon: const Icon(Icons.chat),
              label: const Text('ابدأ المحادثة'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final List<Map<String, String>> faqs = [
      {
        'question': 'كيف يمكنني تغيير كلمة المرور؟',
        'answer': 'يمكنك تغيير كلمة المرور من خلال الذهاب إلى الملف الشخصي ثم اختيار تغيير كلمة المرور.',
      },
      {
        'question': 'كيف يمكنني إضافة منتج جديد؟',
        'answer': 'يمكنك إضافة منتج جديد من خلال الضغط على زر "إضافة منتج" في الصفحة الرئيسية.',
      },
      {
        'question': 'كيف يمكنني تتبع طلبي؟',
        'answer': 'يمكنك تتبع طلبك من خلال الذهاب إلى قسم "الطلبات" في حسابك.',
      },
    ];

    return Column(
      children: faqs.map((faq) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              faq['question']!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  faq['answer']!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSupportOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'خيارات الدعم',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSupportOption(
          icon: Icons.email,
          title: 'البريد الإلكتروني',
          subtitle: 'support@example.com',
          onTap: () {
            // TODO: Implement email support
          },
        ),
        _buildSupportOption(
          icon: Icons.phone,
          title: 'الهاتف',
          subtitle: '+966 50 000 0000',
          onTap: () {
            // TODO: Implement phone support
          },
        ),
        _buildSupportOption(
          icon: Icons.location_on,
          title: 'العنوان',
          subtitle: 'الرياض، المملكة العربية السعودية',
          onTap: () {
            // TODO: Implement location
          },
        ),
      ],
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
} 