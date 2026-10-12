import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/features/translation/presentation/widgets/translated_text_widget.dart';
import '../data/chat_repository.dart';
import 'chat_list_screen.dart';

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
    unawaited(widget.repository.markIncomingRead(widget.conversation.id));
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
          final existing = _messages[existingIndex];
          final updatedReadAt = message.readAt ?? existing.readAt;
          _messages[existingIndex] = ChatMessage(
            id: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            body: message.body,
            createdAt: message.createdAt,
            readAt: updatedReadAt,
          );
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
          title: Text(context.l10n.clearChatTitle),
          content: Text(context.l10n.clearChatConfirmMessage),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.l10n.keepOffer)),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(context.l10n.clearChatButton)),
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
          SnackBar(content: Text(context.l10n.chatClearedSuccess)),
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.l10n.couldNotClearChat}: $error')),
          );
        }
      }
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.deleteChatTitle),
          content: Text(context.l10n.deleteChatConfirmMessage),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.l10n.keepOffer)),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.deleteChatButton),
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
            SnackBar(content: Text('${context.l10n.couldNotDeleteChat}: $error')),
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
            SnackBar(content: Text('${context.l10n.messageNotSent}: $error')));
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

  String _dayLabel(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final isToday = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (isToday) return context.l10n.today;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;
    if (isYesterday) return context.l10n.yesterday;
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

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ChatListScreen(
            repository: widget.repository,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
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
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.otherUserName),
            Text(context.l10n.kisanSetuChat, style: Theme.of(context).textTheme.labelSmall),
          ]),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: context.l10n.chatOptions,
              onSelected: _handleChatMenu,
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cleaning_services_outlined),
                      title: Text(context.l10n.clearChatButton),
                    )),
                PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_outline_rounded),
                      title: Text(context.l10n.deleteChatButton),
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
                                    Text(context.l10n.chatsNotAvailable),
                                    const SizedBox(height: 12),
                                    OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _loading = true;
                                            _error = null;
                                          });
                                          _load();
                                        },
                                        child: Text(context.l10n.retry)),
                                  ])))
                      : _messages.isEmpty
                          ? Center(
                              child: Text(context.l10n.sayHelloToStart))
                          : ListView.builder(
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
                                            TranslatedTextWidget(
                                              text: m.body,
                                              style: TextStyle(
                                                  color: mine
                                                      ? colors.onPrimaryContainer
                                                      : colors.onSurface),
                                              showToggle: !mine,
                                            ),
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
                            decoration: InputDecoration(
                                hintText: context.l10n.messageInputHint,
                                border: const OutlineInputBorder(),
                                counterText: ''),
                            onSubmitted: (_) => _send())),
                    const SizedBox(width: 8),
                    IconButton.filled(
                        onPressed: _sending ? null : _send,
                        tooltip: context.l10n.send,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send_rounded)),
                  ]))),
        ]),
      ),
    );
  }
}
