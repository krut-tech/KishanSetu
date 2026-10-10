import 'package:supabase_flutter/supabase_flutter.dart';

class ChatConversation {
  final String id;
  final String farmerId;
  final String buyerId;
  final String? produceId;
  final DateTime createdAt;

  const ChatConversation({
    required this.id,
    required this.farmerId,
    required this.buyerId,
    required this.produceId,
    required this.createdAt,
  });

  factory ChatConversation.fromMap(Map<String, dynamic> map) => ChatConversation(
        id: map['id'] as String,
        farmerId: map['farmer_id'] as String,
        buyerId: map['buyer_id'] as String,
        produceId: map['produce_id'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// A conversation enriched with the other participant's profile and a
/// preview of the last message, as returned by `list_my_chat_conversations`.
/// This is what powers the WhatsApp-style chat list (last message, time,
/// unread badge) without doing one extra query per row.
class ChatConversationSummary {
  final String conversationId;
  final String farmerId;
  final String buyerId;
  final String? produceId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserRole;
  final String? otherUserAvatar;
  final String? otherUserDistrict;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final int unreadCount;

  const ChatConversationSummary({
    required this.conversationId,
    required this.farmerId,
    required this.buyerId,
    required this.produceId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    required this.otherUserAvatar,
    required this.otherUserDistrict,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageSenderId,
    required this.unreadCount,
  });

  ChatConversation toConversation() => ChatConversation(
        id: conversationId,
        farmerId: farmerId,
        buyerId: buyerId,
        produceId: produceId,
        createdAt: lastMessageAt ?? DateTime.now(),
      );

  factory ChatConversationSummary.fromMap(Map<String, dynamic> map) => ChatConversationSummary(
        conversationId: map['conversation_id'] as String,
        farmerId: map['farmer_id'] as String,
        buyerId: map['buyer_id'] as String,
        produceId: map['produce_id'] as String?,
        otherUserId: map['other_user_id'] as String,
        otherUserName: (map['other_user_name'] as String?)?.trim().isNotEmpty == true
            ? (map['other_user_name'] as String).trim()
            : 'KisanSetu user',
        otherUserRole: map['other_user_role'] as String?,
        otherUserAvatar: map['other_user_avatar'] as String?,
        otherUserDistrict: map['other_user_district'] as String?,
        lastMessage: map['last_message'] as String?,
        lastMessageAt: map['last_message_at'] == null ? null : DateTime.parse(map['last_message_at'] as String),
        lastMessageSenderId: map['last_message_sender_id'] as String?,
        unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
      );
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    required this.readAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] as String,
        conversationId: map['conversation_id'] as String,
        senderId: map['sender_id'] as String,
        body: map['body'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        readAt: map['read_at'] == null ? null : DateTime.parse(map['read_at'] as String),
      );
}

class ChatRepository {
  final SupabaseClient _client;
  ChatRepository(this._client);

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<ChatConversation> startConversation({
    required String farmerId,
    required String buyerId,
    String? produceId,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw const AuthException('Please sign in to start a chat.');
    if (uid != buyerId && uid != farmerId) {
      throw const AuthException('You are not a participant in this conversation.');
    }

    // Create-or-reuse is atomic and safe against two participants tapping at
    // once. The conversation identity is the farmer/buyer pair only (not the
    // produce item), so opening chat from a different listing with the same
    // person reuses the same thread instead of creating a duplicate one.
    try {
      final row = await _client.rpc('get_or_create_chat_conversation', params: {
        'p_farmer_id': farmerId,
        'p_buyer_id': buyerId,
        'p_produce_id': produceId,
      });
      return ChatConversation.fromMap(Map<String, dynamic>.from(row as Map));
    } on PostgrestException catch (error) {
      if (error.code != 'PGRST202' && error.code != '42883') rethrow;
      // Compatible fallback while the new migration/RPC has not been applied.
      final existingRows = await _client.from('chat_conversations').select()
          .eq('farmer_id', farmerId).eq('buyer_id', buyerId);
      final matches = (existingRows as List).cast<Map<String, dynamic>>();
      if (matches.isNotEmpty) return ChatConversation.fromMap(matches.first);
      final created = await _client.from('chat_conversations').insert({
        'farmer_id': farmerId,
        'buyer_id': buyerId,
        'produce_id': produceId,
      }).select().single();
      return ChatConversation.fromMap(created);
    }
  }

  /// Chat list rows, each already carrying the other participant's profile
  /// and a last-message preview, ordered oldest activity first (ascending).
  Future<List<ChatConversationSummary>> listConversationSummaries() async {
    final uid = currentUserId;
    if (uid == null) throw const AuthException('Please sign in to view chats.');
    try {
      final rows = await _client.rpc('list_my_chat_conversations');
      return (rows as List)
          .map((row) => ChatConversationSummary.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    } on PostgrestException catch (error) {
      if (error.code != 'PGRST202' && error.code != '42883') rethrow;
      // Compatible fallback while the new migration/RPC has not been applied.
      final conversations = await listConversations();
      final summaries = <ChatConversationSummary>[];
      for (final conversation in conversations) {
        final otherId = uid == conversation.farmerId ? conversation.buyerId : conversation.farmerId;
        final other = await getOtherParticipant(otherId);
        summaries.add(ChatConversationSummary(
          conversationId: conversation.id,
          farmerId: conversation.farmerId,
          buyerId: conversation.buyerId,
          produceId: conversation.produceId,
          otherUserId: otherId,
          otherUserName: (other?['full_name'] as String?)?.trim().isNotEmpty == true
              ? (other!['full_name'] as String).trim()
              : 'KisanSetu user',
          otherUserRole: other?['role'] as String?,
          otherUserAvatar: other?['avatar_url'] as String?,
          otherUserDistrict: other?['district'] as String?,
          lastMessage: null,
          lastMessageAt: null,
          lastMessageSenderId: null,
          unreadCount: 0,
        ));
      }
      return summaries;
    }
  }

  /// Oldest-conversation-first, per the in-app ordering preference.
  Future<List<ChatConversation>> listConversations() async {
    final uid = currentUserId;
    if (uid == null) throw const AuthException('Please sign in to view chats.');
    final rows = await _client.from('chat_conversations').select()
        .or('farmer_id.eq.$uid,buyer_id.eq.$uid').order('updated_at', ascending: true);
    return (rows as List).map((row) => ChatConversation.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessage>> loadMessages(String conversationId) async {
    final rows = await _client.from('chat_messages').select()
        .eq('conversation_id', conversationId).order('created_at');
    return (rows as List).map((row) => ChatMessage.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<void> sendMessage(String conversationId, String body) async {
    final uid = currentUserId;
    final message = body.trim();
    if (uid == null) throw const AuthException('Please sign in to send messages.');
    if (message.isEmpty) return;
    if (message.length > 4000) throw const FormatException('Message must be 4000 characters or fewer.');
    await _client.from('chat_messages').insert({
      'conversation_id': conversationId, 'sender_id': uid, 'body': message,
    });
  }

  Future<void> markIncomingRead(String conversationId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('chat_messages').update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('conversation_id', conversationId).neq('sender_id', uid).isFilter('read_at', null);
  }

  RealtimeChannel subscribeToMessages(String conversationId, void Function(ChatMessage) onMessage) {
    return _client.channel('chat-messages-$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: conversationId),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isNotEmpty) onMessage(ChatMessage.fromMap(row));
          },
        ).subscribe();
  }

  /// Live updates for the chat list itself: fires whenever any message in
  /// any of the current user's conversations changes, so the list (last
  /// message preview, ordering, unread badge) stays in sync immediately.
  RealtimeChannel subscribeToConversationUpdates(void Function() onChanged) {
    final uid = currentUserId ?? 'anon';
    return _client.channel('chat-list-$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (_) => onChanged(),
        ).subscribe();
  }

  Future<Map<String, dynamic>?> getOtherParticipant(String id) async {
    return await _client.from('profiles')
        .select('id,full_name,role,avatar_url,phone,district,village,state,latitude,longitude')
        .eq('id', id).maybeSingle();
  }
}
