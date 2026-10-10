import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/chat_repository.dart';

class ChatScreen extends StatefulWidget {
  final ChatRepository repository;
  final ChatConversation conversation;
  final String otherUserId;
  final String otherUserName;
  const ChatScreen({super.key, required this.repository, required this.conversation, required this.otherUserId, required this.otherUserName});
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
  String? get _userId => widget.repository.currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = widget.repository.subscribeToMessages(widget.conversation.id, (message) {
      if (!mounted) return;
      final existingIndex = _messages.indexWhere((m) => m.id == message.id);
      if (existingIndex >= 0) {
        setState(() => _messages[existingIndex] = message);
        return;
      }
      setState(() => _messages.add(message));
      _scrollToBottom();
      if (message.senderId != _userId) {
        unawaited(widget.repository.markIncomingRead(widget.conversation.id));
      }
    });
  }

  Future<void> _load() async {
    try {
      final messages = await widget.repository.loadMessages(widget.conversation.id);
      if (!mounted) return;
      setState(() { _messages..clear()..addAll(messages); _loading = false; _error = null; });
      await widget.repository.markIncomingRead(widget.conversation.id);
      _scrollToBottom();
    } catch (error) {
      if (mounted) setState(() { _loading = false; _error = error.toString(); });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final body = _textController.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.repository.sendMessage(widget.conversation.id, body);
      _textController.clear();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message could not be sent: $error')));
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.otherUserName),
        Text('KisanSetu chat', style: Theme.of(context).textTheme.labelSmall),
      ])),
      body: Column(children: [
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off_outlined, size: 38),
                const SizedBox(height: 12),
                const Text('Could not load messages. Check your connection and the chat database migration.'),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: () { setState(() { _loading = true; _error = null; }); _load(); }, child: const Text('Retry')),
              ])))
            : _messages.isEmpty
              ? const Center(child: Text('Say hello to start the conversation.'))
              : ListView.builder(controller: _scrollController, padding: const EdgeInsets.all(16), itemCount: _messages.length, itemBuilder: (context, index) {
                  final m = _messages[index];
                  final mine = m.senderId == _userId;
                  return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
                    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: mine ? colors.primaryContainer : colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(m.body, style: TextStyle(color: mine ? colors.onPrimaryContainer : colors.onSurface)),
                      const SizedBox(height: 4),
                      Text('${m.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${m.createdAt.toLocal().minute.toString().padLeft(2, '0')}${mine && m.readAt != null ? '  ✓✓' : ''}', style: Theme.of(context).textTheme.labelSmall),
                    ]),
                  ));
                })),
        SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: TextField(controller: _textController, minLines: 1, maxLines: 5, maxLength: 4000, textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Message farmer or buyer...', border: OutlineInputBorder(), counterText: ''), onSubmitted: (_) => _send())),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: _sending ? null : _send, tooltip: 'Send message', icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded)),
        ]))),
      ]),
    );
  }
}
