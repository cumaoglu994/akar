import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle_outlined, size: 70, color: Theme.of(context).primaryColor.withOpacity(0.7)),
              const SizedBox(height: 16),
              Text(
                'يرجى تسجيل الدخول',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to login screen - implement as needed
                },
                icon: const Icon(Icons.login),
                label: const Text('تسجيل الدخول'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
  appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 1,
  centerTitle: true,
  title: const Text(
    'المحادثات',
    style: TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black,
      fontSize: 20,
    ),
  ),

),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from(AppConstants.chatsTable)
            .stream(primaryKey: ['id'])
            .order('last_message_time', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(context, '${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          final chats = (snapshot.data ?? []).where((chat) =>
            chat['buyer_id'] == user.id || chat['seller_id'] == user.id
          ).toList();

          if (chats.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              // The stream will automatically update the UI
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chats.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 84,
                endIndent: 16,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                return _buildChatItem(context, chats[index], user.id);
              },
            ),
          );
        },
      ),
      
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat, String userId) {
    final isBuyer = chat['buyer_id'] == userId;
    final otherUserId = isBuyer ? chat['seller_id'] : chat['buyer_id'];
    final adId = chat['ad_id'];
    final hasUnreadMessages = chat['unread_count'] != null && chat['unread_count'] > 0;

    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        Supabase.instance.client
            .from(AppConstants.usersTable)
            .select()
            .eq('id', otherUserId)
            .maybeSingle(),
        Supabase.instance.client
            .from(AppConstants.adsTable)
            .select()
            .eq('id', adId)
            .maybeSingle(),
      ]).then((results) => {
        'user': results[0],
        'ad': results[1],
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildChatItemSkeleton();
        }
        
        if (snapshot.hasError || !snapshot.hasData || 
            snapshot.data!['user'] == null || snapshot.data!['ad'] == null) {
          return _buildInvalidChatItem();
        }

        final otherUser = snapshot.data!['user'];
        final ad = snapshot.data!['ad'];
        final lastMessageTime = chat['last_message_time'] != null
            ? DateTime.parse(chat['last_message_time'])
            : null;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  sellerId: otherUserId,
                  adId: chat['ad_id'],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: otherUser['profile_image'] != null
                          ? Image.network(
                              otherUser['profile_image'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, size: 40, color: Colors.grey),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.person, size: 40, color: Colors.grey),
                            ),
                      ),
                    ),
                    if (hasUnreadMessages)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '${chat['unread_count']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              otherUser['name'] ?? 'مستخدم',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastMessageTime != null)
                            Text(
                              _formatTime(lastMessageTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: hasUnreadMessages
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                                fontWeight: hasUnreadMessages
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ad['title'] ?? 'إعلان',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isBuyer)
                            Icon(
                              Icons.reply,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                          if (isBuyer) const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              chat['last_message'] ?? 'لا توجد رسائل',
                              style: TextStyle(
                                fontSize: 14,
                                color: hasUnreadMessages
                                    ? Colors.black87
                                    : Colors.grey[600],
                                fontWeight: hasUnreadMessages
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatItemSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      color: Colors.grey.shade300,
                    ),
                    Container(
                      width: 40,
                      height: 12,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 14,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidChatItem() {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: const Icon(Icons.error_outline, color: Colors.grey),
      ),
      title: const Text('معلومات غير متوفرة'),
      subtitle: const Text('لا يمكن تحميل بيانات المحادثة'),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل المحادثات...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Implement refresh functionality
            },
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 70,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد محادثات',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'ابدأ محادثة جديدة مع البائعين أو المشترين',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to new chat/ads list
            },
            icon: const Icon(Icons.add),
            label: const Text('بدء محادثة جديدة'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hour = date.hour.toString();
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'بالأمس';
    } else if (difference.inDays < 7) {
      return 'قبل ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}