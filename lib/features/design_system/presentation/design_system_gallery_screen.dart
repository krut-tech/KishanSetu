import 'package:flutter/material.dart';
import 'package:farmer_market_app/core/animations/animated_pressable.dart';
import 'package:farmer_market_app/core/animations/animated_price_counter.dart';
import 'package:farmer_market_app/core/animations/animated_status_switcher.dart';
import 'package:farmer_market_app/core/animations/expandable_container.dart';
import 'package:farmer_market_app/core/animations/success_checkmark_animation.dart';
import 'package:farmer_market_app/core/constants/app_colors.dart';
import 'package:farmer_market_app/core/constants/app_radius.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_bar/app_top_bar.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/badges/app_status_badge.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/cards/buyer_requirement_card.dart';
import 'package:farmer_market_app/core/widgets/cards/offer_card.dart';
import 'package:farmer_market_app/core/widgets/cards/produce_card.dart';
import 'package:farmer_market_app/core/widgets/cards/transaction_card.dart';
import 'package:farmer_market_app/core/widgets/chips/app_chip.dart';
import 'package:farmer_market_app/core/widgets/dialogs/app_dialogs.dart';
import 'package:farmer_market_app/core/widgets/dropdowns/app_dropdown.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_currency_field.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_search_field.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/price/app_price_text.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/core/widgets/states/loading_indicator.dart';
import 'package:farmer_market_app/core/widgets/states/shimmer_loading.dart';

/// Interactive showcase screen demonstrating Phase 1 UI Design System and Animation components.
class DesignSystemGalleryScreen extends StatefulWidget {
  const DesignSystemGalleryScreen({super.key});

  @override
  State<DesignSystemGalleryScreen> createState() => _DesignSystemGalleryScreenState();
}

class _DesignSystemGalleryScreenState extends State<DesignSystemGalleryScreen> {
  bool _isExpanded = false;
  double _priceCounterValue = 2400.0;
  AppStatusType _toggleStatus = AppStatusType.pending;
  int _selectedChipIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Design System & UI Components',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('1. Colors & Design Tokens'),
            _buildColorPalette(),

            const SizedBox(height: AppSpacing.xxl),
            _buildSectionHeader('2. Status Badges & Chips'),
            _buildBadgesAndChips(),

            const SizedBox(height: AppSpacing.xxl),
            _buildSectionHeader('3. Typography & Price Displays'),
            _buildPriceDisplays(),

            const SizedBox(height: AppSpacing.xxl),
            _buildSectionHeader('4. Buttons & Interactive Controls'),
            _buildButtonsSection(),

            const SizedBox(height: AppSpacing.xxl),
            _buildSectionHeader('5. Input Fields & Dropdowns'),
            _buildInputsSection(),

            const SizedBox(height: AppSpacing.xxl),
            _buildSectionHeader('6. Reusable Card Suite'),
            _buildCardsSection(),

            const SizedBox(height: AppSpacing.xxl),
            _buildSectionHeader('7. Dialogs & Snackbars'),
            _buildDialogsSection(context),

            const SizedBox(height: AppSpacing.xxl),
            _buildSectionHeader('8. Animation System'),
            _buildAnimationsSection(),

            const SizedBox(height: AppSpacing.xxl),
            _buildSectionHeader('9. Loading, Empty & Error States'),
            _buildStatesSection(),

            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildColorPalette() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _colorSwatch('Primary', AppColors.primary),
        _colorSwatch('Primary Light', AppColors.primaryLight, textColor: AppColors.primaryDark),
        _colorSwatch('Secondary', AppColors.secondary),
        _colorSwatch('Net Realization', AppColors.netRealizationBadge),
        _colorSwatch('Success', AppColors.success),
        _colorSwatch('Warning', AppColors.warning),
        _colorSwatch('Error', AppColors.error),
      ],
    );
  }

  Widget _colorSwatch(String label, Color color, {Color textColor = Colors.white}) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.borderMd,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildBadgesAndChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppStatusBadge(type: AppStatusType.pending),
            AppStatusBadge(type: AppStatusType.accepted),
            AppStatusBadge(type: AppStatusType.rejected),
            AppStatusBadge(type: AppStatusType.expired),
            AppStatusBadge(type: AppStatusType.inTransit),
            AppStatusBadge(type: AppStatusType.completed),
            AppStatusBadge(type: AppStatusType.active),
            AppStatusBadge(type: AppStatusType.draft),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            AppChip(
              label: 'Wheat (गेहूं)',
              isSelected: _selectedChipIndex == 0,
              icon: Icons.eco,
              onTap: () => setState(() => _selectedChipIndex = 0),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'Cotton (कपास)',
              isSelected: _selectedChipIndex == 1,
              icon: Icons.eco,
              onTap: () => setState(() => _selectedChipIndex = 1),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: 'Grade A',
              isSelected: _selectedChipIndex == 2,
              onTap: () => setState(() => _selectedChipIndex = 2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceDisplays() {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asking Price (Price Trend Up):', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
          AppPriceText(price: 2650, trend: PriceTrend.up),
          SizedBox(height: AppSpacing.md),
          Text('Net Realization Price:', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
          AppPriceText(price: 2420, isNetRealization: true),
        ],
      ),
    );
  }

  Widget _buildButtonsSection() {
    return Column(
      children: [
        AppButton(
          label: 'Primary Action Button',
          onPressed: () {},
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Secondary Action Button',
          style: AppButtonStyle.secondary,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Outlined Button',
          style: AppButtonStyle.outlined,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.sm),
        const AppButton(
          label: 'Loading Button',
          isLoading: true,
        ),
      ],
    );
  }

  Widget _buildInputsSection() {
    return const Column(
      children: [
        AppSearchField(),
        SizedBox(height: AppSpacing.md),
        AppCurrencyField(label: 'Expected Price per Quintal'),
        SizedBox(height: AppSpacing.md),
        AppTextField(label: 'Farm / Village Location', hint: 'Enter village or mandi district'),
        SizedBox(height: AppSpacing.md),
        AppDropdownFormField<String>(
          label: 'Crop Quality Grade',
          hint: 'Select grade',
          items: [
            DropdownMenuItem(value: 'A', child: Text('Grade A (Premium)')),
            DropdownMenuItem(value: 'B', child: Text('Grade B (Standard)')),
          ],
        ),
      ],
    );
  }

  Widget _buildCardsSection() {
    return const Column(
      children: [
        ProduceCard(
          cropName: 'Sharbati Wheat (गेहूं)',
          grade: 'Grade A',
          quantity: '50 Quintals',
          askingPrice: 2600,
          netRealizationPrice: 2450,
          location: 'Anand, Gujarat',
          farmerName: 'Ramesh Patel',
        ),
        SizedBox(height: AppSpacing.md),
        BuyerRequirementCard(
          cropNeeded: 'Basmati Rice',
          targetQuantity: '200 Quintals',
          targetPrice: 3800,
          location: 'Ahmedabad Mandi',
          companyName: 'Agro Exports India',
        ),
        SizedBox(height: AppSpacing.md),
        OfferCard(
          cropName: 'Cotton (कपास)',
          buyerName: 'Jayesh Traders',
          offerPrice: 6200,
          quantity: '30 Quintals',
          status: AppStatusType.pending,
          expiresText: 'Expires in 04h 12m',
        ),
        SizedBox(height: AppSpacing.md),
        TransactionCard(
          orderId: 'FL-9821',
          cropName: 'Yellow Mustard',
          tradeDate: '12 Sep 2026',
          grossAmount: 125000,
          netPayout: 118400,
          status: AppStatusType.inTransit,
        ),
      ],
    );
  }

  Widget _buildDialogsSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Test Dialog',
            style: AppButtonStyle.outlined,
            onPressed: () {
              AppDialogs.showConfirmDialog(
                context: context,
                title: 'Confirm Deal Counter',
                message: 'Are you sure you want to submit a counter-offer of ₹ 2,550 / quintal?',
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppButton(
            label: 'Test Snackbar',
            onPressed: () {
              AppSnackBar.show(
                context,
                message: 'Offer accepted successfully!',
                type: SnackBarType.success,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnimationsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('1. Interactive Micro Press:', style: TextStyle(fontWeight: FontWeight.w600)),
              AnimatedPressable(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: AppRadius.borderMd),
                  child: const Text('Tap Me', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('2. Animated Price Counter:', style: TextStyle(fontWeight: FontWeight.w600)),
              AnimatedPriceCounter(
                value: _priceCounterValue,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.priceHighlight),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                onPressed: () {
                  setState(() {
                    _priceCounterValue += 100;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('3. Animated Status Switcher:', style: TextStyle(fontWeight: FontWeight.w600)),
              AnimatedStatusSwitcher(
                child: AppStatusBadge(key: ValueKey(_toggleStatus), type: _toggleStatus),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
                onPressed: () {
                  setState(() {
                    _toggleStatus = _toggleStatus == AppStatusType.pending
                        ? AppStatusType.accepted
                        : AppStatusType.pending;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('4. Expandable Accordion:', style: TextStyle(fontWeight: FontWeight.w600)),
              IconButton(
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.primary),
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
              ),
            ],
          ),
          ExpandableContainer(
            isExpanded: _isExpanded,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.borderSm),
              child: const Text('Accordion breakdown details: Mandi Cess: ₹20, Transport: ₹80, Net Payout: ₹2,400'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5. Success Checkmark:', style: TextStyle(fontWeight: FontWeight.w600)),
              SuccessCheckmarkAnimation(size: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatesSection() {
    return Column(
      children: [
        const Text('Shimmer Skeleton Loader:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        ShimmerLoading.card(height: 100),
        const SizedBox(height: AppSpacing.md),
        const LoadingIndicator(message: 'Fetching latest mandi prices...'),
        const SizedBox(height: AppSpacing.md),
        const AppCard(
          child: EmptyStateWidget(
            title: 'No Active Offers',
            message: 'You have no pending offers for this crop listing.',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const AppCard(
          child: ErrorStateWidget(
            message: 'Unable to connect to Mandi server. Please retry.',
          ),
        ),
      ],
    );
  }
}
