/// User role enum defining Farmer vs Buyer capabilities.
enum UserRole {
  farmer,
  buyer;

  String get value {
    switch (this) {
      case UserRole.farmer:
        return 'farmer';
      case UserRole.buyer:
        return 'buyer';
    }
  }

  static UserRole? fromString(String? val) {
    if (val == 'farmer') return UserRole.farmer;
    if (val == 'buyer') return UserRole.buyer;
    return null;
  }
}
