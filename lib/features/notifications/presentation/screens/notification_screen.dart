import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:farmer_market_app/core/routing/route_names.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/notifications/domain/models/notification_model.dart';
import 'package:farmer_market_app/features/notifications/presentation/controllers/notification_notifier.dart';
import 'package:farmer_market_app/features/notifications/presentation/widgets/notification_item_card.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notificationsTitle),
        actions: [
          if (state.notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(notificationNotifierProvider.notifier).markAllAsRead();
              },
              child: Text(
                context.l10n.markAllRead,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, ref, state),
    );
  }

  void _navigateToNotificationTarget(
      BuildContext context, WidgetRef ref, NotificationModel notification) {
    final relatedId = notification.relatedId;
    final type = notification.type;
    final role = ref.read(authNotifierProvider).profile?.role;

    if (type == NotificationType.newMessage) {
      context.push(RouteNames.messages);
      return;
    }

    if (type == NotificationType.marketPriceUpdate) {
      context.push(RouteNames.marketPrices);
      return;
    }

    if (type == NotificationType.produceInterest) {
      if (relatedId != null && relatedId.isNotEmpty) {
        context.push('/my-produce?produceId=$relatedId');
      } else {
        context.push(RouteNames.myProduce);
      }
      return;
    }

    // Offer-related notifications: offerRejected, offerAccepted, newOffer, counterOffer, offerCancelled
    if (type == NotificationType.offerRejected ||
        type == NotificationType.offerAccepted ||
        type == NotificationType.newOffer ||
        type == NotificationType.counterOffer ||
        type == NotificationType.offerCancelled ||
        notification.relatedType == 'offer') {
      final String targetStatus;
      switch (type) {
        case NotificationType.offerRejected:
          targetStatus = 'rejected';
          break;
        case NotificationType.offerAccepted:
          targetStatus = 'accepted';
          break;
        case NotificationType.counterOffer:
          targetStatus = 'countered';
          break;
        case NotificationType.offerCancelled:
          targetStatus = 'cancelled';
          break;
        default:
          targetStatus = 'pending';
      }

      final routePath = (role == UserRole.buyer)
          ? RouteNames.buyerOffers
          : RouteNames.offers;

      final queryStr = relatedId != null && relatedId.isNotEmpty
          ? '$routePath?offerId=$relatedId&status=$targetStatus'
          : '$routePath?status=$targetStatus';

      context.push(queryStr);
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, NotificationState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(state.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(notificationNotifierProvider.notifier).refresh();
              },
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              context.l10n.noNotificationsYet,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(notificationNotifierProvider.notifier).refresh();
      },
      child: ListView.separated(
        itemCount: state.notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          return NotificationItemCard(
            notification: notification,
            onTap: () {
              if (!notification.isRead) {
                ref
                    .read(notificationNotifierProvider.notifier)
                    .markAsRead(notification.id);
              }
              _navigateToNotificationTarget(context, ref, notification);
            },
          );
        },
      ),
    );
  }
}
