import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/settings_property_info.dart';
import '../models/settings_user_profile.dart';

class SettingsFirestoreService {
  final FirebaseFirestore _firestore;
  final Random _random;

  SettingsFirestoreService({FirebaseFirestore? firestore, Random? random})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _random = random ?? Random.secure();

  Stream<SettingsUserProfile?> profileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return SettingsUserProfile.fromMap(data);
    });
  }

  Future<SettingsUserProfile?> hydrateProfile(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final data = userDoc.data();
    if (data == null) {
      return null;
    }
    return SettingsUserProfile.fromMap(data);
  }

  Stream<SettingsPropertyInfo?> propertyStream(String propertyId) {
    final trimmedPropertyId = propertyId.trim();
    if (trimmedPropertyId.isEmpty) {
      return Stream<SettingsPropertyInfo?>.value(null);
    }

    return _firestore
        .collection('properties')
        .doc(trimmedPropertyId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (data == null) {
            return null;
          }
          return SettingsPropertyInfo.fromMap(doc.id, data);
        });
  }

  Future<SettingsPropertyInfo?> hydrateProperty(String propertyId) async {
    final trimmedPropertyId = propertyId.trim();
    if (trimmedPropertyId.isEmpty) {
      return null;
    }

    final propertyDoc = await _firestore
        .collection('properties')
        .doc(trimmedPropertyId)
        .get();
    final data = propertyDoc.data();
    if (data == null) {
      return null;
    }

    return SettingsPropertyInfo.fromMap(propertyDoc.id, data);
  }

  Stream<String?> managerRoleStream({
    required String uid,
    required String propertyId,
  }) {
    final trimmedPropertyId = propertyId.trim();
    if (trimmedPropertyId.isEmpty) {
      return Stream<String?>.value(null);
    }

    final docId = '${trimmedPropertyId}_$uid';
    return _firestore.collection('managers').doc(docId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return null;
      }

      final role = (data['manager_role'] as String? ?? '').trim();
      return role.isEmpty ? null : role;
    });
  }

  Stream<bool?> membershipVerificationStream({
    required String uid,
    required String propertyId,
    required String role,
  }) {
    final trimmedPropertyId = propertyId.trim();
    if (trimmedPropertyId.isEmpty) {
      return Stream<bool?>.value(null);
    }

    final isManager = role.trim() == 'manager';
    final collection = isManager ? 'managers' : 'residents';
    final docId = '${trimmedPropertyId}_$uid';

    return _firestore.collection(collection).doc(docId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return data['is_verified'] as bool?;
    });
  }

  Future<String> rerollInviteCode({required String uid}) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    final role = (userData['role'] as String? ?? '').trim();
    final propertyId = (userData['property_id'] as String? ?? '').trim();

    if (role != 'manager') {
      throw Exception('Only managers can reroll invite codes.');
    }
    if (propertyId.isEmpty) {
      throw Exception('No building is linked to this account.');
    }

    final inviteCode = await _generateUniqueInviteCode();
    await _firestore.collection('properties').doc(propertyId).set({
      'invite_code': inviteCode,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return inviteCode;
  }

  Future<void> updateProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String contactEmail,
    required String phone,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'contact_email': contactEmail.trim(),
      'phone': phone.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateContactEmail({
    required String uid,
    required String contactEmail,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'contact_email': contactEmail.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteAccountData(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    final userDoc = await userRef.get();
    final userData = userDoc.data() ?? <String, dynamic>{};

    // keep all documents so that we can delete all at once
    final refsToDelete = <DocumentReference>{};

    final role = (userData['role'] as String? ?? '').trim();
    final propertyId = (userData['property_id'] as String? ?? '').trim();

    if (propertyId.isNotEmpty) {
      if (role == 'manager') {
        refsToDelete.add(
          _firestore.collection('managers').doc('${propertyId}_$uid'),
        );
      } else {
        refsToDelete.add(
          _firestore.collection('residents').doc('${propertyId}_$uid'),
        );
      }
    }

    // Also remove any stale memberships in case a user switched role/property.
    final residentsQuery = await _firestore
        .collection('residents')
        .where('resident_id', isEqualTo: uid)
        .get();
    for (final doc in residentsQuery.docs) {
      refsToDelete.add(doc.reference);
    }
    final managersQuery = await _firestore
        .collection('managers')
        .where('manager_id', isEqualTo: uid)
        .get();
    for (final doc in managersQuery.docs) {
      refsToDelete.add(doc.reference);
    }

    refsToDelete.add(userRef);

    final batch = _firestore.batch();
    for (final ref in refsToDelete) {
      batch.delete(ref);
    }
    await batch.commit();
  }

  Future<String> _generateUniqueInviteCode() async {
    // generate unique invite code
    for (var i = 0; i < 8; i++) {
      final code = _generateInviteCode();
      final existing = await _firestore
          .collection('properties')
          .where('invite_code', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        return code;
      }
    }

    throw Exception('Unable to generate a unique invite code. Please retry.');
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    String chunk() {
      return List.generate(
        3,
        (_) => chars[_random.nextInt(chars.length)],
      ).join();
    }

    return '${chunk()}-${chunk()}';
  }
}
