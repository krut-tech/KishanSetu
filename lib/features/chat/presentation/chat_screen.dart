import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/chat_repository.dart';

class ChatScreen extends StatefulWidget {
  final ChatRepository repository;
  final ChatConversation conversation;
  final String otherUserId;
  final String otherUserName;
  const ChatScreen(
      {super.key,
      required this.repository,
      required this.conversation,
      required this.otherUserId,
      required this.otherUserName});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  RealtimeChannel? _channel;
  bool _loading = true, _sending = false;
  String? _error;
  DateTime? _clearedAt;
  String? get _userId => widget.repository.currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = widget.repository.subscribeToMessages(widget.conversation.id,
        (message) {
      if (!mounted) return;
      if (_clearedAt != null &&
          message.createdAt.toUtc().isBefore(_clearedAt!)) {
        return;
      }
      final existingIndex = _messages.indexWhere((m) => m.id == message.id);
      if (existingIndex >= 0) {
        setState(() {
          _messages[existingIndex] = message;
          _sortMessages();
        });
        return;
      }
      setState(() {
        _messages.add(message);
        _sortMessages();
      });
      if (message.senderId != _userId) {
        unawaited(widget.repository.markIncomingRead(widget.conversation.id));
      }
    });
  }

  Future<void> _load() async {
    try {
      final messages =
          await widget.repository.loadMessages(widget.conversation.id);
      if (!mounted) return;
      setState(() {
        // Merge the initial query with realtime events received while it was
        // in flight. Clearing and replacing the list here could drop messages.
        final byId = <String, ChatMessage>{
          for (final message in _messages) message.id: message,
          for (final message in messages) message.id: message,
        };
        _messages
          ..clear()
          ..addAll(byId.values);
        _sortMessages();
        _loading = false;
        _error = null;
      });
      await widget.repository.markIncomingRead(widget.conversation.id);
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  void _sortMessages() {
    _messages.sort((a, b) {
      final byTime = a.createdAt.toUtc().compareTo(b.createdAt.toUtc());
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  }

  Future<void> _handleChatMenu(String action) async {
    if (action == 'clear') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Clear this chat?'),
          content: const Text(
              'Messages will be cleared only for you. The other person will still have their chat history.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Clear chat')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      try {
        final clearedAt =
            await widget.repository.clearChatForMe(widget.conversation.id);
        if (!mounted) return;
        setState(() {
          _messages.clear();
          _clearedAt = clearedAt;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat cleared for you')),
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not clear chat: $error')),
          );
        }
      }
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete this chat?'),
          content: const Text(
              'This removes the conversation from your chat list only. The other person keeps their messages.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete chat'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      try {
        await widget.repository.deleteChatForMe(widget.conversation.id);
        if (mounted) Navigator.of(context).pop('deleted');
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete chat: $error')),
          );
        }
      }
    }
  }

  Future<void> _send() async {
    final body = _textController.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.repository.sendMessage(widget.conversation.id, body);
      _textController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Message could not be sent: $error')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// WhatsApp-style day label ("Today" / "Yesterday" / date) shown once per
  /// day between messages.
  String _dayLabel(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final isToday = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (isToday) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;
    if (isYesterday) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  bool _isNewDay(int index) {
    if (index == 0) return true;
    final prev = _messages[index - 1].createdAt.toLocal();
    final curr = _messages[index].createdAt.toLocal();
    return prev.year != curr.year ||
        prev.month != curr.month ||
        prev.day != curr.day;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.otherUserName),
          Text('KisanSetu chat', style: Theme.of(context).textTheme.labelSmall),
        ]),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Chat options',
            onSelected: _handleChatMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(
                  value: 'clear',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.cleaning_services_outlined),
                    title: Text('Clear chat'),
                  )),
              PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline_rounded),
                    title: Text('Delete chat'),
                  )),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wifi_off_outlined, size: 38),
                                  const SizedBox(height: 12),
                                  const Text(
                                      'Could not load messages. Check your connection and the chat database migration.'),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _loading = true;
                                          _error = null;
                                        });
                                        _load();
                                      },
                                      child: const Text('Retry')),
                                ])))
                    : _messages.isEmpty
                        ? const Center(
                            child: Text('Say hello to start the conversation.'))
                        : ListView.builder(
                            // Keep chronological chat layout explicit: oldest at top,
                            // newest at bottom. This avoids a reversed list rendering
                            // the newest messages above older history.
                            reverse: true,
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final reversedIndex =
                                  _messages.length - 1 - index;
                              final m = _messages[reversedIndex];
                              final mine = m.senderId == _userId;
                              final bubble = Align(
                                  alignment: mine
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.sizeOf(context).width *
                                                .78),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                        color: mine
                                            ? colors.primaryContainer
                                            : colors.surfaceContainerHighest,
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(m.body,
                                              style: TextStyle(
                                                  color: mine
                                                      ? colors
                                                          .onPrimaryContainer
                                                      : colors.onSurface)),
                                          const SizedBox(height: 4),
                                          Text(
                                              '${m.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${m.createdAt.toLocal().minute.toString().padLeft(2, '0')}${mine && m.readAt != null ? '  ✓✓' : ''}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall),
                                        ]),
                                  ));

                              if (!_isNewDay(reversedIndex)) return bubble;

                              return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Center(
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                            color:
                                                colors.surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Text(_dayLabel(m.createdAt),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall),
                                      ),
                                    ),
                                    bubble,
                                  ]);
                            })),
        SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child:
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                      child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 5,
                          maxLength: 4000,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                              hintText: 'Message farmer or buyer...',
                              border: OutlineInputBorder(),
                              counterText: ''),
                          onSubmitted: (_) => _send())),
                  const SizedBox(width: 8),
                  IconButton.filled(
                      onPressed: _sending ? null : _send,
                      tooltip: 'Send message',
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded)),
                ]))),
      ]),
    );
  }
}
