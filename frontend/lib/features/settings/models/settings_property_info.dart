class SettingsPropertyInfo {
  final String propertyId;
  final String displayAddress;
  final String addressLine;
  final String city;
  final String region;
  final String postalCode;
  final String countryCode;
  final double? latitude;
  final double? longitude;
  final String inviteCode;

  const SettingsPropertyInfo({
    required this.propertyId,
    required this.displayAddress,
    required this.addressLine,
    required this.city,
    required this.region,
    required this.postalCode,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.inviteCode,
  });

  factory SettingsPropertyInfo.fromMap(
    String propertyId,
    Map<String, dynamic> data,
  ) {
    return SettingsPropertyInfo(
      propertyId: propertyId,
      displayAddress: (data['address_display_name'] as String? ?? '').trim(),
      addressLine: (data['address_line'] as String? ?? '').trim(),
      city: (data['city'] as String? ?? '').trim(),
      region: (data['region'] as String? ?? '').trim(),
      postalCode: (data['postal_code'] as String? ?? '').trim(),
      countryCode: (data['country_code'] as String? ?? '').trim(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      inviteCode: (data['invite_code'] as String? ?? '').trim(),
    );
  }
}
