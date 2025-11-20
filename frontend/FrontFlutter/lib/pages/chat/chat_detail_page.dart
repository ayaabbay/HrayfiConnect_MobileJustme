import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../models/booking.dart';
import '../../services/chat_service.dart';
import '../../services/booking_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import 'dart:async';

class ChatDetailPage extends StatefulWidget {
  final String bookingId;
  final String otherUserName;
  final String? otherUserAvatar;
  
  const ChatDetailPage({
    super.key,
    required this.bookingId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markAsRead();
    // Rafraîchir les messages toutes les 5 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await ChatService.getMessages(widget.bookingId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
          _error = null;
        });
        // Scroll vers le bas si nouveau message
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead() async {
    try {
      await ChatService.markAsRead(widget.bookingId);
    } catch (e) {
      // Ignorer les erreurs de marquage comme lu
    }
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      final userInfo = await StorageService.getUserInfo();
      final userId = userInfo['userId']!;
      final userType = userInfo['userType'] ?? 'client';
      
      // Déterminer le receiver_id depuis le booking
      final bookings = await BookingService.getMyBookings();
      final booking = bookings.firstWhere(
        (b) => b.id == widget.bookingId,
        orElse: () => throw Exception('Réservation non trouvée'),
      );
      
      final receiverId = userType == 'client' ? booking.artisanId : booking.clientId;
      
      // Envoyer le message via REST
      await ChatService.sendMessage(
        bookingId: widget.bookingId,
        receiverId: receiverId,
        content: content,
        senderType: userType,
        senderId: userId,
      );

      if (mounted) {
        _controller.clear();
        // Recharger les messages immédiatement
        await _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de l\'envoi';
        if (e is ApiException) {
          errorMessage = e.message;
        } else {
          errorMessage = e.toString();
        }
        setState(() {
          _error = errorMessage;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<bool> _isMyMessage(Message message) async {
    final userInfo = await StorageService.getUserInfo();
    final userId = userInfo['userId'];
    final userType = userInfo['userType'];
    return message.senderId == userId && message.senderType == userType;
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.otherUserAvatar != null)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(widget.otherUserAvatar!),
              )
            else
              const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 16),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.otherUserName),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red.shade700),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadMessages,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun message',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Commencez la conversation',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadMessages,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                reverse: true,
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[_messages.length - 1 - index];
                                  return FutureBuilder<bool>(
                                    future: _isMyMessage(message),
                                    builder: (context, snapshot) {
                                      final isMine = snapshot.data ?? false;
                                      return Align(
                                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 4),
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                                          ),
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: isMine ? Colors.indigo : Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    message.content,
                                                    style: TextStyle(color: isMine ? Colors.white : Colors.black87),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatTime(message.createdAt),
                                                    style: TextStyle(
                                                      color: isMine ? Colors.white70 : Colors.grey.shade600,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                enabled: !_isSending,
                                decoration: InputDecoration(
                                  hintText: 'Écrire un message',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _isSending ? null : _sendMessage,
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}