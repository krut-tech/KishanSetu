import 'package:supabase_flutter/supabase_flutter.dart';undefined
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

    // Create-or-reuse is atomic and safe against two participants tapping at once.
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
      final matches = (existingRows as List).cast<Map<String, dynamic>>()
          .where((item) => item['produce_id'] == produceId);
      if (matches.isNotEmpty) return ChatConversation.fromMap(matches.first);
      final created = await _client.from('chat_conversations').insert({
        'farmer_id': farmerId,
        'buyer_id': buyerId,
        'produce_id': produceId,
      }).select().single();
      return ChatConversation.fromMap(created);
    }
  }

  Future<List<ChatConversation>> listConversations() async {
    final uid = currentUserId;
    if (uid == null) throw const AuthException('Please sign in to view chats.');
    final rows = await _client.from('chat_conversations').select()
        .or('farmer_id.eq.$uid,buyer_id.eq.$uid').order('updated_at', ascending: false);
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

  Future<Map<String, dynamic>?> getOtherParticipant(String id) async {
    return await _client.from('profiles')
        .select('id,full_name,role,avatar_url,phone,district,village,state,latitude,longitude')
        .eq('id', id).maybeSingle();
  }
}
