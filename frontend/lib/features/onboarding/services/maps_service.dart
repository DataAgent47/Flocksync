import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MapTileConfig {
  static const urlTemplate = String.fromEnvironment(
    'MAP_TILE_URL_TEMPLATE',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static const attribution = String.fromEnvironment(
    'MAP_TILE_ATTRIBUTION',
    defaultValue: 'OpenStreetMap',
  );

  static const userAgentPackageName = String.fromEnvironment(
    'MAP_TILE_USER_AGENT_PACKAGE',
    defaultValue: 'com.flocksync.frontend',
  );
}

class AddressSuggestion {
  final String displayName;
  final double latitude;
  final double longitude;

  const AddressSuggestion({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    final displayName = (json['display_name'] as String?)?.trim() ?? '';
    final lat = double.tryParse(json['lat']?.toString() ?? '');
    final lon = double.tryParse(json['lon']?.toString() ?? '');

    if (displayName.isEmpty || lat == null || lon == null) {
      throw const MapsServiceException('Could not parse address.');
    }

    return AddressSuggestion(
      displayName: displayName,
      latitude: lat,
      longitude: lon,
    );
  }
}

class VerifiedAddress {
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String? addressLine;
  final String? city;
  final String? region;
  final String? postalCode;
  final String? countryCode;

  const VerifiedAddress({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.addressLine,
    this.city,
    this.region,
    this.postalCode,
    this.countryCode,
  });
}

class MapsServiceException implements Exception {
  final String message;

  const MapsServiceException(this.message);

  @override
  String toString() => message;
}

class MapsService {
  MapsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = String.fromEnvironment(
    'BACKEND_API_URL',
    defaultValue: 'http://localhost:5000',
  );
  static const _timeout = Duration(seconds: 10);

  Future<List<AddressSuggestion>> autocompleteAddress(
    String query, {
    int limit = 5,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) {
      return const [];
    }

    final uri = Uri.parse(
      '$_baseUrl/api/maps/autocomplete',
    ).replace(queryParameters: {'q': trimmed, 'limit': '$limit'});

    final response = await _get(uri);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const MapsServiceException('Unexpected map service response.');
    }

    final suggestions = decoded['suggestions'];
    if (suggestions is! List) {
      throw const MapsServiceException('Unexpected map service response.');
    }

    final results = <AddressSuggestion>[];
    for (final item in suggestions) {
      if (item is Map<String, dynamic>) {
        try {
          results.add(
            AddressSuggestion(
              displayName: (item['displayName'] as String?)?.trim() ?? '',
              latitude:
                  double.tryParse(item['latitude']?.toString() ?? '') ?? 0,
              longitude:
                  double.tryParse(item['longitude']?.toString() ?? '') ?? 0,
            ),
          );
        } on MapsServiceException {
          // Skip malformed result rows.
        }
      }
    }

    return results;
  }

  Future<VerifiedAddress> verifyAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      throw const MapsServiceException('Building address is required.');
    }

    final uri = Uri.parse(
      '$_baseUrl/api/maps/verify',
    ).replace(queryParameters: {'address': trimmed});

    final response = await _get(uri);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const MapsServiceException('Unexpected map service response.');
    }

    final verifiedAddress = decoded['verifiedAddress'];
    if (verifiedAddress is! Map<String, dynamic>) {
      throw const MapsServiceException(
        'We could not verify that address. Please choose a suggestion or refine it.',
      );
    }

    return VerifiedAddress(
      formattedAddress:
          (verifiedAddress['formattedAddress'] as String?)?.trim() ?? '',
      latitude:
          double.tryParse(verifiedAddress['latitude']?.toString() ?? '') ?? 0,
      longitude:
          double.tryParse(verifiedAddress['longitude']?.toString() ?? '') ?? 0,
      addressLine: (verifiedAddress['addressLine'] as String?)?.trim(),
      city: (verifiedAddress['city'] as String?)?.trim(),
      region: (verifiedAddress['region'] as String?)?.trim(),
      postalCode: (verifiedAddress['postalCode'] as String?)?.trim(),
      countryCode: (verifiedAddress['countryCode'] as String?)?.trim(),
    );
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['error'] is String) {
          throw MapsServiceException(decoded['error'] as String);
        }

        throw MapsServiceException(
          'Map service returned ${response.statusCode}. Please try again.',
        );
      }

      return response;
    } on MapsServiceException {
      rethrow;
    } catch (_) {
      throw const MapsServiceException(
        'Unable to reach map service. Check your connection and try again.',
      );
    }
  }
}

class AddressLookupController extends ChangeNotifier {
  AddressLookupController({MapsService? mapsService})
    : _mapsService = mapsService ?? MapsService();

  final MapsService _mapsService;

  Timer? _debounce;
  String _latestQuery = '';
  List<AddressSuggestion> _suggestions = const [];
  VerifiedAddress? _verifiedAddress;
  bool _isLoadingSuggestions = false;
  bool _isVerifying = false;
  String? _lookupError;

  List<AddressSuggestion> get suggestions => _suggestions;
  VerifiedAddress? get verifiedAddress => _verifiedAddress;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  bool get isVerifying => _isVerifying;
  String? get lookupError => _lookupError;

  void onAddressChanged(String value) {
    _latestQuery = value;
    _verifiedAddress = null;
    _lookupError = null;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadSuggestions(value);
    });
  }

  void selectSuggestion(AddressSuggestion suggestion) {
    _debounce?.cancel();
    _suggestions = const [];
    _lookupError = null;
    _verifiedAddress = VerifiedAddress(
      formattedAddress: suggestion.displayName,
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
    );
    notifyListeners();
  }

  Future<VerifiedAddress?> verifyAddressInput(String rawAddress) async {
    _isVerifying = true;
    _lookupError = null;
    _suggestions = const [];
    notifyListeners();

    try {
      final verified = await _mapsService.verifyAddress(rawAddress);
      _verifiedAddress = verified;
      return verified;
    } on MapsServiceException catch (error) {
      _lookupError = error.message;
      return null;
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  Future<void> _loadSuggestions(String query) async {
    if (query.trim().length < 3) {
      _suggestions = const [];
      _isLoadingSuggestions = false;
      notifyListeners();
      return;
    }

    _isLoadingSuggestions = true;
    notifyListeners();

    try {
      final loadedSuggestions = await _mapsService.autocompleteAddress(query);
      if (query.trim().toLowerCase() != _latestQuery.trim().toLowerCase()) {
        return;
      }
      _suggestions = loadedSuggestions;
    } on MapsServiceException catch (error) {
      _lookupError = error.message;
    } finally {
      _isLoadingSuggestions = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
