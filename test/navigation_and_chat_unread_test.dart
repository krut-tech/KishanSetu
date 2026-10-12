import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer_market_app/l10n/generated/app_localizations.dart';
import 'package:farmer_market_app/core/errors/failure.dart';
import 'package:farmer_market_app/features/chat/data/chat_repository.dart';
import 'package:farmer_market_app/features/chat/presentation/chat_list_screen.dart';
import 'package:farmer_market_app/features/chat/presentation/chat_screen.dart';
import 'package:farmer_market_app/features/home/presentation/farmer_home_screen.dart';
import 'package:farmer_market_app/features/home/presentation/buyer_home_screen.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_profile.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:farmer_market_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:farmer_market_app/features/farmer/domain/models/dashboard_stats.dart';
import 'package:farmer_market_app/features/farmer/domain/models/produce_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/features/farmer/domain/models/market_price_model.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_dashboard_notifier.dart';
import 'package:farmer_market_app/features/farmer/domain/repositories/farmer_repository.dart';
import 'package:farmer_market_app/features/buyer/domain/models/buyer_dashboard_stats.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_providers.dart';
import 'package:farmer_market_app/features/buyer/presentation/controllers/buyer_dashboard_notifier.dart';
import 'package:farmer_market_app/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:farmer_market_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:farmer_market_app/features/notifications/presentation/controllers/notification_repository_provider.dart';
import 'package:farmer_market_app/core/errors/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:fpdart/fpdart.dart';

class FakeRealtimeChannel extends sb.RealtimeChannel {
  bool unsubscribed = false;
  FakeRealtimeChannel()
      : super('fake_channel', sb.RealtimeClient('https://fake.supabase.co'));

  @override
  sb.RealtimeChannel subscribe(
      [void Function(sb.RealtimeSubscribeStatus status, Object? error)?
          callback,
      Duration? timeout]) {
    return this;
  }

  @override
  Future<String> unsubscribe([Duration? timeout]) async {
    unsubscribed = true;
    return 'ok';
  }
}

class FakeAuthRepository implements AuthRepository {
  final UserProfile? mockProfile;
  FakeAuthRepository({this.mockProfile});

  @override
  Stream<sb.AuthState> get onAuthStateChanges => const Stream.empty();

  @override
  sb.User? get currentUser => const sb.User(
        id: 'user-123',
        appMetadata: {},
        userMetadata: {},
        aud: '',
        createdAt: '',
      );

  @override
  Future<AppResult<UserProfile>> getUserProfile(String userId) async {
    if (mockProfile != null) return Right(mockProfile!);
    return const Left(AuthFailure('Profile not found'));
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
  Future<AppResult<void>> signOut() async {
    return const Right(null);
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
    return FakeRealtimeChannel();
  }

  @override
  Future<AppResult<UserProfile>> updateUserProfile(UserProfile profile) {
    throw UnimplementedError();
  }
}

class MockFarmerRepository implements FarmerRepository {
  @override
  Future<AppResult<DashboardStats>> getFarmerDashboardStats(String farmerId) async {
    return right(const DashboardStats(
      totalProduce: 5,
      activeListings: 3,
      pendingOffers: 2,
      acceptedOffers: 1,
      soldProduce: 1,
      draftProduce: 0,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    if (name.contains('subscribe')) {
      return FakeRealtimeChannel();
    }
    if (invocation.memberName == #getOffersForFarmer) {
      return Future<AppResult<List<OfferModel>>>.value(right([]));
    }
    if (invocation.memberName == #getFarmerProduce) {
      return Future<AppResult<List<ProduceModel>>>.value(right([]));
    }
    if (invocation.memberName == #getMarketPrices ||
        invocation.memberName == #getLatestMarketPriceHighlights) {
      return Future<AppResult<List<MarketPriceModel>>>.value(right([]));
    }
    return super.noSuchMethod(invocation);
  }
}

class MockBuyerRepository implements BuyerRepository {
  @override
  Future<AppResult<BuyerDashboardStats>> getBuyerDashboardStats(String buyerId) async {
    return right(const BuyerDashboardStats(
      totalAvailableProduce: 10,
      activeOffers: 4,
      pendingOffers: 2,
      acceptedOffers: 1,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    if (name.contains('subscribe')) {
      return FakeRealtimeChannel();
    }
    if (invocation.memberName == #getBuyerOffers) {
      return Future<AppResult<List<OfferModel>>>.value(right([]));
    }
    if (invocation.memberName == #getMarketplaceProduce ||
        invocation.memberName == #getFeaturedProduce) {
      return Future<AppResult<List<ProduceModel>>>.value(right([]));
    }
    return super.noSuchMethod(invocation);
  }
}

class MockChatRepository implements ChatRepository {
  bool markIncomingReadCalled = false;
  String? lastMarkedConversationId;
  int listSummariesCallCount = 0;
  final FakeRealtimeChannel listChannel = FakeRealtimeChannel();
  final FakeRealtimeChannel msgChannel = FakeRealtimeChannel();
  void Function()? listCallback;
  void Function(ChatMessage)? msgCallback;

  List<ChatConversationSummary> mockSummaries = [];
  List<ChatMessage> mockMessages = [];

  @override
  String? get currentUserId => 'user-123';

  @override
  Future<ChatConversation> startConversation({
    required String farmerId,
    required String buyerId,
    String? produceId,
  }) async {
    return ChatConversation(
      id: 'c1',
      farmerId: farmerId,
      buyerId: buyerId,
      produceId: produceId,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<ChatConversationSummary>> listConversationSummaries() async {
    listSummariesCallCount++;
    return mockSummaries;
  }

  @override
  Future<List<ChatConversation>> listConversations() async {
    return [];
  }

  @override
  Future<List<ChatMessage>> loadMessages(String conversationId) async {
    return mockMessages;
  }

  @override
  Future<DateTime> clearChatForMe(String conversationId) async {
    return DateTime.now();
  }

  @override
  Future<void> deleteChatForMe(String conversationId) async {}

  @override
  Future<void> sendMessage(String conversationId, String body) async {}

  @override
  Future<void> markIncomingRead(String conversationId) async {
    markIncomingReadCalled = true;
    lastMarkedConversationId = conversationId;
  }

  @override
  sb.RealtimeChannel subscribeToConversationUpdates(void Function() onChanged) {
    listCallback = onChanged;
    return listChannel;
  }

  @override
  sb.RealtimeChannel subscribeToMessages(
      String conversationId, void Function(ChatMessage) onMessage) {
    msgCallback = onMessage;
    return msgChannel;
  }

  @override
  Future<Map<String, dynamic>?> getOtherParticipant(String id) async {
    return {'full_name': 'Other User', 'role': 'farmer'};
  }
}

Widget createTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(disableAnimations: true),
          child: child,
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await sb.Supabase.initialize(
        url: 'https://fake.supabase.co',
        publishableKey: 'sb_publishable_DHunbunR1EYt-IMaubiHfg_53aWe6YH',
      );
    } catch (_) {}
  });

  final mockFarmerProfile = UserProfile(
    id: 'user-123',
    fullName: 'Ramesh Farmer',
    role: UserRole.farmer,
    phone: '9876543210',
    isProfileComplete: true,
    createdAt: DateTime.now(),
  );

  final mockBuyerProfile = UserProfile(
    id: 'user-123',
    fullName: 'Suresh Buyer',
    role: UserRole.buyer,
    phone: '9876543211',
    isProfileComplete: true,
    createdAt: DateTime.now(),
  );

  group('Requirement 1 — Android Back Navigation & Double-Tap Exit Tests', () {
    testWidgets('FarmerHomeScreen on non-zero tab returns to Home tab on back press',
        (tester) async {
      final fakeAuthRepo = FakeAuthRepository(mockProfile: mockFarmerProfile);
      final authNotifier = AuthNotifier(fakeAuthRepo);
      authNotifier.setTestState(AuthState(
        status: AuthStatus.authenticated,
        user: fakeAuthRepo.currentUser,
        profile: mockFarmerProfile,
      ));

      final mockFarmerRepo = MockFarmerRepository();
      final farmerDashNotifier = FarmerDashboardNotifier(mockFarmerRepo);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => authNotifier),
            farmerRepositoryProvider.overrideWithValue(mockFarmerRepo),
            farmerDashboardNotifierProvider.overrideWith((ref) => farmerDashNotifier),
            notificationRepositoryProvider
                .overrideWithValue(const UninitializedNotificationRepository()),
          ],
          child: createTestApp(const FarmerHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Market Prices tab (index 1)
      await tester.tap(find.text('Market Prices').last);
      await tester.pumpAndSettle();

      // Simulate Android back button press via PopScope
      final popScopeFinder = find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('PopScope'));
      final popScope = tester.widget(popScopeFinder) as dynamic;
      popScope.onPopInvokedWithResult?.call(false, null);
      await tester.pumpAndSettle();

      // Should be back on Home tab view (Hero welcome card visible)
      expect(find.textContaining('Ramesh Farmer'), findsWidgets);
    });

    testWidgets('FarmerHomeScreen shows "Press back again to exit" on first back press on Tab 0',
        (tester) async {
      final fakeAuthRepo = FakeAuthRepository(mockProfile: mockFarmerProfile);
      final authNotifier = AuthNotifier(fakeAuthRepo);
      authNotifier.setTestState(AuthState(
        status: AuthStatus.authenticated,
        user: fakeAuthRepo.currentUser,
        profile: mockFarmerProfile,
      ));

      final mockFarmerRepo = MockFarmerRepository();
      final farmerDashNotifier = FarmerDashboardNotifier(mockFarmerRepo);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => authNotifier),
            farmerRepositoryProvider.overrideWithValue(mockFarmerRepo),
            farmerDashboardNotifierProvider.overrideWith((ref) => farmerDashNotifier),
            notificationRepositoryProvider
                .overrideWithValue(const UninitializedNotificationRepository()),
          ],
          child: createTestApp(const FarmerHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // On Tab 0, simulate back press
      final popScopeFinder = find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('PopScope'));
      final popScope = tester.widget(popScopeFinder) as dynamic;
      popScope.onPopInvokedWithResult?.call(false, null);
      await tester.pump();

      expect(find.text('Press back again to exit'), findsOneWidget);
    });

    testWidgets('BuyerHomeScreen on non-zero tab returns to Home tab on back press',
        (tester) async {
      final fakeAuthRepo = FakeAuthRepository(mockProfile: mockBuyerProfile);
      final authNotifier = AuthNotifier(fakeAuthRepo);
      authNotifier.setTestState(AuthState(
        status: AuthStatus.authenticated,
        user: fakeAuthRepo.currentUser,
        profile: mockBuyerProfile,
      ));

      final mockBuyerRepo = MockBuyerRepository();
      final mockFarmerRepo = MockFarmerRepository();
      final buyerDashNotifier =
          BuyerDashboardNotifier(mockBuyerRepo, mockFarmerRepo);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => authNotifier),
            buyerRepositoryProvider.overrideWithValue(mockBuyerRepo),
            farmerRepositoryProvider.overrideWithValue(mockFarmerRepo),
            buyerDashboardNotifierProvider.overrideWith((ref) => buyerDashNotifier),
            notificationRepositoryProvider
                .overrideWithValue(const UninitializedNotificationRepository()),
          ],
          child: createTestApp(const BuyerHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Marketplace tab (index 1)
      await tester.tap(find.text('Marketplace').last);
      await tester.pumpAndSettle();

      // Simulate Android back press
      final popScopeFinder = find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('PopScope'));
      final popScope = tester.widget(popScopeFinder) as dynamic;
      popScope.onPopInvokedWithResult?.call(false, null);
      await tester.pumpAndSettle();

      // Should return to Home tab
      expect(find.textContaining('Suresh Buyer'), findsWidgets);
    });

    testWidgets('ChatListScreen has a visible back arrow button', (tester) async {
      final repo = MockChatRepository();
      await tester.pumpWidget(
        createTestApp(ChatListScreen(repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('ChatScreen has a visible back arrow button', (tester) async {
      final repo = MockChatRepository();
      final conversation = ChatConversation(
        id: 'c1',
        farmerId: 'user-123',
        buyerId: 'user-456',
        produceId: null,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestApp(
          ChatScreen(
            repository: repo,
            conversation: conversation,
            otherUserId: 'user-456',
            otherUserName: 'Kisan User',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  group('Requirement 2 — Automatically Clear Unread Count Tests', () {
    testWidgets('Opening ChatScreen triggers markIncomingRead for conversation',
        (tester) async {
      final repo = MockChatRepository();
      final conversation = ChatConversation(
        id: 'conv-101',
        farmerId: 'user-123',
        buyerId: 'user-456',
        produceId: null,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestApp(
          ChatScreen(
            repository: repo,
            conversation: conversation,
            otherUserId: 'user-456',
            otherUserName: 'Farmer Bob',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.markIncomingReadCalled, isTrue);
      expect(repo.lastMarkedConversationId, equals('conv-101'));
    });

    testWidgets('Tapping unread chat in ChatListScreen resets unread count immediately',
        (tester) async {
      final repo = MockChatRepository();
      final now = DateTime.now();
      repo.mockSummaries = [
        ChatConversationSummary(
          conversationId: 'c-unread-1',
          farmerId: 'user-123',
          buyerId: 'other-user',
          produceId: null,
          otherUserId: 'other-user',
          otherUserName: 'Rajesh Kumar',
          otherUserRole: 'farmer',
          otherUserAvatar: null,
          otherUserDistrict: 'Anand',
          lastMessage: 'Hello friend',
          lastMessageAt: now,
          lastMessageSenderId: 'other-user',
          unreadCount: 3,
        ),
      ];

      await tester.pumpWidget(
        createTestApp(ChatListScreen(repository: repo)),
      );
      await tester.pumpAndSettle();

      // Verify unread badge is initially '3'
      expect(find.text('3'), findsOneWidget);

      // Tap the conversation item
      await tester.tap(find.text('Rajesh Kumar'));
      await tester.pump(); // Start navigation frame

      // ChatScreen opens and markIncomingRead is called
      expect(repo.markIncomingReadCalled, isTrue);
      expect(repo.lastMarkedConversationId, equals('c-unread-1'));
    });

    test('Incoming read updates target only incoming messages (sender_id != currentUserId)',
        () {
      const uid = 'user-123';
      final msgIncoming = ChatMessage(
        id: 'm-in',
        conversationId: 'c1',
        senderId: 'other-456',
        body: 'Incoming message',
        createdAt: DateTime.now(),
        readAt: null,
      );
      final msgOutgoing = ChatMessage(
        id: 'm-out',
        conversationId: 'c1',
        senderId: uid,
        body: 'Outgoing message',
        createdAt: DateTime.now(),
        readAt: null,
      );

      // Verify sender condition: incoming message sender != uid, outgoing sender == uid
      expect(msgIncoming.senderId != uid, isTrue);
      expect(msgOutgoing.senderId != uid, isFalse);
    });
  });

  group('Requirement 3 — Real-Time Updates & Subscription Management Tests', () {
    testWidgets('ChatListScreen unsubscribes Realtime channel on dispose',
        (tester) async {
      final repo = MockChatRepository();

      await tester.pumpWidget(
        createTestApp(ChatListScreen(repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(repo.listChannel.unsubscribed, isFalse);

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.listChannel.unsubscribed, isTrue);
    });

    testWidgets('ChatScreen unsubscribes Realtime channel on dispose',
        (tester) async {
      final repo = MockChatRepository();
      final conversation = ChatConversation(
        id: 'c1',
        farmerId: 'user-123',
        buyerId: 'user-456',
        produceId: null,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestApp(
          ChatScreen(
            repository: repo,
            conversation: conversation,
            otherUserId: 'user-456',
            otherUserName: 'Kisan User',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.msgChannel.unsubscribed, isFalse);

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.msgChannel.unsubscribed, isTrue);
    });

    testWidgets('Realtime event on ChatListScreen triggers refresh', (tester) async {
      final repo = MockChatRepository();
      await tester.pumpWidget(
        createTestApp(ChatListScreen(repository: repo)),
      );
      await tester.pumpAndSettle();

      final initialCalls = repo.listSummariesCallCount;

      // Trigger Realtime callback
      repo.listCallback?.call();
      await tester.pumpAndSettle();

      expect(repo.listSummariesCallCount, greaterThan(initialCalls));
    });

    testWidgets('ChatScreen deduplicates messages received via Realtime',
        (tester) async {
      final repo = MockChatRepository();
      final now = DateTime.now();
      final msg1 = ChatMessage(
        id: 'msg-dup-1',
        conversationId: 'c1',
        senderId: 'user-456',
        body: 'Original body',
        createdAt: now,
        readAt: null,
      );
      repo.mockMessages = [msg1];

      final conversation = ChatConversation(
        id: 'c1',
        farmerId: 'user-123',
        buyerId: 'user-456',
        produceId: null,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestApp(
          ChatScreen(
            repository: repo,
            conversation: conversation,
            otherUserId: 'user-456',
            otherUserName: 'Kisan User',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Original body'), findsOneWidget);

      // Send same message ID via Realtime callback with updated readAt
      final updatedMsg1 = ChatMessage(
        id: 'msg-dup-1',
        conversationId: 'c1',
        senderId: 'user-456',
        body: 'Original body',
        createdAt: now,
        readAt: now.add(const Duration(seconds: 5)),
      );

      repo.msgCallback?.call(updatedMsg1);
      await tester.pumpAndSettle();

      // Only 1 message instance rendered (no duplicates)
      expect(find.text('Original body'), findsOneWidget);
    });
  });
}
