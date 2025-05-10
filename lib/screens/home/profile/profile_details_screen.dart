import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الملف الشخصي'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile Image Section
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, size: 60, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // User Information Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المعلومات الشخصية',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.person,
                          label: 'الاسم',
                          value: user?.name ?? 'غير متوفر',
                        ),
                        _buildInfoRow(
                          icon: Icons.email,
                          label: 'البريد الإلكتروني',
                          value: user?.email ?? 'غير متوفر',
                        ),
                        _buildInfoRow(
                          icon: Icons.phone,
                          label: 'رقم الهاتف',
                          value: user?.phone ?? 'غير متوفر',
                        ),
                        _buildInfoRow(
                          icon: Icons.location_on,
                          label: 'العنوان',
                          value: user?.address ?? 'غير متوفر',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Account Information Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'معلومات الحساب',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.calendar_today,
                          label: 'تاريخ التسجيل',
                          value: user?.createdAt != null
                              ? _formatDate(user!.createdAt!)
                              : 'غير متوفر',
                        ),
                        _buildInfoRow(
                          icon: Icons.update,
                          label: 'آخر تحديث',
                          value: user?.updatedAt != null
                              ? _formatDate(user!.updatedAt!)
                              : 'غير متوفر',
                        ),
                        _buildInfoRow(
                          icon: Icons.login,
                          label: 'آخر تسجيل دخول',
                          value: user?.lastLogin != null
                              ? _formatDate(user!.lastLogin!)
                              : 'غير متوفر',
                        ),
                        _buildInfoRow(
                          icon: Icons.account_circle,
                          label: 'نوع الحساب',
                          value: user?.isAnonymous == true ? 'مجهول' : 'مسجل',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Edit Profile Button
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement edit profile functionality
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('تعديل الملف الشخصي'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute}';
  }
} 