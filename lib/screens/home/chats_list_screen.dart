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
      return const Center(child: Text('يرجى تسجيل الدخول'));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from(AppConstants.chatsTable)
          .stream(primaryKey: ['id'])
          .eq('buyer_id', user.id)
          .order('last_message_time', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data ?? [];

        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 50, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'لا توجد محادثات',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // The stream will automatically update the UI
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final isBuyer = chat['buyer_id'] == user.id;
              final otherUserId = isBuyer ? chat['seller_id'] : chat['buyer_id'];

              return FutureBuilder<Map<String, dynamic>>(
                future: Supabase.instance.client
                    .from(AppConstants.usersTable)
                    .select()
                    .eq('id', otherUserId)
                    .single(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('جاري التحميل...'),
                    );
                  }

                  final otherUser = userSnapshot.data!;
                  final lastMessageTime = chat['last_message_time'] != null
                      ? DateTime.parse(chat['last_message_time'])
                      : null;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: otherUser['profile_image'] != null
                          ? NetworkImage(otherUser['profile_image'])
                          : null,
                      child: otherUser['profile_image'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(otherUser['name'] ?? 'مستخدم'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat['last_message'] ?? 'لا توجد رسائل',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (lastMessageTime != null)
                          Text(
                            _formatTime(lastMessageTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
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
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'بالأمس';
    } else if (difference.inDays < 7) {
      return 'قبل ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 