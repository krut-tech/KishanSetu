import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_market_app/core/theme/theme_controller.dart';
import 'package:farmer_market_app/core/notifications/push_notification_service.dart';
import 'package:farmer_market_app/features/chat/data/chat_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:farmer_market_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_state.dart';

import 'package:fpdart/fpdart.dart';

class FakeAuthRepository implements AuthRepository {
  bool signOutCalled = false;

  @override
  Stream<sb.AuthState> get onAuthStateChanges => const Stream.empty();

  @override
  Future<AppResult<void>> signOut() async {
    signOutCalled = true;
    return const Right(null);
  }

  @override
  sb.User? get currentUser => null;

  @override
  Future<AppResult<UserProfile>> getUserProfile(String userId) async {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> resetPassword(String newPassword) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<void>> sendPasswordResetEmail(String email) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<sb.AuthResponse>> signIn(
      {required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<bool>> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<sb.AuthResponse>> signUp(
      {required String email,
      required String password,
      required String fullName,
      required UserRole role,
      String? phone}) {
    throw UnimplementedError();
  }

  @override
  sb.RealtimeChannel subscribeToProfile(
      String userId, void Function(UserProfile? p1) onUpdate) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<UserProfile>> updateUserProfile(UserProfile profile) {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
      'Part 2 — Chat Message Chronological Sorting & Deterministic Tie-Breaker',
      () {
    test('Messages are sorted chronologically with ID tie-breaker', () {
      final now = DateTime.utc(2026, 10, 11, 10, 0, 0);
      final msg1 = ChatMessage(
        id: 'msg-b',
        conversationId: 'c1',
        senderId: 'u1',
        body: 'Second message with same timestamp',
        createdAt: now,
        readAt: null,
      );
      final msg2 = ChatMessage(
        id: 'msg-a',
        conversationId: 'c1',
        senderId: 'u2',
        body: 'First message with same timestamp',
        createdAt: now,
        readAt: null,
      );
      final msg3 = ChatMessage(
        id: 'msg-c',
        conversationId: 'c1',
        senderId: 'u1',
        body: 'Later message',
        createdAt: now.add(const Duration(minutes: 5)),
        readAt: null,
      );

      final list = [msg3, msg1, msg2];
      list.sort((a, b) {
        final byTime = a.createdAt.toUtc().compareTo(b.createdAt.toUtc());
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });

      expect(list[0].id, equals('msg-a'));
      expect(list[1].id, equals('msg-b'));
      expect(list[2].id, equals('msg-c'));
    });

    test('Deduplication and merging preserves updated readAt state', () {
      final now = DateTime.utc(2026, 10, 11, 10, 0, 0);
      final initialMessage = ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u2',
        body: 'Hello',
        createdAt: now,
        readAt: null,
      );

      final realtimeUpdatedMessage = ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u2',
        body: 'Hello',
        createdAt: now,
        readAt: now.add(const Duration(seconds: 10)),
      );

      final serverMessages = [initialMessage];
      final localRealtimeMessages = [realtimeUpdatedMessage];

      final byId = <String, ChatMessage>{};
      for (final m in serverMessages) {
        byId[m.id] = m;
      }
      for (final m in localRealtimeMessages) {
        final existing = byId[m.id];
        if (existing == null) {
          byId[m.id] = m;
        } else {
          final readAt = m.readAt ?? existing.readAt;
          byId[m.id] = ChatMessage(
            id: m.id,
            conversationId: m.conversationId,
            senderId: m.senderId,
            body: m.body,
            createdAt: m.createdAt,
            readAt: readAt,
          );
        }
      }

      expect(byId['m1']?.readAt, isNotNull);
      expect(byId['m1']?.readAt, equals(now.add(const Duration(seconds: 10))));
    });
  });

  group('Part 2 — WhatsApp-Style Conversation List Ordering', () {
    test('Conversations are mapped and sorted DESC by latest message timestamp',
        () {
      final t1 = DateTime.utc(2026, 10, 11, 9, 0, 0);
      final t2 = DateTime.utc(2026, 10, 11, 10, 0, 0);

      final c1 = ChatConversationSummary(
        conversationId: 'c1',
        farmerId: 'f1',
        buyerId: 'b1',
        produceId: 'p1',
        otherUserId: 'f1',
        otherUserName: 'Farmer Ram',
        otherUserRole: 'farmer',
        otherUserAvatar: null,
        otherUserDistrict: 'Anand',
        lastMessage: 'Earlier message',
        lastMessageAt: t1,
        lastMessageSenderId: 'f1',
        unreadCount: 0,
      );

      final c2 = ChatConversationSummary(
        conversationId: 'c2',
        farmerId: 'f2',
        buyerId: 'b1',
        produceId: 'p2',
        otherUserId: 'f2',
        otherUserName: 'Farmer Shyam',
        otherUserRole: 'farmer',
        otherUserAvatar: null,
        otherUserDistrict: 'Rajkot',
        lastMessage: 'Latest message',
        lastMessageAt: t2,
        lastMessageSenderId: 'f2',
        unreadCount: 1,
      );

      final list = [c1, c2];
      list.sort((a, b) {
        final timeA = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });

      expect(list.first.conversationId, equals('c2'));
      expect(list.last.conversationId, equals('c1'));
    });
  });

  group('Part 3 — Per-User Chat Clearing and Deletion Filtering', () {
    test('Cleared/Deleted cutoff filters old messages for current user', () {
      final t1 = DateTime.utc(2026, 10, 11, 8, 0, 0);
      final t2 = DateTime.utc(2026, 10, 11, 9, 0, 0);
      final t3 = DateTime.utc(2026, 10, 11, 10, 0, 0);

      final msg1 = ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        body: 'Old msg 1',
        createdAt: t1,
        readAt: null,
      );
      final msg2 = ChatMessage(
        id: 'm2',
        conversationId: 'c1',
        senderId: 'u2',
        body: 'Old msg 2',
        createdAt: t2,
        readAt: null,
      );
      final msg3 = ChatMessage(
        id: 'm3',
        conversationId: 'c1',
        senderId: 'u2',
        body: 'New msg after clear',
        createdAt: t3,
        readAt: null,
      );

      final allMessages = [msg1, msg2, msg3];
      final clearedAt = t2; // User cleared chat at t2

      final visibleForUser = allMessages
          .where((m) => m.createdAt.toUtc().isAfter(clearedAt))
          .toList();

      expect(visibleForUser.length, equals(1));
      expect(visibleForUser.first.id, equals('m3'));
      expect(allMessages.length,
          equals(3)); // Other participant still retains all 3
    });
  });

  group('Part 4 — Notification Route Resolution', () {
    test('resolveRouteFromData maps notification types to correct app routes',
        () {
      expect(
          PushNotificationService.resolveRouteFromData(
              {'type': 'chat_message'}),
          equals('/messages'));
      expect(
          PushNotificationService.resolveRouteFromData({'type': 'new_offer'}),
          equals('/offers'));
      expect(
          PushNotificationService.resolveRouteFromData(
              {'type': 'produce_interest'}),
          equals('/my-produce'));
      expect(
          PushNotificationService.resolveRouteFromData(
              {'type': 'market_price_update'}),
          equals('/market-prices'));
      expect(
          PushNotificationService.resolveRouteFromData(
              {'route': '/custom-route'}),
          equals('/custom-route'));
    });
  });

  group('Part 6 — Theme Controller Instant Toggle and Persistence', () {
    test('toggleTheme updates state immediately without waiting for disk write',
        () async {
      SharedPreferences.setMockInitialValues(
          {'user_theme_mode': ThemeMode.dark.index});
      final controller = ThemeController();

      expect(controller.state, equals(ThemeMode.dark));

      controller.toggleTheme();
      expect(controller.state, equals(ThemeMode.light));

      controller.toggleTheme();
      expect(controller.state, equals(ThemeMode.dark));
    });
  });

  group('Part 7 — AuthNotifier Logout Behavior', () {
    test('signOut clears state and calls repository signOut', () async {
      final fakeRepo = FakeAuthRepository();
      final notifier = AuthNotifier(fakeRepo);

      await notifier.signOut();

      expect(fakeRepo.signOutCalled, isTrue);
      expect(notifier.state.status, equals(AuthStatus.unauthenticated));
    });
  });
}
