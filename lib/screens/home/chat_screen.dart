import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart' hide TextDirection;

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
  bool _isInitialized = false;
  String? _error;
  String? _sellerName;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _loadSellerInfo();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSellerInfo() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', widget.sellerId)
          .single();

      if (mounted && response != null) {
        setState(() {
          _sellerName = response['name'] ?? 'Satıcı';
        });
      }
    } catch (e) {
      debugPrint('Seller info loading error: $e');
      if (mounted) {
        setState(() {
          _sellerName = 'Satıcı';
        });
      }
    }
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;

    try {
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      if (supabaseUser == null) throw Exception('User not authenticated');

      final buyerId = supabaseUser.id;
      final sellerId = widget.sellerId;

      final chatId = buyerId.compareTo(sellerId) < 0
          ? '$buyerId-$sellerId-${widget.adId}'
          : '$sellerId-$buyerId-${widget.adId}';

      final response = await Supabase.instance.client
          .from(AppConstants.chatsTable)
          .select()
          .eq('id', chatId)
          .maybeSingle();

      if (response == null) {
        await Supabase.instance.client
            .from(AppConstants.chatsTable)
            .insert({
          'id': chatId,
          'buyer_id': buyerId,
          'seller_id': sellerId,
          'ad_id': widget.adId,
          'last_message': '',
          'last_message_time': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        setState(() {
          _chatId = chatId;
          _isInitialized = true;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatId == null) return;

    setState(() {
      _isTyping = false;
    });

    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser != null) {
      final messageText = _messageController.text.trim();
      _messageController.clear();

      final chatId = _chatId!;

      try {
        await Supabase.instance.client
            .from(AppConstants.messagesTable)
            .insert({
          'chat_id': chatId,
          'sender_id': supabaseUser.id,
          'message': messageText,
          'timestamp': DateTime.now().toIso8601String(),
        });

        await Supabase.instance.client
            .from(AppConstants.chatsTable)
            .update({
          'last_message': messageText,
          'last_message_time': DateTime.now().toIso8601String(),
        }).eq('id', chatId);

        _scrollToBottom();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending message: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _buildErrorScreen();

    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser == null || _chatId == null) return _buildLoadingScreen();

    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(theme),
        body: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            image: DecorationImage(
              image: const AssetImage('assets/images/chat_background.png'),
              fit: BoxFit.cover,
              opacity: 0.05,
              colorFilter: ColorFilter.mode(
                theme.colorScheme.primary.withOpacity(0.1),
                BlendMode.lighten,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildDateHeader(theme, DateTime.now()),
              Expanded(
                child: _buildMessagesList(_chatId!, supabaseUser),
              ),
              if (_isTyping) _buildTypingIndicator(theme),
              _buildMessageInput(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('المحادثة')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text('حدث خطأ: $_error', textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isInitialized = false;
                  _error = null;
                });
                _initializeChat();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('المحادثة')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            child: Text(
              _sellerName?.isNotEmpty == true
                  ? _sellerName![0].toUpperCase()
                  : 'S',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sellerName ?? 'المحادثة',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'متصل الآن',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimary.withOpacity(0.8)),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تفاصيل الإعلان'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateHeader(ThemeData theme, DateTime date) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          DateFormat('y MMMM d', 'ar').format(date),
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
      ),
    );
  }

  Widget _buildMessagesList(String chatId, User supabaseUser) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from(AppConstants.messagesTable)
          .stream(primaryKey: ['id'])
          .eq('chat_id', chatId)
          .order('timestamp', ascending: true),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('خطأ في تحميل الرسائل'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final messages = snapshot.data ?? [];

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMine = message['sender_id'] == supabaseUser.id;
            return Align(
              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMine ? Colors.blueAccent.withOpacity(0.8) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message['message'],
                  style: TextStyle(color: isMine ? Colors.white : Colors.black),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'اكتب رسالتك...',
                border: InputBorder.none,
              ),
              onChanged: (text) {
                setState(() {
                  _isTyping = text.trim().isNotEmpty;
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: theme.colorScheme.primary,
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '...يكتب الآن',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
