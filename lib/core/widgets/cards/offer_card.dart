import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/badges/app_status_badge.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/buttons/map_link_button.dart';
import 'package:farmer_market_app/core/widgets/price/app_price_text.dart';
import 'package:farmer_market_app/features/farmer/domain/models/offer_model.dart';
import 'package:farmer_market_app/core/localization/localization_extension.dart';
import 'package:farmer_market_app/features/translation/presentation/widgets/translated_text_widget.dart';

/// Reusable Offer / Negotiation Card displaying offer status, bid price, edit history, and action triggers.
class OfferCard extends StatefulWidget {
  final String cropName;
  final String buyerName;

  /// Optional party label prefix (e.g., "Buyer", "Farmer").
  /// Defaults to [AppLocalizations.buyerLabel] if not specified.
  final String? partyLabel;

  final double offerPrice;
  final String quantity;
  final AppStatusType status;
  final String? statusLabel;
  final String expiresText;
  final String? message;
  final List<OfferHistoryModel>? history;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCounter;
  final String? acceptLabel;
  final String? rejectLabel;
  final String? counterLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;
  final String? cancelLabel;

  /// Free-text location of the other party; when set, a tappable
  /// "View on Map" row is shown under the title.
  final String? location;

  /// Whether this offer card is highlighted (e.g., opened via direct notification tap).
  final bool isHighlighted;

  const OfferCard({
    super.key,
    required this.cropName,
    required this.buyerName,
    this.partyLabel,
    required this.offerPrice,
    required this.quantity,
    required this.status,
    this.statusLabel,
    required this.expiresText,
    this.message,
    this.history,
    this.onAccept,
    this.onReject,
    this.onCounter,
    this.acceptLabel,
    this.rejectLabel,
    this.counterLabel,
    this.onCancel,
    this.onEdit,
    this.cancelLabel,
    this.location,
    this.isHighlighted = false,
  });

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  bool _isHistoryExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final warningColor = isDark ? const Color(0xFFFBBF24) : AppColors.warning;

    final rejectText = widget.rejectLabel ?? context.l10n.rejectedStatus;
    final acceptText = widget.acceptLabel ?? context.l10n.acceptedStatus;
    final cancelText = widget.cancelLabel ?? context.l10n.cancelOffer;
    final counterText = widget.counterLabel ?? 'Counter';
    final editText = context.l10n.editOfferLabel;

    final hasHistory = widget.history != null && widget.history!.length > 1;

    final String partyInfo;
    if (widget.partyLabel != null) {
      partyInfo = '${widget.partyLabel}: ${widget.buyerName}';
    } else if (widget.buyerName.startsWith('${context.l10n.farmerLabel}:') ||
        widget.buyerName.startsWith('Farmer:') ||
        widget.buyerName.startsWith('${context.l10n.buyerLabel}:') ||
        widget.buyerName.startsWith('Buyer:')) {
      partyInfo = widget.buyerName;
    } else {
      partyInfo = '${context.l10n.buyerLabel}: ${widget.buyerName}';
    }

    return AppCard(
      backgroundColor: widget.isHighlighted
          ? colorScheme.primaryContainer.withValues(alpha: 0.25)
          : null,
      borderColor: widget.isHighlighted ? colorScheme.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TranslatedTextWidget(
                        text: widget.cropName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        showToggle: false,
                      ),
                    ),
                    if (hasHistory) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.l10n.editedLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppStatusBadge(
                  type: widget.status, customLabel: widget.statusLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$partyInfo • ${context.l10n.offerQuantity}: ${widget.quantity}',
            style: TextStyle(fontSize: 13, color: secondaryText),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.location != null &&
              widget.location!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            MapLinkButton(location: widget.location!.trim()),
          ],
          if (widget.message != null && widget.message!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.l10n.messageLabelColon} ',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: secondaryText),
                ),
                Expanded(
                  child: TranslatedTextWidget(
                    text: widget.message!,
                    style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: secondaryText),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.offeredPrice,
                      style: TextStyle(fontSize: 12, color: secondaryText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    AppPriceText(price: widget.offerPrice),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: warningColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.expiresText,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: warningColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Offer History Expansion Section
          if (hasHistory) ...[
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: () {
                setState(() {
                  _isHistoryExpanded = !_isHistoryExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                child: Row(
                  children: [
                    Icon(
                      _isHistoryExpanded
                          ? Icons.history_toggle_off
                          : Icons.history,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isHistoryExpanded
                          ? 'Hide Offer History'
                          : 'View Offer History (${widget.history!.length} versions)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    Icon(
                      _isHistoryExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            if (_isHistoryExpanded) ...[
              Builder(
                builder: (context) {
                  final sortedHistory =
                      List<OfferHistoryModel>.from(widget.history!)
                        ..sort((a, b) => a.version.compareTo(b.version));
                  final maxVersion =
                      sortedHistory.isNotEmpty ? sortedHistory.last.version : 1;

                  return Container(
                    margin: const EdgeInsets.only(top: AppSpacing.xs),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sortedHistory.map((ver) {
                        final isLatest = ver.version == maxVersion;
                        final formattedDate = DateFormat('dd MMM yyyy, hh:mm a')
                            .format(ver.createdAt);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isLatest
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'v${ver.version}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isLatest
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '₹${ver.offeredPrice.toStringAsFixed(2)} / ${ver.quantity} units ${isLatest ? "(Current)" : ""}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isLatest
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    if (ver.message != null &&
                                        ver.message!.isNotEmpty)
                                      Text(
                                        '"${ver.message}"',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: secondaryText),
                                      ),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                          fontSize: 10, color: secondaryText),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ],

          if (widget.status == AppStatusType.pending) ...[
            const SizedBox(height: AppSpacing.md),
            if (_buildPendingActions(
              cancelText: cancelText,
              editText: editText,
              rejectText: rejectText,
              acceptText: acceptText,
              counterText: counterText,
            )
                case final actionsWidget?)
              actionsWidget,
          ],
        ],
      ),
    );
  }

  Widget? _buildPendingActions({
    required String cancelText,
    required String editText,
    required String rejectText,
    required String acceptText,
    required String counterText,
  }) {
    if (widget.onEdit != null) {
      return Row(
        children: [
          if (widget.onCancel != null) ...[
            Expanded(
              child: AppButton(
                label: cancelText,
                style: AppButtonStyle.outlined,
                onPressed: widget.onCancel,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: AppButton(
              label: editText,
              style: AppButtonStyle.secondary,
              onPressed: widget.onEdit,
            ),
          ),
        ],
      );
    }

    if (widget.onAccept != null &&
        widget.onReject != null &&
        widget.onCounter == null &&
        widget.onCancel == null) {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              label: rejectText,
              style: AppButtonStyle.outlined,
              onPressed: widget.onReject,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton(
              label: acceptText,
              style: AppButtonStyle.primary,
              onPressed: widget.onAccept,
            ),
          ),
        ],
      );
    }

    if (widget.onAccept != null ||
        widget.onReject != null ||
        widget.onCounter != null) {
      if (widget.onCancel != null) {
        final row1 = Row(
          children: [
            Expanded(
              child: AppButton(
                label: rejectText,
                style: AppButtonStyle.outlined,
                onPressed: widget.onReject,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: cancelText,
                style: AppButtonStyle.outlined,
                onPressed: widget.onCancel,
              ),
            ),
          ],
        );

        final row2 = Row(
          children: [
            Expanded(
              child: AppButton(
                label: counterText,
                style: AppButtonStyle.secondary,
                onPressed: widget.onCounter,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: acceptText,
                style: AppButtonStyle.primary,
                onPressed: widget.onAccept,
              ),
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            row1,
            const SizedBox(height: AppSpacing.xs),
            row2,
          ],
        );
      }

      return Row(
        children: [
          Expanded(
            child: AppButton(
              label: rejectText,
              style: AppButtonStyle.outlined,
              onPressed: widget.onReject,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton(
              label: counterText,
              style: AppButtonStyle.secondary,
              onPressed: widget.onCounter,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton(
              label: acceptText,
              style: AppButtonStyle.primary,
              onPressed: widget.onAccept,
            ),
          ),
        ],
      );
    }

    if (widget.onCancel != null) {
      return AppButton(
        label: cancelText,
        style: AppButtonStyle.outlined,
        onPressed: widget.onCancel,
      );
    }

    return null;
  }
}
