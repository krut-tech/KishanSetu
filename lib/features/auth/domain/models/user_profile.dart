import 'package:equatable/equatable.dart';
import 'package:farmer_market_app/features/auth/domain/models/user_role.dart';

/// User Profile domain model mapping Supabase profiles table.
class UserProfile extends Equatable {
  final String id;
  final UserRole? role;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String language;

  // Farmer details
  final String? state;
  final String? district;
  final String? village;
  final double? landSizeAcres;
  final String? primaryCrop;

  // Buyer details
  final String? companyName;
  final String? gstNumber;
  final String? businessType;
  final double? buyingCapacityQuintals;

  final bool isProfileComplete;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    this.role,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.language = 'en',
    this.state,
    this.district,
    this.village,
    this.landSizeAcres,
    this.primaryCrop,
    this.companyName,
    this.gstNumber,
    this.businessType,
    this.buyingCapacityQuintals,
    this.isProfileComplete = false,
    this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      role: UserRole.fromString(map['role'] as String?),
      fullName: (map['full_name'] as String?) ?? '',
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      language: (map['language'] as String?) ?? 'en',
      state: map['state'] as String?,
      district: map['district'] as String?,
      village: map['village'] as String?,
      landSizeAcres: map['land_size_acres'] != null
          ? (map['land_size_acres'] as num).toDouble()
          : null,
      primaryCrop: map['primary_crop'] as String?,
      companyName: map['company_name'] as String?,
      gstNumber: map['gst_number'] as String?,
      businessType: map['business_type'] as String?,
      buyingCapacityQuintals: map['buying_capacity_quintals'] != null
          ? (map['buying_capacity_quintals'] as num).toDouble()
          : null,
      isProfileComplete: (map['is_profile_complete'] as bool?) ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role?.value,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'language': language,
      'state': state,
      'district': district,
      'village': village,
      'land_size_acres': landSizeAcres,
      'primary_crop': primaryCrop,
      'company_name': companyName,
      'gst_number': gstNumber,
      'business_type': businessType,
      'buying_capacity_quintals': buyingCapacityQuintals,
      'is_profile_complete': isProfileComplete,
    };
  }

  UserProfile copyWith({
    String? id,
    UserRole? role,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? language,
    String? state,
    String? district,
    String? village,
    double? landSizeAcres,
    String? primaryCrop,
    String? companyName,
    String? gstNumber,
    String? businessType,
    double? buyingCapacityQuintals,
    bool? isProfileComplete,
  }) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      language: language ?? this.language,
      state: state ?? this.state,
      district: district ?? this.district,
      village: village ?? this.village,
      landSizeAcres: landSizeAcres ?? this.landSizeAcres,
      primaryCrop: primaryCrop ?? this.primaryCrop,
      companyName: companyName ?? this.companyName,
      gstNumber: gstNumber ?? this.gstNumber,
      businessType: businessType ?? this.businessType,
      buyingCapacityQuintals: buyingCapacityQuintals ?? this.buyingCapacityQuintals,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        role,
        fullName,
        phone,
        avatarUrl,
        language,
        state,
        district,
        village,
        landSizeAcres,
        primaryCrop,
        companyName,
        gstNumber,
        businessType,
        buyingCapacityQuintals,
        isProfileComplete,
      ];
}
