import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_bar/app_top_bar.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/dropdowns/app_dropdown.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/trust_safety/domain/models/dispute_model.dart';
import 'package:farmer_market_app/features/trust_safety/presentation/controllers/trust_safety_providers.dart';

/// Lets a user file a report/dispute, and shows their own filed reports.
class ReportDisputeScreen extends ConsumerStatefulWidget {
  /// Optional pre-fill when reporting a specific user/order/offer (e.g. from
  /// a produce details or order screen). All optional.
  final String? reportedUserId;
  final String? relatedOrderId;
  final String? relatedOfferId;

  const ReportDisputeScreen({
    super.key,
    this.reportedUserId,
    this.relatedOrderId,
    this.relatedOfferId,
  });

  @override
  ConsumerState<ReportDisputeScreen> createState() => _ReportDisputeScreenState();
}

class _ReportDisputeScreenState extends ConsumerState<ReportDisputeScreen> {
  static const Map<String, String> _types = {
    'quality_issue': 'Produce Quality Issue',
    'payment_issue': 'Payment Issue',
    'no_show': 'No-Show / Missed Delivery',
    'fraud': 'Suspected Fraud',
    'harassment': 'Harassment / Abuse',
    'other': 'Other',
  };

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _type = 'quality_issue';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authNotifierProvider).profile?.id;
      if (userId != null) {
        ref.read(disputeControllerProvider.notifier).fetch(userId);
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = ref.read(authNotifierProvider).profile?.id;
    if (userId == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final dispute = DisputeModel(
      id: '',
      reporterId: userId,
      reportedUserId: widget.reportedUserId,
      relatedOrderId: widget.relatedOrderId,
      relatedOfferId: widget.relatedOfferId,
      type: _type,
      description: _descriptionController.text.trim(),
    );
    final ok = await ref.read(disputeControllerProvider.notifier).file(dispute);
    if (!mounted) return;
    if (ok) {
      _descriptionController.clear();
      AppSnackBar.show(context, message: 'Report submitted.', type: SnackBarType.success);
    } else {
      final err = ref.read(disputeControllerProvider).errorMessage;
      if (err != null) AppSnackBar.show(context, message: err, type: SnackBarType.error);
    }
  }

  Color _statusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return colorScheme.onSurfaceVariant;
      case 'investigating':
        return Colors.orange;
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(disputeControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const AppTopBar(title: 'Report an Issue'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDropdownFormField<String>(
                    label: 'Issue Type',
                    value: _type,
                    items: _types.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Describe what happened',
                    controller: _descriptionController,
                    maxLines: 4,
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? 'Please describe the issue (min 10 characters)'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Submit Report',
                    icon: Icons.flag_outlined,
                    isLoading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Your Reports',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (state.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (state.myDisputes.isEmpty)
              const EmptyStateWidget(
                icon: Icons.shield_outlined,
                title: 'No reports filed',
                message: 'Reports you file will show up here with their status.',
              )
            else
              ...state.myDisputes.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(_types[d.type] ?? d.type, style: const TextStyle(fontWeight: FontWeight.bold))),
                              Text(
                                d.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _statusColor(d.status, colorScheme),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(d.description, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          if (d.resolutionNote != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Resolution: ${d.resolutionNote}',
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
