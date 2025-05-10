import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'الملف الشخصي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                // TODO: Navigate to settings
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header Section with Background
              Container(
                color: theme.primaryColor,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Profile Image with edit button
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.person, size: 60, color: Colors.grey),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.blue),
                            onPressed: () {
                              // TODO: Implement photo change functionality
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // User name with verified badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user?.name ?? 'غير متوفر',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Colors.white, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Email with subtle styling
                    Text(
                      user?.email ?? 'غير متوفر',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              
              // Quick Stats Section
              // Padding(
              //   padding: const EdgeInsets.symmetric(vertical: 8),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //     children: [
              //       _buildQuickStat(context, '150', 'المتابعون'),
              //       _buildDivider(),
              //       _buildQuickStat(context, '254', 'المتابَعون'),
              //       _buildDivider(),
              //       _buildQuickStat(context, '10', 'المنشورات'),
              //     ],
              //   ),
              // ),
              
              const SizedBox(height: 16),
              
              // Personal Information Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline, color: theme.primaryColor),
                            const SizedBox(width: 8),
                            const Text(
                              'المعلومات الشخصية',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: theme.primaryColor),
                              onPressed: () {
                                // TODO: Edit personal info
                              },
                              tooltip: 'تعديل المعلومات',
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildModernInfoRow(
                          icon: Icons.phone_android,
                          label: 'رقم الهاتف',
                          value: user?.phone ?? 'غير متوفر',
                        ),
                        _buildModernInfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'العنوان',
                          value: user?.address ?? 'غير متوفر',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Account Information Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security_outlined, color: theme.primaryColor),
                            const SizedBox(width: 8),
                            const Text(
                              'معلومات الحساب',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildModernInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'تاريخ التسجيل',
                          value: user?.createdAt != null
                              ? _formatDate(user!.createdAt!)
                              : 'غير متوفر',
                        ),
                        _buildModernInfoRow(
                          icon: Icons.update_outlined,
                          label: 'آخر تحديث',
                          value: user?.updatedAt != null
                              ? _formatDate(user!.updatedAt!)
                              : 'غير متوفر',
                        ),
                        _buildModernInfoRow(
                          icon: Icons.login_outlined,
                          label: 'آخر تسجيل دخول',
                          value: user?.lastLogin != null
                              ? _formatDate(user!.lastLogin!)
                              : 'غير متوفر',
                        ),
                        // _buildModernInfoRow(
                        //   icon: Icons.account_circle_outlined,
                        //   label: 'نوع الحساب',
                        //   value: user?.isAnonymous == true ? 'مجهول' : 'مسجل',
                        //   isLast: true,
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: ElevatedButton.icon(
              //           onPressed: () {
              //             // TODO: Implement edit profile functionality
              //           },
              //           icon: const Icon(Icons.edit),
              //           label: const Text('تعديل الملف'),
              //           style: ElevatedButton.styleFrom(
              //             padding: const EdgeInsets.symmetric(vertical: 12),
              //             shape: RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(12),
              //             ),
              //             backgroundColor: theme.primaryColor,
              //             foregroundColor: Colors.white,
              //           ),
              //         ),
              //       ),
              //       const SizedBox(width: 12),
              //       Container(
              //         decoration: BoxDecoration(
              //           color: Colors.grey[200],
              //           borderRadius: BorderRadius.circular(12),
              //         ),
              //         child: IconButton(
              //           onPressed: () {
              //             // TODO: Implement QR code share
              //           },
              //           icon: const Icon(Icons.qr_code),
              //           tooltip: 'مشاركة الملف الشخصي',
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: Colors.blue),
          ),
          const SizedBox(width: 16),
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
  
  Widget _buildQuickStat(BuildContext context, String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  String _formatDate(DateTime date) {
    // Format with leading zeros for better appearance
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    String year = date.year.toString();
    String hour = date.hour.toString().padLeft(2, '0');
    String minute = date.minute.toString().padLeft(2, '0');
    
    return '$year/$month/$day $hour:$minute';
  }
}