import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmer_market_app/features/notifications/domain/models/notification_model.dart';

class NotificationItemCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationItemCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.newOffer:
        return Icons.local_offer;
      case NotificationType.offerAccepted:
        return Icons.check_circle;
      case NotificationType.offerRejected:
      case NotificationType.offerCancelled:
        return Icons.cancel;
      case NotificationType.counterOffer:
        return Icons.handshake;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.produceInterest:
        return Icons.visibility;
      case NotificationType.marketPriceUpdate:
        return Icons.trending_up;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color _getIconColor(ColorScheme colorScheme) {
    switch (notification.type) {
      case NotificationType.offerAccepted:
        return Colors.green;
      case NotificationType.offerRejected:
      case NotificationType.offerCancelled:
        return colorScheme.error;
      case NotificationType.newOffer:
      case NotificationType.counterOffer:
        return colorScheme.primary;
      default:
        return colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead ? Colors.transparent : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: _getIconColor(theme.colorScheme).withValues(alpha: 0.1),
              child: Icon(
                _getIcon(),
                color: _getIconColor(theme.colorScheme),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(notification.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
