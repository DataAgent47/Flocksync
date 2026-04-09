// This file is a bit temporary, as we may move some logic to the backend
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingPropertyRecord {
  const OnboardingPropertyRecord({
    required this.propertyId,
    required this.data,
  });

  final String propertyId;
  final Map<String, dynamic> data;
}

class OnboardingHydrationData {
  const OnboardingHydrationData({this.userData, this.property});

  final Map<String, dynamic>? userData;
  final OnboardingPropertyRecord? property;
}

class OnboardingPersistResult {
  const OnboardingPersistResult({this.propertyId, this.inviteCode});

  final String? propertyId;
  final String? inviteCode;
}

class OnboardingFirestoreService {
  OnboardingFirestoreService({FirebaseFirestore? firestore, Random? random})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _random = random ?? Random.secure();

  final FirebaseFirestore _firestore;
  final Random _random;

  static const Map<int, String> _stepKeys = {
    1: 'role_selection',
    2: 'resident_welcome',
    3: 'invite_code',
    4: 'address_confirmation',
    5: 'resident_details',
    6: 'resident_completed',
    7: 'resident_request',
    8: 'management_address',
    9: 'management_details',
    10: 'invite_residents',
    11: 'management_completed',
    12: 'management_role_verification',
  };

  String stepKeyFor(int step) {
    return _stepKeys[step] ?? 'unknown';
  }

  int? stepFromKey(String? stepKey) {
    if (stepKey == null) {
      return null;
    }

    for (final entry in _stepKeys.entries) {
      if (entry.value == stepKey) {
        return entry.key;
      }
    }

    return null;
  }

  Future<OnboardingHydrationData> hydrate({
    required String uid,
    String? preferredPropertyId,
  }) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.exists ? userDoc.data() : null;

    var propertyId = preferredPropertyId;
    if ((propertyId == null || propertyId.isEmpty) && userData != null) {
      final onboardingState = userData['onboarding_state'];
      if (onboardingState is Map<String, dynamic>) {
        final remotePropertyId = onboardingState['property_id'];
        if (remotePropertyId is String && remotePropertyId.isNotEmpty) {
          propertyId = remotePropertyId;
        }
      }
    }

    if (propertyId == null || propertyId.isEmpty) {
      return OnboardingHydrationData(userData: userData);
    }

    final propertyDoc = await _firestore
        .collection('properties')
        .doc(propertyId)
        .get();
    if (!propertyDoc.exists) {
      return OnboardingHydrationData(userData: userData);
    }

    return OnboardingHydrationData(
      userData: userData,
      property: OnboardingPropertyRecord(
        propertyId: propertyDoc.id,
        data: propertyDoc.data() ?? <String, dynamic>{},
      ),
    );
  }

  Future<OnboardingPropertyRecord?> findPropertyByInviteCode(
    String inviteCode,
  ) async {
    final normalized = inviteCode.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }

    final matchingProperty = await _firestore
        .collection('properties')
        .where('invite_code', isEqualTo: normalized)
        .limit(1)
        .get();

    if (matchingProperty.docs.isEmpty) {
      return null;
    }

    final snapshot = matchingProperty.docs.first;
    return OnboardingPropertyRecord(
      propertyId: snapshot.id,
      data: snapshot.data(),
    );
  }

  Future<OnboardingPersistResult> saveStepData({
    required String uid,
    required int previousStep,
    required int nextStep,
    required bool isManagement,
    required bool usedInviteCode,
    required String firstName,
    required String lastName,
    required String contactEmail,
    required String fallbackAuthEmail,
    required String phone,
    required String aptNumber,
    required String? selectedManagementRole,
    required String? propertyId,
    required String displayAddress,
    required double? latitude,
    required double? longitude,
    required String? verifiedAddressLine,
    required String? verifiedCity,
    required String? verifiedRegion,
    required String? verifiedPostalCode,
    required String? verifiedCountryCode,
  }) async {
    var activePropertyId = propertyId;
    String? generatedInviteCode;

    if (previousStep == 4 && (nextStep == 5 || nextStep == 9)) {
      final property = await _ensurePropertyExists(
        existingPropertyId: activePropertyId,
        displayAddress: displayAddress,
        latitude: latitude,
        longitude: longitude,
        verifiedAddressLine: verifiedAddressLine,
        verifiedCity: verifiedCity,
        verifiedRegion: verifiedRegion,
        verifiedPostalCode: verifiedPostalCode,
        verifiedCountryCode: verifiedCountryCode,
      );
      activePropertyId = property.propertyId;
      generatedInviteCode = (property.data['invite_code'] as String?)?.trim();
    }

    final usersRef = _firestore.collection('users').doc(uid);
    final existingUser = await usersRef.get();
    final timestamp = FieldValue.serverTimestamp();
    final safeContactEmail = contactEmail.trim().isEmpty
        ? fallbackAuthEmail.trim()
        : contactEmail.trim();

    final userPayload = <String, dynamic>{
      'user_id': uid,
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'contact_email': safeContactEmail,
      'phone': phone.trim(),
      'apt_number': aptNumber.trim().isEmpty ? null : aptNumber.trim(),
      'role': isManagement ? 'manager' : 'resident',
      'onboarding_state': {
        'step': stepKeyFor(nextStep),
        'property_id': activePropertyId,
        'completed': false,
      },
      'updated_at': timestamp,
    };

    if (!existingUser.exists) {
      userPayload['created_at'] = timestamp;
    }

    await usersRef.set(userPayload, SetOptions(merge: true));

    if (nextStep == 6 && activePropertyId != null) {
      await _upsertResident(
        uid: uid,
        propertyId: activePropertyId,
        isVerified: usedInviteCode,
      );
    }

    if (nextStep == 11 && activePropertyId != null) {
      await _upsertManager(
        uid: uid,
        propertyId: activePropertyId,
        managementRole: (selectedManagementRole ?? '').trim(),
      );
    }

    return OnboardingPersistResult(
      propertyId: activePropertyId,
      inviteCode: generatedInviteCode,
    );
  }

  Future<OnboardingPropertyRecord> _ensurePropertyExists({
    required String? existingPropertyId,
    required String displayAddress,
    required double? latitude,
    required double? longitude,
    required String? verifiedAddressLine,
    required String? verifiedCity,
    required String? verifiedRegion,
    required String? verifiedPostalCode,
    required String? verifiedCountryCode,
  }) async {
    if (existingPropertyId != null && existingPropertyId.isNotEmpty) {
      final existingDoc = await _firestore
          .collection('properties')
          .doc(existingPropertyId)
          .get();
      if (existingDoc.exists) {
        return OnboardingPropertyRecord(
          propertyId: existingDoc.id,
          data: existingDoc.data() ?? <String, dynamic>{},
        );
      }
    }

    final normalizedAddress = displayAddress.trim();
    if (normalizedAddress.isEmpty) {
      throw Exception('Please verify your building address first.');
    }

    final existingPropertyByAddress = await _firestore
        .collection('properties')
        .where('address_display_name', isEqualTo: normalizedAddress)
        .limit(1)
        .get();

    if (existingPropertyByAddress.docs.isNotEmpty) {
      final propertyDoc = existingPropertyByAddress.docs.first;
      return OnboardingPropertyRecord(
        propertyId: propertyDoc.id,
        data: propertyDoc.data(),
      );
    }

    final inviteCode = await _generateUniqueInviteCode();
    final addressParts = _splitAddress(normalizedAddress);
    final addressLine = (verifiedAddressLine ?? '').trim().isEmpty
        ? addressParts['address_line']
        : verifiedAddressLine!.trim();
    final city = (verifiedCity ?? '').trim().isEmpty
        ? addressParts['city']
        : verifiedCity!.trim();
    final region = (verifiedRegion ?? '').trim().isEmpty
        ? addressParts['region']
        : verifiedRegion!.trim();
    final postalCode = (verifiedPostalCode ?? '').trim().isEmpty
        ? addressParts['postal_code']
        : verifiedPostalCode!.trim();
    final countryCode = (verifiedCountryCode ?? '').trim().isEmpty
        ? (addressParts['country_code'] ?? '')
        : verifiedCountryCode!.trim().toUpperCase();
    final propertyRef = _firestore.collection('properties').doc();
    final timestamp = FieldValue.serverTimestamp();

    final payload = <String, dynamic>{
      'property_id': propertyRef.id,
      'address_line': addressLine,
      'city': city,
      'region': region,
      'postal_code': postalCode,
      'country_code': countryCode,
      'latitude': latitude,
      'longitude': longitude,
      'address_display_name': normalizedAddress,
      'invite_code': inviteCode,
      'created_at': timestamp,
      'updated_at': timestamp,
    };

    await propertyRef.set(payload);

    return OnboardingPropertyRecord(propertyId: propertyRef.id, data: payload);
  }

  Future<void> _upsertResident({
    required String uid,
    required String propertyId,
    required bool isVerified,
  }) async {
    final docId = '${propertyId}_$uid';
    final residentRef = _firestore.collection('residents').doc(docId);
    final existingResident = await residentRef.get();
    final timestamp = FieldValue.serverTimestamp();

    final payload = <String, dynamic>{
      'resident_id': uid,
      'property_id': propertyId,
      'is_verified': isVerified,
      'verified_at': isVerified ? timestamp : null,
      'updated_at': timestamp,
    };

    if (!existingResident.exists) {
      payload['created_at'] = timestamp;
    }

    await residentRef.set(payload, SetOptions(merge: true));
  }

  Future<void> _upsertManager({
    required String uid,
    required String propertyId,
    required String managementRole,
  }) async {
    final docId = '${propertyId}_$uid';
    final managerRef = _firestore.collection('managers').doc(docId);
    final existingManager = await managerRef.get();
    final timestamp = FieldValue.serverTimestamp();
    final payload = <String, dynamic>{
      'manager_id': uid,
      'property_id': propertyId,
      'manager_role': managementRole,
      'is_verified': false,
      'verified_at': null,
      'updated_at': timestamp,
    };

    if (!existingManager.exists) {
      payload['created_at'] = timestamp;
    }

    await managerRef.set(payload, SetOptions(merge: true));
  }

  Future<String> _generateUniqueInviteCode() async {
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

  Map<String, String> _splitAddress(String address) {
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    final addressLine = parts.isNotEmpty ? parts[0] : '';
    final city = parts.length > 1 ? parts[1] : '';
    var region = '';
    var postalCode = '';
    if (parts.length > 2) {
      final statePostal = parts[2];
      final postalMatch = RegExp(
        r'\b\d{4,10}(?:-\d{4})?\b',
      ).firstMatch(statePostal);
      postalCode = postalMatch?.group(0) ?? '';
      region = statePostal.replaceAll(postalCode, '').trim();
    }

    final countryRaw = parts.length > 3 ? parts.last : '';
    final countryCode = countryRaw.length == 2 ? countryRaw.toUpperCase() : '';

    return {
      'address_line': addressLine,
      'city': city,
      'region': region,
      'postal_code': postalCode,
      'country_code': countryCode,
    };
  }

  Future<void> finalizeOnboarding({required String uid}) async {
    await _firestore.collection('users').doc(uid).update({
      'onboarding_state.completed': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Check if user has completed onboarding (returns a Stream for real-time updates)
  Stream<bool> isOnboardingCompleted(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((
      docSnapshot,
    ) {
      if (!docSnapshot.exists) {
        return false;
      }
      final data = docSnapshot.data();
      final onboardingState =
          data?['onboarding_state'] as Map<String, dynamic>?;
      return onboardingState?['completed'] as bool? ?? false;
    });
  }
}
