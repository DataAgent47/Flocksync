class SettingsUserProfile {
  final String firstName;
  final String lastName;
  final String contactEmail;
  final String phone;
  final String role;
  final String apartmentNumber;
  final String propertyId;
  final String photoData;
  final bool hideApartmentNumber;
  final String photoBase64;

  const SettingsUserProfile({
    required this.firstName,
    required this.lastName,
    required this.contactEmail,
    required this.phone,
    required this.role,
    required this.apartmentNumber,
    required this.propertyId,
    required this.photoData,
    required this.hideApartmentNumber,
    required this.photoBase64,
  });

  factory SettingsUserProfile.fromMap(Map<String, dynamic> data) {
    return SettingsUserProfile(
      firstName: (data['first_name'] as String? ?? '').trim(),
      lastName: (data['last_name'] as String? ?? '').trim(),
      contactEmail: (data['contact_email'] as String? ?? '').trim(),
      phone: (data['phone'] as String? ?? '').trim(),
      role: (data['role'] as String? ?? 'resident').trim(),
      apartmentNumber: (data['apt_number'] as String? ?? '').trim(),
      propertyId: (data['property_id'] as String? ?? '').trim(),
      photoData: (
        (data['photo_base64'] as String?) ??
        (data['photo_url'] as String?) ??
        ''
      ).trim(),
      hideApartmentNumber: (data['hide_apt_number'] as bool? ?? false),
      photoBase64: (data['photo_base64'] as String? ?? '').trim()
    );
  }
}
