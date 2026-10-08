import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_bar/app_top_bar.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/dropdowns/app_dropdown.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/trust_safety/presentation/controllers/trust_safety_providers.dart';

/// Lets a farmer/buyer submit an identity document for KYC verification.
class KycSubmissionScreen extends ConsumerStatefulWidget {
  const KycSubmissionScreen({super.key});

  @override
  ConsumerState<KycSubmissionScreen> createState() => _KycSubmissionScreenState();
}

class _KycSubmissionScreenState extends ConsumerState<KycSubmissionScreen> {
  static const Map<String, String> _docTypes = {
    'aadhaar': 'Aadhaar Card',
    'pan': 'PAN Card',
    'voter_id': 'Voter ID',
    'driving_license': 'Driving License',
    'other': 'Other Government ID',
  };

  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _imagePicker = ImagePicker();
  String _docType = 'aadhaar';
  XFile? _photo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authNotifierProvider).profile?.id;
      if (userId != null) {
        ref.read(kycControllerProvider.notifier).fetch(userId);
      }
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null && mounted) setState(() => _photo = picked);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Could not open the photo gallery.', type: SnackBarType.error);
    }
  }

  Future<void> _submit() async {
    final userId = ref.read(authNotifierProvider).profile?.id;
    if (userId == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_photo == null) {
      AppSnackBar.show(context, message: 'Please attach a photo of your document.', type: SnackBarType.error);
      return;
    }

    final ok = await ref.read(kycControllerProvider.notifier).submit(
          userId: userId,
          documentType: _docType,
          documentNumber: _numberController.text.trim(),
          file: File(_photo!.path),
        );
    if (!mounted) return;
    if (ok) {
      AppSnackBar.show(context, message: 'Submitted for verification!', type: SnackBarType.success);
    } else {
      final err = ref.read(kycControllerProvider).errorMessage;
      if (err != null) AppSnackBar.show(context, message: err, type: SnackBarType.error);
    }
  }

  Color _statusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return colorScheme.error;
      case 'pending':
        return Colors.orange;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final doc = state.document;

    return Scaffold(
      appBar: const AppTopBar(title: 'Identity Verification (KYC)'),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (doc != null) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Current Submission',
                                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _statusColor(doc.status, colorScheme).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  doc.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _statusColor(doc.status, colorScheme),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${_docTypes[doc.documentType] ?? doc.documentType} • ${doc.documentNumber}'),
                          if (doc.status == 'rejected' && doc.rejectionReason != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Reason: ${doc.rejectionReason}',
                                style: TextStyle(color: colorScheme.error, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (doc.status == 'verified')
                      Text(
                        'Your identity is verified. No further action needed.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    if (doc.status == 'pending')
                      Text(
                        'Your document is under review. This usually takes 1-2 business days.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                  ],
                  if (doc == null || doc.status == 'rejected') ...[
                    Text(
                      doc == null ? 'Submit a Document' : 'Resubmit a Document',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Verified accounts build trust with buyers and farmers.',
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppDropdownFormField<String>(
                            label: 'Document Type',
                            value: _docType,
                            items: _docTypes.entries
                                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                .toList(),
                            onChanged: (v) => setState(() => _docType = v ?? _docType),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Document Number',
                            controller: _numberController,
                            validator: (v) => (v == null || v.trim().length < 4) ? 'Enter a valid number' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          InkWell(
                            onTap: _pickPhoto,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                border: Border.all(color: colorScheme.outline),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _photo != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(File(_photo!.path), height: 160, fit: BoxFit.cover),
                                    )
                                  : Column(
                                      children: [
                                        Icon(Icons.upload_file_rounded, color: colorScheme.primary, size: 32),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text('Tap to attach a clear photo of your document'),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: 'Submit for Verification',
                            icon: Icons.verified_user_outlined,
                            isLoading: state.isSubmitting,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
