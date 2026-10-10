import 'package:flutter/material.dart';
import '../data/chat_repository.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final ChatRepository repository;
  const ChatListScreen({super.key, required this.repository});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<ChatConversation>> _conversations;

  @override
  void initState() {
    super.initState();
    _conversations = widget.repository.listConversations();
  }

  Future<void> _refresh() async {
    setState(() => _conversations = widget.repository.listConversations());
    await _conversations;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<ChatConversation>>(
            future: _conversations,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  children: [
                    const SizedBox(height: 180),
                    const Center(child: CircularProgressIndicator()),
                  ],
                );
              }
              if (snapshot.hasError) {
                return ListView(
                  children: [
                    const SizedBox(height: 120),
                    const Icon(Icons.chat_bubble_outline, size: 44),
                    const Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Chats are not available yet. Check the chat database migration and connection.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Center(
                      child: OutlinedButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 140),
                    Icon(Icons.forum_outlined, size: 48),
                    SizedBox(height: 12),
                    Center(child: Text('No conversations yet')),
                    SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Open a produce listing and contact its farmer.',
                      ),
                    ),
                  ],
                );
              }
              final uid = widget.repository.currentUserId;
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final chat = items[index];
                  final otherId =
                      uid == chat.farmerId ? chat.buyerId : chat.farmerId;
                  return FutureBuilder<Map<String, dynamic>?>(
                    future: widget.repository.getOtherParticipant(otherId),
                    builder: (context, userSnapshot) {
                      final user = userSnapshot.data;
                      final name = (user?['full_name'] as String?)?.trim();
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (name == null || name.isEmpty ? '?' : name[0])
                                .toUpperCase(),
                          ),
                        ),
                        title: Text(
                          name == null || name.isEmpty
                              ? 'KisanSetu user'
                              : name,
                        ),
                        subtitle: Text(
                          user?['district'] as String? ?? 'Farmer / buyer',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: user == null
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ChatScreen(
                                      repository: widget.repository,
                                      conversation: chat,
                                      otherUserId: otherId,
                                      otherUserName: name ?? 'KisanSetu user',
                                    ),
                                  ),
                                ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      );
}
