/// Represents a user in a building
class BuildingUser {
  final String userId;
  final String firstName;
  final String lastName;
  final String role; // 'manager' or 'resident'
  final String? managerRole; // e.g. 'Building Owner', 'Supervisor', etc. (only if manager)
  final String? email;
  final String? phoneNumber;
  final bool isVerified;
  final String photoUrl;
  final String apartmentNumber;

  const BuildingUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.managerRole,
    this.email,
    this.phoneNumber,
    required this.isVerified,
    required this.photoUrl,
    required this.apartmentNumber,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get roleLabel {
    if (role == 'manager' && managerRole != null) {
      return managerRole!;
    }
    return role == 'manager' ? 'Manager' : 'Resident';
  }

  /// Sorting priority for users:
  /// 0: Building Owner
  /// 1: Other managers
  /// 2: Residents (renters)
  /// 3: Unverified users
  int get sortPriority {
    if (!isVerified) {
      return 3;
    }
    if (role != 'manager') {
      return 2;
    }
    if (managerRole == 'Building Owner') {
      return 0;
    }
    return 1;
  }
}
