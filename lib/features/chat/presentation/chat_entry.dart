import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/chat_repository.dart';
import 'chat_screen.dart';

class ChatEntryButton extends StatefulWidget {
  final String farmerId, buyerId, otherUserName;
  final String? produceId;
  final bool iconOnly;
  const ChatEntryButton({super.key, required this.farmerId, required this.buyerId, required this.otherUserName, this.produceId, this.iconOnly = false});
  @override
  State<ChatEntryButton> createState() => _ChatEntryButtonState();
}

class _ChatEntryButtonState extends State<ChatEntryButton> {
  bool _loading = false;

  Future<void> _openChat() async {
    if (_loading) return;
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to chat.'))); return; }
    if (uid != widget.farmerId && uid != widget.buyerId) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only the farmer and buyer can open this chat.'))); return; }
    setState(() => _loading = true);
    try {
      final repo = ChatRepository(client);
      final conversation = await repo.startConversation(farmerId: widget.farmerId, buyerId: widget.buyerId, produceId: widget.produceId);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(
        repository: repo, conversation: conversation,
        otherUserId: uid == widget.farmerId ? widget.buyerId : widget.farmerId,
        otherUserName: widget.otherUserName,
      )));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open chat: $error')));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.iconOnly) return IconButton(tooltip: 'Chat with ${widget.otherUserName}', onPressed: _loading ? null : _openChat,
      icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chat_bubble_outline));
    return OutlinedButton.icon(onPressed: _loading ? null : _openChat,
      icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chat_bubble_outline),
      label: const Text('Chat with farmer'));
  }
}
