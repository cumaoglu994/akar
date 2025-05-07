import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final String sellerId;
  final String adId;

  const ChatScreen({
    super.key,
    required this.sellerId,
    required this.adId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final buyerId = user.id;
      final sellerId = widget.sellerId;
      
      // Create a unique chat ID by combining buyer and seller IDs
      final chatId = buyerId.compareTo(sellerId) < 0
          ? '$buyerId-$sellerId-${widget.adId}'
          : '$sellerId-$buyerId-${widget.adId}';
      
      // Check if chat exists, if not create it
      final response = await Supabase.instance.client
          .from('chats')
          .select()
          .eq('id', chatId)
          .single();
      
      if (response == null) {
        await Supabase.instance.client
            .from('chats')
            .insert({
              'id': chatId,
              'buyer_id': buyerId,
              'seller_id': sellerId,
              'ad_id': widget.adId,
              'last_message': '',
              'last_message_time': DateTime.now().toIso8601String(),
            });
      }

      setState(() {
        _chatId = chatId;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null) return;

    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final chatId = _chatId!;
      await Supabase.instance.client
          .from('messages')
          .insert({
            'chat_id': chatId,
            'sender_id': user.id,
            'message': _messageController.text.trim(),
            'timestamp': DateTime.now().toIso8601String(),
          });

      await Supabase.instance.client
          .from('chats')
          .update({
            'last_message': _messageController.text.trim(),
            'last_message_time': DateTime.now().toIso8601String(),
          })
          .eq('id', chatId);

      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (user == null || _chatId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final chatId = _chatId!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المحادثة'),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('messages')
                    .stream(primaryKey: ['id'])
                    .eq('chat_id', chatId)
                    .order('timestamp'),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data ?? [];

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message['sender_id'] == user.id;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.green[100] : Colors.blue[100],
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(message['message']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 