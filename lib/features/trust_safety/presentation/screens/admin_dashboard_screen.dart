import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/trust_safety/presentation/controllers/trust_safety_providers.dart';

/// Admin-only panel: user management, KYC review queue, listing moderation, disputes.
/// Route access is gated to profile.isAdmin in app_router.dart.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'KYC Queue'),
              Tab(text: 'Listings'),
              Tab(text: 'Disputes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AdminUsersTab(),
            _AdminKycTab(),
            _AdminListingsTab(),
            _AdminDisputesTab(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// USERS TAB
// ============================================================
class _AdminUsersTab extends ConsumerStatefulWidget {
  const _AdminUsersTab();

  @override
  ConsumerState<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<_AdminUsersTab> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(adminControllerProvider.notifier).fetchUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSetStatus(String userId, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${newStatus[0].toUpperCase()}${newStatus.substring(1)} this account?'),
        content: Text('This will set the account status to "$newStatus" and notify the user.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref.read(adminControllerProvider.notifier).setAccountStatus(userId, newStatus);
    if (!mounted) return;
    if (ok) AppSnackBar.show(context, message: 'Account status updated.', type: SnackBarType.success);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppTextField(
            label: 'Search by name, phone, or company',
            controller: _searchController,
            prefixIcon: const Icon(Icons.search_rounded),
            onChanged: (v) => ref.read(adminControllerProvider.notifier).fetchUsers(search: v),
          ),
        ),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.users.isEmpty
                  ? const EmptyStateWidget(icon: Icons.people_outline, title: 'No users found', message: '')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xxxl),
                      itemCount: state.users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final user = state.users[index];
                        final isBanned = user.accountStatus == 'banned';
                        final isSuspended = user.accountStatus == 'suspended';
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (isBanned
                                              ? colorScheme.error
                                              : isSuspended
                                                  ? Colors.orange
                                                  : Colors.green)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      user.accountStatus.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isBanned
                                            ? colorScheme.error
                                            : isSuspended
                                                ? Colors.orange
                                                : Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${user.role?.value ?? 'unknown'} • ${user.phone ?? 'no phone'} • KYC: ${user.kycStatus}',
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  if (user.accountStatus != 'active')
                                    Expanded(
                                      child: AppButton(
                                        label: 'Reactivate',
                                        style: AppButtonStyle.outlined,
                                        onPressed: () => _confirmAndSetStatus(user.id, 'active'),
                                      ),
                                    ),
                                  if (user.accountStatus != 'suspended') ...[
                                    if (user.accountStatus != 'active') const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: AppButton(
                                        label: 'Suspend',
                                        style: AppButtonStyle.outlined,
                                        onPressed: () => _confirmAndSetStatus(user.id, 'suspended'),
                                      ),
                                    ),
                                  ],
                                  if (!isBanned) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: AppButton(
                                        label: 'Ban',
                                        style: AppButtonStyle.outlined,
                                        onPressed: () => _confirmAndSetStatus(user.id, 'banned'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ============================================================
// KYC QUEUE TAB
// ============================================================
class _AdminKycTab extends ConsumerStatefulWidget {
  const _AdminKycTab();

  @override
  ConsumerState<_AdminKycTab> createState() => _AdminKycTabState();
}

class _AdminKycTabState extends ConsumerState<_AdminKycTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(adminControllerProvider.notifier).fetchKycQueue());
  }

  Future<void> _reject(String documentId) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Reject')),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final ok = await ref.read(adminControllerProvider.notifier).reviewKyc(documentId, 'rejected', rejectionReason: reason);
    if (!mounted) return;
    if (ok) AppSnackBar.show(context, message: 'Document rejected.', type: SnackBarType.info);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.kycQueue.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.verified_user_outlined,
        title: 'KYC queue is empty',
        message: 'No documents are currently pending review.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
      itemCount: state.kycQueue.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final doc = state.kycQueue[index];
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doc.userName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${doc.documentType.toUpperCase()} • ${doc.documentNumber} • ${doc.userRole ?? ''}',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Verify',
                      icon: Icons.check_rounded,
                      onPressed: () async {
                        final ok = await ref.read(adminControllerProvider.notifier).reviewKyc(doc.id, 'verified');
                        if (ok && context.mounted) {
                          AppSnackBar.show(context, message: 'Document verified.', type: SnackBarType.success);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Reject',
                      style: AppButtonStyle.outlined,
                      icon: Icons.close_rounded,
                      onPressed: () => _reject(doc.id),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// LISTINGS TAB
// ============================================================
class _AdminListingsTab extends ConsumerStatefulWidget {
  const _AdminListingsTab();

  @override
  ConsumerState<_AdminListingsTab> createState() => _AdminListingsTabState();
}

class _AdminListingsTabState extends ConsumerState<_AdminListingsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(adminControllerProvider.notifier).fetchListings());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.listings.isEmpty) {
      return const EmptyStateWidget(icon: Icons.inventory_2_outlined, title: 'No listings', message: '');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
      itemCount: state.listings.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final p = state.listings[index];
        final isFlagged = p.moderationStatus == 'flagged';
        final isRemoved = p.moderationStatus == 'removed';
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isRemoved ? colorScheme.error : (isFlagged ? Colors.orange : Colors.green))
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.moderationStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isRemoved ? colorScheme.error : (isFlagged ? Colors.orange : Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'By ${p.farmerName ?? 'farmer'} • ${p.quantity} ${p.unit} • ₹${p.expectedPrice.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (p.moderationStatus != 'approved')
                    Expanded(
                      child: AppButton(
                        label: 'Approve',
                        style: AppButtonStyle.outlined,
                        onPressed: () => ref.read(adminControllerProvider.notifier).moderateProduce(p.id, 'approved'),
                      ),
                    ),
                  if (p.moderationStatus != 'flagged') ...[
                    if (p.moderationStatus != 'approved') const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: 'Flag',
                        style: AppButtonStyle.outlined,
                        onPressed: () => ref.read(adminControllerProvider.notifier).moderateProduce(p.id, 'flagged'),
                      ),
                    ),
                  ],
                  if (!isRemoved) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: 'Remove',
                        style: AppButtonStyle.outlined,
                        onPressed: () => ref.read(adminControllerProvider.notifier).moderateProduce(p.id, 'removed'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// DISPUTES TAB
// ============================================================
class _AdminDisputesTab extends ConsumerStatefulWidget {
  const _AdminDisputesTab();

  @override
  ConsumerState<_AdminDisputesTab> createState() => _AdminDisputesTabState();
}

class _AdminDisputesTabState extends ConsumerState<_AdminDisputesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(adminControllerProvider.notifier).fetchDisputes());
  }

  Future<void> _resolve(String disputeId, String status) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'resolved' ? 'Resolve Dispute' : 'Dismiss Dispute'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Resolution note (optional)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Confirm')),
        ],
      ),
    );
    if (note == null) return;
    final ok = await ref
        .read(adminControllerProvider.notifier)
        .resolveDispute(disputeId, status, resolutionNote: note.isEmpty ? null : note);
    if (!mounted) return;
    if (ok) AppSnackBar.show(context, message: 'Dispute updated.', type: SnackBarType.success);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.disputes.isEmpty) {
      return const EmptyStateWidget(icon: Icons.shield_outlined, title: 'No disputes', message: '');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
      itemCount: state.disputes.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final d = state.disputes[index];
        final isOpen = d.status == 'open' || d.status == 'investigating';
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(d.type, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Text(d.status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                ],
              ),
              Text(
                'From: ${d.reporterName ?? 'user'}${d.reportedUserName != null ? ' • Against: ${d.reportedUserName}' : ''}',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(d.description),
              if (isOpen) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (d.status == 'open')
                      Expanded(
                        child: AppButton(
                          label: 'Investigate',
                          style: AppButtonStyle.outlined,
                          onPressed: () => _resolve(d.id, 'investigating'),
                        ),
                      ),
                    if (d.status == 'open') const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(label: 'Resolve', onPressed: () => _resolve(d.id, 'resolved')),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: 'Dismiss',
                        style: AppButtonStyle.outlined,
                        onPressed: () => _resolve(d.id, 'dismissed'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
