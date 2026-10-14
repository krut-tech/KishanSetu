/// Aggregate counts shown on the admin panel's Analytics tab.
/// Populated from the `admin_get_dashboard_stats` RPC (admin-only, server-side).
class AdminDashboardStats {
  final int totalUsers;
  final int totalFarmers;
  final int totalBuyers;
  final int activeListings;
  final int flaggedListings;
  final int removedListings;
  final int pendingKyc;
  final int verifiedKyc;
  final int rejectedKyc;
  final int openDisputes;
  final int resolvedDisputes;
  final int suspendedAccounts;
  final int bannedAccounts;
  final int pendingOffers;
  final int acceptedOffers;
  final int rejectedOffers;
  final int cancelledOffers;

  const AdminDashboardStats({
    this.totalUsers = 0,
    this.totalFarmers = 0,
    this.totalBuyers = 0,
    this.activeListings = 0,
    this.flaggedListings = 0,
    this.removedListings = 0,
    this.pendingKyc = 0,
    this.verifiedKyc = 0,
    this.rejectedKyc = 0,
    this.openDisputes = 0,
    this.resolvedDisputes = 0,
    this.suspendedAccounts = 0,
    this.bannedAccounts = 0,
    this.pendingOffers = 0,
    this.acceptedOffers = 0,
    this.rejectedOffers = 0,
    this.cancelledOffers = 0,
  });

  factory AdminDashboardStats.fromMap(Map<String, dynamic> map) {
    int asInt(dynamic v) =>
        v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);
    return AdminDashboardStats(
      totalUsers: asInt(map['total_users']),
      totalFarmers: asInt(map['total_farmers']),
      totalBuyers: asInt(map['total_buyers']),
      activeListings: asInt(map['active_listings']),
      flaggedListings: asInt(map['flagged_listings']),
      removedListings: asInt(map['removed_listings']),
      pendingKyc: asInt(map['pending_kyc']),
      verifiedKyc: asInt(map['verified_kyc']),
      rejectedKyc: asInt(map['rejected_kyc']),
      openDisputes: asInt(map['open_disputes']),
      resolvedDisputes: asInt(map['resolved_disputes']),
      suspendedAccounts: asInt(map['suspended_accounts']),
      bannedAccounts: asInt(map['banned_accounts']),
      pendingOffers: asInt(map['pending_offers']),
      acceptedOffers: asInt(map['accepted_offers']),
      rejectedOffers: asInt(map['rejected_offers']),
      cancelledOffers: asInt(map['cancelled_offers']),
    );
  }
}
