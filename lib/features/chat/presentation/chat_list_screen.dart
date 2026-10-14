import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/core/routing/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/chat_repository.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final ChatRepository repository;
  const ChatListScreen({super.key, required this.repository});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<ChatConversationSummary>> _conversations;
  RealtimeChannel? _channel;
  bool _searching = false;
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _conversations = widget.repository.listConversationSummaries();
    _channel = widget.repository.subscribeToConversationUpdates(() {
      if (mounted) _refresh();
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = widget.repository.listConversationSummaries();
    setState(() {
      _conversations = future;
    });
    await future;
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    final isToday = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;
    if (isToday) {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final period = local.hour < 12 ? 'AM' : 'PM';
      return '$hour:${local.minute.toString().padLeft(2, '0')} $period';
    }
    if (isYesterday) return context.l10n.yesterday;
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.farmerHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleBack();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: context.l10n.retry,
              onPressed: _handleBack,
            ),
            title: _searching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: context.l10n.searchChatsHint,
                      border: InputBorder.none,
                    ),
                    style: Theme.of(context).appBarTheme.titleTextStyle,
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                  )
                : Text(context.l10n.messagesTitle),
          actions: [
            IconButton(
              tooltip: context.l10n.notificationsTitle,
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push('/notifications'),
            ),
            IconButton(
              icon: Icon(_searching ? Icons.close : Icons.search),
              tooltip: _searching ? context.l10n.hideDetails : context.l10n.searchChatsHint,
              onPressed: () {
                setState(() {
                  _searching = !_searching;
                  if (!_searching) {
                    _query = '';
                    _searchController.clear();
                  }
                });
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<ChatConversationSummary>>(
            future: _conversations,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  children: const [
                    SizedBox(height: 180),
                    Center(child: CircularProgressIndicator()),
                  ],
                );
              }
              if (snapshot.hasError) {
                return ListView(
                  children: [
                    const SizedBox(height: 120),
                    const Icon(Icons.chat_bubble_outline, size: 44),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        context.l10n.chatsNotAvailable,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Center(
                      child: OutlinedButton(
                        onPressed: _refresh,
                        child: Text(context.l10n.retry),
                      ),
                    ),
                  ],
                );
              }
              final allItems = snapshot.data ?? [];
              final items = _query.isEmpty
                  ? allItems
                  : allItems
                      .where((c) =>
                          c.otherUserName.toLowerCase().contains(_query) ||
                          (c.lastMessage ?? '').toLowerCase().contains(_query))
                      .toList();

              if (allItems.isEmpty) {
                return ListView(
                  children: [
                    const SizedBox(height: 140),
                    const Icon(Icons.forum_outlined, size: 48),
                    const SizedBox(height: 12),
                    Center(child: Text(context.l10n.noConversationsYet)),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        context.l10n.contactFarmerSubtitle,
                      ),
                    ),
                  ],
                );
              }
              if (items.isEmpty) {
                return ListView(
                  children: [
                    const SizedBox(height: 140),
                    const Icon(Icons.search_off, size: 48),
                    const SizedBox(height: 12),
                    Center(child: Text(context.l10n.noChatsMatchSearch)),
                  ],
                );
              }

              final uid = widget.repository.currentUserId;
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final chat = items[index];
                  final hasUnread = chat.unreadCount > 0;
                  final isMine = chat.lastMessageSenderId != null &&
                      chat.lastMessageSenderId == uid;
                  final previewText = chat.lastMessage == null
                      ? context.l10n.sayHelloToStart
                      : (isMine
                          ? context.l10n.youPrefix(chat.lastMessage!)
                          : chat.lastMessage!);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: chat.otherUserAvatar != null &&
                              chat.otherUserAvatar!.isNotEmpty
                          ? CachedNetworkImageProvider(chat.otherUserAvatar!)
                          : null,
                      child: chat.otherUserAvatar == null ||
                              chat.otherUserAvatar!.isEmpty
                          ? Text(chat.otherUserName[0].toUpperCase())
                          : null,
                    ),
                    title: Text(
                      chat.otherUserName,
                      style: TextStyle(
                          fontWeight:
                              hasUnread ? FontWeight.bold : FontWeight.normal),
                    ),
                    subtitle: Text(
                      previewText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            hasUnread ? FontWeight.w600 : FontWeight.normal,
                        color: hasUnread
                            ? Theme.of(context).colorScheme.onSurface
                            : null,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTimestamp(chat.lastMessageAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                            fontWeight:
                                hasUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              chat.unreadCount > 99
                                  ? '99+'
                                  : chat.unreadCount.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      if (chat.unreadCount > 0) {
                        setState(() {
                          _conversations = _conversations.then((list) {
                            return list.map((c) {
                              if (c.conversationId == chat.conversationId) {
                                return ChatConversationSummary(
                                  conversationId: c.conversationId,
                                  farmerId: c.farmerId,
                                  buyerId: c.buyerId,
                                  produceId: c.produceId,
                                  otherUserId: c.otherUserId,
                                  otherUserName: c.otherUserName,
                                  otherUserRole: c.otherUserRole,
                                  otherUserAvatar: c.otherUserAvatar,
                                  otherUserDistrict: c.otherUserDistrict,
                                  lastMessage: c.lastMessage,
                                  lastMessageAt: c.lastMessageAt,
                                  lastMessageSenderId: c.lastMessageSenderId,
                                  unreadCount: 0,
                                );
                              }
                              return c;
                            }).toList();
                          });
                        });
                      }
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute<dynamic>(
                          builder: (_) => ChatScreen(
                            repository: widget.repository,
                            conversation: chat.toConversation(),
                            otherUserId: chat.otherUserId,
                            otherUserName: chat.otherUserName,
                          ),
                        ),
                      );
                      if (result == 'deleted') {
                        if (mounted) {
                          setState(() {
                            _conversations = _conversations.then((list) => list
                                .where((c) =>
                                    c.conversationId != chat.conversationId)
                                .toList());
                          });
                        }
                      } else {
                        _refresh();
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
