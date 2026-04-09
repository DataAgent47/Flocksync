import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/flock_theme.dart';
import '../services/maps_service.dart';
import '../services/onboarding_firestore_service.dart';
import '../services/onboarding_flow_state.dart';

class OnboardingScreen extends StatefulWidget {
  final User? user;

  const OnboardingScreen({super.key, this.user});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  OnboardingFlowState _flow = const OnboardingFlowState();
  final OnboardingFirestoreService _onboardingStore =
      OnboardingFirestoreService();

  final _inviteCodeController = TextEditingController();
  final _buildingAddressController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _aptController = TextEditingController();

  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'US');
  Key _phoneInputKey = const ValueKey('phone_initial');

  final _inviteCodeFormKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();
  final _residentDetailsFormKey = GlobalKey<FormState>();
  final _managementDetailsFormKey = GlobalKey<FormState>();
  late final AddressLookupController _addressLookup;

  String? _selectedManagementRole;
  bool _managementRoleVerified = false;
  String? _activePropertyId;
  String? _activeInviteCode;
  bool _isSyncingStep = false;
  bool _isSubmittingInviteCode = false;

  @override
  void initState() {
    super.initState();
    _addressLookup = AddressLookupController()
      ..addListener(_handleAddressLookupChanged);
    _prefillName(widget.user);
    Future<void>.microtask(_hydrateFromDB);
  }

  void _handleAddressLookupChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _prefillName(User? user) {
    if (user == null) return;

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      final nameParts = displayName
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();

      if (_firstNameController.text.isEmpty && nameParts.isNotEmpty) {
        _firstNameController.text = nameParts.first;
      }

      if (_lastNameController.text.isEmpty && nameParts.length > 1) {
        _lastNameController.text = nameParts.sublist(1).join(' ');
      }
    }
  }

  @override
  void dispose() {
    _addressLookup
      ..removeListener(_handleAddressLookupChanged)
      ..dispose();
    _inviteCodeController.dispose();
    _buildingAddressController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _contactEmailController.dispose();
    _aptController.dispose();
    super.dispose();
  }

  void _updateFlow(OnboardingFlowState nextFlow) {
    final previousFlow = _flow;
    setState(() {
      _flow = OnboardingFlowState(
        step: nextFlow.step,
        usedInviteCode: nextFlow.usedInviteCode,
        isManagement: nextFlow.isManagement,
      );
    });
    _syncTransition(previousFlow, nextFlow);
  }

  Future<void> _syncTransition(
    OnboardingFlowState previousFlow,
    OnboardingFlowState nextFlow,
  ) async {
    if (_isSyncingStep) {
      return;
    }

    if (mounted) {
      setState(() => _isSyncingStep = true);
    } else {
      _isSyncingStep = true;
    }
    try {
      _clearFlowError();
      await _saveStepData(
        previousFlow: previousFlow,
        nextFlow: nextFlow,
      ).timeout(const Duration(seconds: 12));
      await _hydrateFromDB().timeout(const Duration(seconds: 12));
    } on TimeoutException {
      _setFlowError(
        'Request timed out. Please check your connection and try again.',
      );
    } catch (error) {
      _setFlowError(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isSyncingStep = false);
      } else {
        _isSyncingStep = false;
      }
    }
  }

  Future<void> _hydrateFromDB() async {
    final uid = widget.user?.uid;
    if (uid == null) {
      return;
    }

    try {
      final hydrated = await _onboardingStore.hydrate(
        uid: uid,
        preferredPropertyId: _activePropertyId,
      );
      if (!mounted) {
        return;
      }

      final data = hydrated.userData;
      if (data != null) {
        _setController(_firstNameController, data['first_name']);
        _setController(_lastNameController, data['last_name']);
        final storedPhone = data['phone'] as String?;
        if (storedPhone != null && storedPhone.isNotEmpty) {
          if (storedPhone.startsWith('+')) {
            try {
              final parsed = await PhoneNumber.getRegionInfoFromPhoneNumber(storedPhone);
              setState(() {
                _phoneNumber = parsed;
                _phoneInputKey = ValueKey(storedPhone);
              });
            } catch (_) {
              _setController(_phoneController, storedPhone);
            }
          } else {
            _setController(_phoneController, storedPhone);
          }
        }
        _setController(_contactEmailController, data['contact_email']);
        _setController(_aptController, data['apt_number']);

        final role = data['role'] as String?;
        if (role == 'manager' && !_flow.isManagement) {
          setState(() {
            _flow = OnboardingFlowState(
              step: _flow.step,
              usedInviteCode: _flow.usedInviteCode,
              isManagement: true,
              errorMessage: _flow.errorMessage,
            );
          });
        }

        final onboardingState = data['onboarding_state'];
        if (onboardingState is Map<String, dynamic>) {
          final propertyId = onboardingState['property_id'] as String?;
          if (propertyId != null && propertyId.isNotEmpty) {
            _activePropertyId = propertyId;
          }

          final remoteStepKey = onboardingState['step'] as String?;
          final remoteStep = _onboardingStore.stepFromKey(remoteStepKey);
          if (remoteStep != null && remoteStep != _flow.step) {
            setState(() {
              _flow = OnboardingFlowState(
                step: remoteStep,
                usedInviteCode: _flow.usedInviteCode,
                isManagement: _flow.isManagement,
                errorMessage: _flow.errorMessage,
              );
            });
          }
        }
      }

      final property = hydrated.property;
      if (property != null) {
        _applyPropertyData(property.propertyId, property.data);
      }
    } catch (error) {
      _setFlowError(_friendlyError(error));
    }
  }

  // Mark onboarding as complete at final state
  Future<void> _finalizeOnboarding() async {
    final uid = widget.user?.uid;
    if (uid == null) return;
    await _onboardingStore.finalizeOnboarding(uid: uid);
  }

  Future<void> _saveStepData({
    required OnboardingFlowState previousFlow,
    required OnboardingFlowState nextFlow,
  }) async {
    final uid = widget.user?.uid;
    if (uid == null) {
      throw Exception('You must be signed in to continue onboarding.');
    }

    final persist = await _onboardingStore.saveStepData(
      uid: uid,
      previousStep: previousFlow.step,
      nextStep: nextFlow.step,
      isManagement: nextFlow.isManagement,
      usedInviteCode: nextFlow.usedInviteCode,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      contactEmail: _contactEmailController.text,
      fallbackAuthEmail: widget.user?.email ?? '',
      phone: _phoneNumber.phoneNumber ?? _phoneController.text,
      aptNumber: _aptController.text,
      selectedManagementRole: _selectedManagementRole,
      propertyId: _activePropertyId,
      displayAddress: _buildingAddressController.text,
      latitude: _addressLookup.verifiedAddress?.latitude,
      longitude: _addressLookup.verifiedAddress?.longitude,
      verifiedAddressLine: _addressLookup.verifiedAddress?.addressLine,
      verifiedCity: _addressLookup.verifiedAddress?.city,
      verifiedRegion: _addressLookup.verifiedAddress?.region,
      verifiedPostalCode: _addressLookup.verifiedAddress?.postalCode,
      verifiedCountryCode: _addressLookup.verifiedAddress?.countryCode,
    );

    if (persist.propertyId != null && persist.propertyId!.isNotEmpty) {
      _activePropertyId = persist.propertyId;
    }

    if (persist.inviteCode != null && persist.inviteCode!.isNotEmpty) {
      _activeInviteCode = persist.inviteCode;
      _inviteCodeController.text = persist.inviteCode!;
    }
  }

  void _applyPropertyData(String propertyId, Map<String, dynamic> data) {
    _activePropertyId = propertyId;
    final display = (data['address_display_name'] as String?)?.trim() ?? '';
    if (display.isNotEmpty) {
      _buildingAddressController.text = display;
    }

    final inviteCode = (data['invite_code'] as String?)?.trim() ?? '';
    if (inviteCode.isNotEmpty) {
      _activeInviteCode = inviteCode;
      _inviteCodeController.text = inviteCode;
    }

    final lat = (data['latitude'] as num?)?.toDouble();
    final lon = (data['longitude'] as num?)?.toDouble();
    if (display.isNotEmpty && lat != null && lon != null) {
      _addressLookup.selectSuggestion(
        AddressSuggestion(displayName: display, latitude: lat, longitude: lon),
      );
    }
  }

  void _setController(TextEditingController controller, dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      controller.text = value.trim();
    }
  }

  String _friendlyError(Object error) {
    if (error is FirebaseException) {
      return error.message ?? 'A Firebase error occurred. Please try again.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  void _setFlowError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _flow = OnboardingFlowState(
        step: _flow.step,
        usedInviteCode: _flow.usedInviteCode,
        isManagement: _flow.isManagement,
        errorMessage: message,
      );
    });
  }

  void _clearFlowError() {
    if (!mounted || _flow.errorMessage == null) {
      return;
    }

    setState(() {
      _flow = OnboardingFlowState(
        step: _flow.step,
        usedInviteCode: _flow.usedInviteCode,
        isManagement: _flow.isManagement,
      );
    });
  }

  // Helper functions for address state transitions
  Future<void> _submitAddress({required int nextStep}) async {
    final isValid = _addressFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final verified = await _addressLookup.verifyAddressInput(
      _buildingAddressController.text,
    );
    if (!mounted) {
      return;
    }

    if (verified == null) {
      if (_addressLookup.lookupError != null) {
        _setFlowError(_addressLookup.lookupError!);
      }
      return;
    }

    _buildingAddressController.text = verified.formattedAddress;
    _updateFlow(_flow.goTo(nextStep));
  }

  void _selectAddressSuggestion(AddressSuggestion suggestion) {
    _buildingAddressController.text = suggestion.displayName;
    _addressLookup.selectSuggestion(suggestion);
  }

  Widget _addressSuggestionsList() {
    if (_addressLookup.isLoadingSuggestions) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_addressLookup.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: AppColors.middleground.withAlpha(28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.middleground.withAlpha(95)),
      ),
      child: Column(
        children: _addressLookup.suggestions
            .map(
              (suggestion) => ListTile(
                dense: true,
                leading: const Icon(Icons.location_on_outlined),
                title: Text(
                  suggestion.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _selectAddressSuggestion(suggestion),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _submitInviteCode({required int nextStep}) async {
    final isValid = _inviteCodeFormKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final inviteCode = _inviteCodeController.text.trim().toUpperCase();
    _inviteCodeController.text = inviteCode;

    setState(() => _isSubmittingInviteCode = true);
    try {
      final property = await _onboardingStore
          .findPropertyByInviteCode(inviteCode)
          .timeout(const Duration(seconds: 10));

      if (property == null) {
        _setFlowError('Invite code not found. Please check and try again.');
        return;
      }

      _applyPropertyData(property.propertyId, property.data);
      _updateFlow(_flow.goTo(nextStep));
    } on TimeoutException {
      _setFlowError('Invite code check timed out. Please try again.');
    } catch (error) {
      _setFlowError(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmittingInviteCode = false);
      } else {
        _isSubmittingInviteCode = false;
      }
    }
  }

  void _goBack() {
    if (_flow.step == 1) {
      Navigator.of(context).pop();
      return;
    }

    _updateFlow(_flow.goBack());
  }

  Widget _backButton({bool showLabel = true}) {
    return OutlinedButton.icon(
      onPressed: _goBack,
      icon: const Icon(Icons.arrow_back),
      label: showLabel ? const Text('Back') : const SizedBox.shrink(),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_flow.errorMessage != null)
                    _errorBanner(_flow.errorMessage!),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildState(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // We should add state(s) for errors

  Widget _buildState() {
    return switch (_flow.step) {
      1 => _stateRoleSelection(),
      2 => _stateResidentWelcome(),
      3 => _stateInviteCode(),
      4 => _stateAddressConfirmation(),
      5 => _stateResidentDetails(),
      6 => _stateCompleted(),
      7 => _stateResidentRequest(),
      8 => _stateManagementAddress(),
      9 => _stateManagementDetails(),
      10 => _stateInviteResidents(),
      11 => _stateManagementCompleted(),
      12 => _stateManagementRoleVerification(),
      _ => _stateRoleSelection(),
    };
  }

  Widget _errorBanner(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            const Color(0x26C62828),
            AppColors.background,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color.alphaBlend(
              const Color(0x66C62828),
              AppColors.middleground,
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.darkGreen,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, size: 64, color: AppColors.darkGreen),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.green2),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  // State 1: Select Role
  Widget _stateRoleSelection() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: Icons.waving_hand_outlined,
          title: "Let's get started",
          subtitle: 'Select your role to continue',
        ),
        FilledButton.icon(
          onPressed: () => _updateFlow(_flow.startResident()),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Resident'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _updateFlow(_flow.startManagement()),
          icon: const Icon(Icons.business_outlined),
          label: const Text('Management'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  // State 2: Welcome
  Widget _stateResidentWelcome() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: Icons.celebration_outlined,
          title: "We're so happy you're here!",
          subtitle: 'How will you be joining?',
        ),
        FilledButton.icon(
          onPressed: () => _updateFlow(_flow.state3Invite(true, 3)),
          icon: const Icon(Icons.vpn_key_outlined),
          label: const Text('I have an invite code'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _updateFlow(_flow.state3Invite(false, 7)),
          icon: const Icon(Icons.send_outlined),
          label: const Text('Resident Request'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        _backButton(),
      ],
    );
  }

  // State 3: Enter Invite Code
  Widget _stateInviteCode() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: Icons.link_outlined,
          title: "Let's get you connected",
          subtitle: 'Enter the invite code you received',
        ),
        Form(
          key: _inviteCodeFormKey,
          child: TextFormField(
            controller: _inviteCodeController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Invite code is required';
              }
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Invite code',
              prefixIcon: Icon(Icons.vpn_key_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _backButton(),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: (_isSyncingStep || _isSubmittingInviteCode)
                    ? null
                    : () => _submitInviteCode(nextStep: 4),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
                child: (_isSyncingStep || _isSubmittingInviteCode)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enter'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // State 4: Confirm Address
  Widget _stateAddressConfirmation() {
    return Column(
      key: const ValueKey(4),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: Icons.location_on_outlined,
          title: 'Is this your address?',
        ),
        // Mock address card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.middleground.withAlpha(40),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.middleground),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.darkGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildingAddressController.text.trim(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_addressLookup.verifiedAddress != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          _addressLookup.verifiedAddress!.latitude,
                          _addressLookup.verifiedAddress!.longitude,
                        ),
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: MapTileConfig.urlTemplate,
                          userAgentPackageName:
                              MapTileConfig.userAgentPackageName,
                        ),
                        RichAttributionWidget(
                          showFlutterMapAttribution: false,
                          attributions: [
                            TextSourceAttribution(MapTileConfig.attribution),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _addressLookup.verifiedAddress!.latitude,
                                _addressLookup.verifiedAddress!.longitude,
                              ),
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.location_pin,
                                color: AppColors.darkGreen,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.middleground.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.middleground.withAlpha(80),
                    ),
                  ),
                  child: const Center(child: Text('Address not verified yet')),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _updateFlow(
                _flow.goTo(
                  _flow.isManagement ? 8 : (_flow.usedInviteCode ? 3 : 7),
                ),
              ),
              icon: const Icon(Icons.arrow_back),
              label: const Text('No'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () =>
                    _updateFlow(_flow.goTo(_flow.isManagement ? 9 : 5)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Yes'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // State 5: Enter User Details
  Widget _stateResidentDetails() {
    return Column(
      key: const ValueKey(5),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: Icons.person_outline,
          title: "Let's get some details filled in",
        ),
        Form(
          key: _residentDetailsFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First Name is required';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last Name is required';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InternationalPhoneNumberInput(
                key: _phoneInputKey,
                onInputChanged: (PhoneNumber number) {
                  _phoneNumber = number;
                },
                initialValue: _phoneNumber,
                textFieldController: _phoneController,
                countries: ['US', 'CA', 'MX', 'GB', 'FR', 'DE', 'IT', 'ES', 'NL'],
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.DIALOG,
                  useEmoji: true,
                  showFlags: true,
                  leadingPadding: 12,
                  setSelectorButtonAsPrefixIcon: true,
                  trailingSpace: false
                ),
                inputDecoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: FlockColors.darkGreen, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: FlockColors.darkGreen, width: 1.5),
                  ),
                ),
                keyboardType: TextInputType.phone,
                formatInput: true,
                validator: (value) => null,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contactEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Contact Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _aptController,
                decoration: const InputDecoration(
                  labelText: 'Apartment Number',
                  prefixIcon: Icon(Icons.door_front_door_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '*We do not display sensitive information',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.green2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _backButton(),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  final isValid =
                      _residentDetailsFormKey.currentState?.validate() ?? false;
                  if (!isValid) {
                    return;
                  }

                  _updateFlow(_flow.goTo(6));
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // State 6: Complete Resident Onboarding
  Widget _stateCompleted() {
    final isInvite = _flow.usedInviteCode;
    return Column(
      key: const ValueKey(6),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: isInvite
              ? Icons.check_circle_outline
              : Icons.mark_email_read_outlined,
          title: isInvite
              ? "You're all set! 👏"
              : "Request sent to your building!",
        ),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _finalizeOnboarding,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Go to Dashboard'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper function for states 7 and 8
  Widget _addressEntryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Form(
          key: _addressFormKey,
          child: TextFormField(
            controller: _buildingAddressController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: _addressLookup.onAddressChanged,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Building address is required.';
              }
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Building address',
              prefixIcon: Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        _addressSuggestionsList(),
        if (_addressLookup.lookupError != null) ...[
          const SizedBox(height: 8),
          Text(
            _addressLookup.lookupError!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
          ),
        ],
      ],
    );
  }

  // State 7: Resident Request using Address
  Widget _stateResidentRequest() {
    return Column(
      key: const ValueKey(7),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: Icons.link_outlined,
          title: "Let's get you connected",
          subtitle: 'Enter your building address',
        ),
        _addressEntryForm(),
        const SizedBox(height: 24),
        Row(
          children: [
            _backButton(),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _addressLookup.isVerifying
                    ? null
                    : () => _submitAddress(nextStep: 4),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _addressLookup.isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enter'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // State 8: Management
  Widget _stateManagementAddress() {
    return Column(
      key: const ValueKey(8),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: Icons.business_outlined,
          title: 'Management Onboarding',
          subtitle: 'Enter your building address',
        ),
        _addressEntryForm(),
        const SizedBox(height: 24),
        Row(
          children: [
            _backButton(),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _addressLookup.isVerifying
                    ? null
                    : () => _submitAddress(nextStep: 4),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _addressLookup.isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // State 9: Management Details
  Widget _stateManagementDetails() {
    const roles = [
      'Building Owner',
      'Superintendant',
      'Porter',
      'Doorman',
      'Building Manager',
    ];

    return Column(
      key: const ValueKey(9),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: Icons.person_outline,
          title: "Let's get some details filled in",
        ),
        Form(
          key: _managementDetailsFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First Name is required';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last Name is required';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedManagementRole,
                decoration: const InputDecoration(
                  labelText: 'Select your role',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                items: roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedManagementRole = v),
              ),
              const SizedBox(height: 16),
              InternationalPhoneNumberInput(
                key: _phoneInputKey,
                onInputChanged: (PhoneNumber number) {
                  _phoneNumber = number;
                },
                initialValue: _phoneNumber,
                textFieldController: _phoneController,
                countries: ['US', 'CA', 'MX', 'GB', 'FR', 'DE', 'IT', 'ES', 'NL'],
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.DIALOG,
                  useEmoji: true,
                  showFlags: true,
                  leadingPadding: 12,
                  setSelectorButtonAsPrefixIcon: true,
                  trailingSpace: false,
                ),
                inputDecoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: FlockColors.darkGreen, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: FlockColors.darkGreen, width: 1.5),
                  ),
                ),
                keyboardType: TextInputType.phone,
                formatInput: true,
                validator: (value) => null,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contactEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Contact Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _aptController,
                decoration: const InputDecoration(
                  labelText: 'Apartment Number',
                  prefixIcon: Icon(Icons.door_front_door_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '*We do not display sensitive information',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.green2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _backButton(),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  final isValid =
                      _managementDetailsFormKey.currentState?.validate() ??
                      false;
                  if (!isValid) {
                    return;
                  }

                  final needsVerification =
                      _selectedManagementRole == 'Building Owner' ||
                      _selectedManagementRole == 'Superintendant';
                  _updateFlow(_flow.goTo(needsVerification ? 12 : 10));
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // State 10: Invite Residents as Management
  Widget _stateInviteResidents() {
    return Column(
      key: const ValueKey(10),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: Icons.group_add_outlined,
          title: 'Invite residents',
          subtitle: 'Share this code with your residents',
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.middleground.withAlpha(40),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.middleground),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _activeInviteCode ?? '--- ---',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Copy code',
                  icon: const Icon(Icons.content_copy),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _activeInviteCode ?? '--- ---'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.middleground.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.middleground),
            ),
            child: QrImageView(
              data: _activeInviteCode ?? '',
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.transparent,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.darkGreen,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.darkGreen,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _backButton(),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _updateFlow(_flow.goTo(11)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // State 11: Complete Management Onboarding
  Widget _stateManagementCompleted() {
    return Column(
      key: const ValueKey(11),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(icon: Icons.check_circle_outline, title: "You're all set! 👏"),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _finalizeOnboarding,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Go to Dashboard'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // State 12: Management Role Verification
  Widget _stateManagementRoleVerification() {
    final role = _selectedManagementRole;

    return Column(
      key: const ValueKey(12),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: Icons.verified_user_outlined,
          title: 'Management Verification',
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.middleground.withAlpha(40),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.middleground),
          ),
          child: Text(
            'Please provide proof of your role as "$role". Some examples include: tax records, utility bills.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        // Later add file or image uploads
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _managementRoleVerified,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('I confirm this info is accurate.'),
          onChanged: (value) {
            setState(() {
              _managementRoleVerified = value ?? false;
            });
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _backButton(),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _managementRoleVerified
                    ? () {
                        _updateFlow(_flow.goTo(10));
                        setState(() {
                          _managementRoleVerified = false;
                        });
                      }
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
