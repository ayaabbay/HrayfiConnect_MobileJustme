import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../services/chat_service.dart';
import '../../services/api_service.dart';
import '../chat/chat_detail_page.dart';

class ClientChatListPage extends StatefulWidget {
  const ClientChatListPage({super.key});

  @override
  State<ClientChatListPage> createState() => _ClientChatListPageState();
}

class _ClientChatListPageState extends State<ClientChatListPage> {
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final conversations = await ChatService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
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
                        onPressed: _loadConversations,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune conversation',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _conversations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          final otherUser = conversation.otherUser;
                          final lastMessage = conversation.lastMessage;
                          
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: conversation.otherUserAvatar != null
                                    ? NetworkImage(conversation.otherUserAvatar!)
                                    : null,
                                child: conversation.otherUserAvatar == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(conversation.otherUserName),
                              subtitle: Text(
                                lastMessage?['content'] ?? 'Aucun message',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (lastMessage != null)
                                    Text(
                                      _formatTimestamp(lastMessage['created_at'] != null
                                          ? DateTime.parse(lastMessage['created_at'])
                                          : null),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  if (conversation.unreadCount > 0) ...[
                                    const SizedBox(height: 4),
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.indigo,
                                      child: Text(
                                        conversation.unreadCount.toString(),
                                        style: const TextStyle(fontSize: 12, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailPage(
                                      bookingId: conversation.bookingId,
                                      otherUserName: conversation.otherUserName,
                                      otherUserAvatar: conversation.otherUserAvatar,
                                    ),
                                  ),
                                ).then((_) => _loadConversations());
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}


