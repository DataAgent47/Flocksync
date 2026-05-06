import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/building_user.dart';

class UsersService {
  final FirebaseFirestore _firestore;

  UsersService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches all users in a building and applies visibility/sorting rules.
  /// - Managers can see all users (verified and unverified)
  /// - Unverified users can only see management
  /// - All lists are sorted by priority: Building Owner, other managers, residents, unverified
  Stream<List<BuildingUser>> buildingUsersStream({
    required String propertyId,
    required String currentUserId,
    required String currentUserRole,
    required bool currentUserIsVerified,
  }) {
    if (propertyId.trim().isEmpty) {
      return Stream.value(<BuildingUser>[]);
    }

    return _firestore
        .collection('users')
        .where('property_id', isEqualTo: propertyId)
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        final users = <BuildingUser>[];

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final userId = doc.id;
          final role = (data['role'] as String? ?? 'resident').trim();
          final firstName = (data['first_name'] as String? ?? '').trim();
          final lastName = (data['last_name'] as String? ?? '').trim();
          final apartmentNumber = (data['apt_number'] as String? ?? '').trim();
          final photoUrl = (data['photo_url'] as String? ?? '').trim();
          final email = (data['contact_email'] as String? ?? '').trim();
          final phoneNumber = (data['phone'] as String? ?? '').trim();

          if (firstName.isEmpty || lastName.isEmpty) {
            continue;
          }

          final isVerified =
              await _fetchVerificationStatus(userId, propertyId, role);

          // Fetch manager role if applicable
          String? managerRole;
          if (role == 'manager') {
            managerRole = await _fetchManagerRole(userId, propertyId);
          }

          // Apply visibility rules
          final shouldShow = _shouldShowUser(
            userId: userId,
            userRole: role,
            userIsVerified: isVerified,
            currentUserId: currentUserId,
            currentUserRole: currentUserRole,
            currentUserIsVerified: currentUserIsVerified,
          );

          if (!shouldShow) {
            continue;
          }

          users.add(
            BuildingUser(
              userId: userId,
              firstName: firstName,
              lastName: lastName,
              role: role,
              managerRole: managerRole,
              email: email.isEmpty ? null : email,
              phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
              isVerified: isVerified,
              photoUrl: photoUrl,
              apartmentNumber: apartmentNumber,
            ),
          );
        }

        users.sort((a, b) => a.sortPriority.compareTo(b.sortPriority));

        return users;
      } catch (_) {
        // Prevent the stream from closing on errors
        return <BuildingUser>[];
      }
    });
  }

  /// Verify a user
  Future<void> setVerificationStatus({
    required String userId,
    required String propertyId,
    required String role,
    required bool isVerified,
  }) async {
    try {
      final collection = role == 'manager' ? 'managers' : 'residents';
      final docId = '${propertyId}_$userId';
      await _firestore.collection(collection).doc(docId).set({
        'is_verified': isVerified,
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Updates editable profile fields for a user document.
  Future<void> updateUserDetails({
    required String userId,
    required String firstName,
    required String lastName,
    required String apartmentNumber,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'apt_number': apartmentNumber.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Filters the users list based on the selected filter category.
  /// [users] — all visible users (after visibility rules applied)
  /// [filter] — 'all', 'unverified', 'residents', or 'management'
  List<BuildingUser> filterUsers(List<BuildingUser> users, String filter) {
    switch (filter) {
      case 'unverified':
        return users.where((u) => !u.isVerified).toList();
      case 'residents':
        return users
            .where((u) => u.role == 'resident' && u.isVerified)
            .toList();
      case 'management':
        return users
            .where((u) => u.role == 'manager' && u.isVerified)
            .toList();
      case 'all':
      default:
        return users;
    }
  }

  bool _shouldShowUser({
    required String userId,
    required String userRole,
    required bool userIsVerified,
    required String currentUserId,
    required String currentUserRole,
    required bool currentUserIsVerified,
  }) {
    if (userId == currentUserId) {
      return true;
    }
    if (!currentUserIsVerified) {
      return userRole == 'manager' && userIsVerified;
    }
    if (currentUserRole == 'manager') {
      return true;
    }

    return userIsVerified;
  }

  Future<bool> _fetchVerificationStatus(
    String userId,
    String propertyId,
    String role,
  ) async {
    try {
      final collection = role == 'manager' ? 'managers' : 'residents';
      final docId = '${propertyId}_$userId';
      final doc = await _firestore.collection(collection).doc(docId).get();

      if (!doc.exists) {
        return false;
      }

      return doc.data()?['is_verified'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> _fetchManagerRole(String userId, String propertyId) async {
    try {
      final docId = '${propertyId}_$userId';
      final doc = await _firestore.collection('managers').doc(docId).get();

      if (!doc.exists) {
        return null;
      }

      final role = (doc.data()?['manager_role'] as String? ?? '').trim();
      return role.isEmpty ? null : role;
    } catch (e) {
      return null;
    }
  }

}
