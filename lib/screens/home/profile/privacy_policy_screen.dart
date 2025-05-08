import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'مقدمة',
                content: 'نحن نقدر خصوصيتك ونلتزم بحماية بياناتك الشخصية. توضح سياسة الخصوصية هذه كيفية جمع واستخدام وحماية معلوماتك.',
              ),
              _buildSection(
                title: 'جمع المعلومات',
                content: 'نقوم بجمع المعلومات التي تقدمها لنا مباشرة عند التسجيل أو استخدام خدماتنا، بما في ذلك الاسم وعنوان البريد الإلكتروني ورقم الهاتف.',
              ),
              _buildSection(
                title: 'استخدام المعلومات',
                content: 'نستخدم معلوماتك لتقديم وتحسين خدماتنا، والاتصال بك، وتخصيص تجربتك، وضمان أمن حسابك.',
              ),
              _buildSection(
                title: 'حماية المعلومات',
                content: 'نحن نستخدم تقنيات تشفير متقدمة لحماية معلوماتك الشخصية وضمان عدم وصولها إلى أطراف غير مصرح لها.',
              ),
              _buildSection(
                title: 'حقوقك',
                content: 'لديك الحق في الوصول إلى معلوماتك الشخصية وتعديلها أو حذفها في أي وقت. يمكنك أيضًا طلب نسخة من بياناتك الشخصية.',
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'آخر تحديث: ${DateTime.now().year}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 