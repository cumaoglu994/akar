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
  
  // Chat state
  String? _chatId;
  bool _isInitialized = false;
  String? _error;
  String? _sellerName;
  bool _isTyping = false;
  late final ValueNotifier<bool> _sendButtonEnabled = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _loadSellerInfo();
    
    // Monitor text field for enabling/disabling send button
    _messageController.addListener(_updateSendButtonState);
  }

  void _updateSendButtonState() {
    _sendButtonEnabled.value = _messageController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sendButtonEnabled.dispose();
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

      // Create consistent chat ID regardless of who started the chat
      final chatId = buyerId.compareTo(sellerId) < 0
          ? '$buyerId-$sellerId-${widget.adId}'
          : '$sellerId-$buyerId-${widget.adId}';

      final response = await Supabase.instance.client
          .from(AppConstants.chatsTable)
          .select()
          .eq('id', chatId)
          .maybeSingle();

      // Create chat if it doesn't exist
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
        // Add message to messages table
        await Supabase.instance.client
            .from(AppConstants.messagesTable)
            .insert({
          'chat_id': chatId,
          'sender_id': supabaseUser.id,
          'message': messageText,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Update chat with last message info
        await Supabase.instance.client
            .from(AppConstants.chatsTable)
            .update({
          'last_message': messageText,
          'last_message_time': DateTime.now().toIso8601String(),
        }).eq('id', chatId);

        _scrollToBottom();
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error sending message: ${e.toString()}');
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
      ),
    );
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
        body: SafeArea(
          child: Container(
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
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثة'),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'حدث خطأ: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثة'),
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل المحادثة...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      elevation: 1,
      title: Row(
        children: [
          Hero(
            tag: 'seller-${widget.sellerId}',
            child: CircleAvatar(
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sellerName ?? 'المحادثة',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'متصل الآن',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'تفاصيل الإعلان',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تفاصيل الإعلان'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'block':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حظر المستخدم')),
                );
                break;
              case 'report':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم الإبلاغ عن المستخدم')),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, size: 20),
                  SizedBox(width: 8),
                  Text('حظر المستخدم'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag, size: 20),
                  SizedBox(width: 8),
                  Text('الإبلاغ عن محتوى'),
                ],
              ),
            ),
          ],
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
          color: theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          DateFormat('y MMMM d', 'ar').format(date),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
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
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  'خطأ في تحميل الرسائل',
                  style: TextStyle(fontSize: 16),
                ),
                TextButton(
                  onPressed: () => setState(() {}), // Simple refresh
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data ?? [];
        
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'ابدأ المحادثة الآن',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Scroll to bottom whenever messages change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        DateTime? previousDate;
        
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMine = message['sender_id'] == supabaseUser.id;
            final messageTimestamp = DateTime.parse(message['timestamp']);
            
            // Check if we need to show a date header
            Widget? dateHeader;
            if (previousDate == null || !_isSameDay(previousDate!, messageTimestamp)) {
              dateHeader = _buildInlineDate(messageTimestamp);
              previousDate = messageTimestamp;
            }
            
            return Column(
              children: [
                if (dateHeader != null) dateHeader,
                _buildMessageBubble(message, isMine, messageTimestamp),
              ],
            );
          },
        );
      },
    );
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  Widget _buildInlineDate(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              DateFormat('d MMMM', 'ar').format(date),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMine, DateTime timestamp) {
    final theme = Theme.of(context);
    
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Card(
          color: isMine 
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isMine
                ? BorderSide.none
                : BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  message['message'],
                  style: TextStyle(
                    color: isMine ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 6, left: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm', 'ar').format(timestamp),
                      style: TextStyle(
                        color: isMine 
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        size: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 5,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              color: theme.colorScheme.primary,
              onPressed: () {
                // Attachment functionality would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ميزة الملفات المرفقة قيد التطوير'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 16),
                  ),
                  style: const TextStyle(fontSize: 16),
                  textAlignVertical: TextAlignVertical.center,
                  onChanged: (text) {
                    setState(() {
                      _isTyping = text.trim().isNotEmpty;
                    });
                  },
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<bool>(
              valueListenable: _sendButtonEnabled,
              builder: (context, enabled, _) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: enabled 
                        ? theme.colorScheme.primary 
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send),
                    color: enabled ? Colors.white : Colors.grey[500],
                    onPressed: enabled ? _sendMessage : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'يكتب الآن',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 8),
              _buildPulsingDots(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPulsingDots() {
    return Row(
      children: List.generate(
        3,
        (index) => _buildPulsingDot(
          delay: Duration(milliseconds: 300 * index),
        ),
      ),
    );
  }
  
  Widget _buildPulsingDot({required Duration delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 6 + (value * 2),
          width: 6 + (value * 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.6 - (value * 0.3)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}