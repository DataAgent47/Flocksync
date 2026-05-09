import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../../core/theme/flock_theme.dart';
import '../../../core/widgets/flock_message_banner.dart';
import '../controllers/settings_controller.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final String uid;
  final SettingsController controller;

  const ProfileSettingsScreen({
    super.key,
    required this.uid,
    required this.controller,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  static const Set<String> _supportedCountryCodes = {
    'US',
    'MX',
    'GB',
    'FR',
    'DE',
    'IT',
    'ES',
    'NL',
  };

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'US');
  Key _phoneInputKey = const ValueKey('profile_phone_initial');
  // Later add a controller for the URL
  String? _photoUrl;

  bool _hydrated = false;
  bool _isHydrating = false;
  String? _hydrationError;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_hydrateFromDB);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactEmailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _hydrateFromDB() async {
    if (_isHydrating || _hydrated) {
      return;
    }

    setState(() => _isHydrating = true);

    try {
      final profile = await widget.controller.hydrateProfile(widget.uid);
      if (!mounted) {
        return;
      }
      if (profile == null) {
        setState(() {
          _hydrated = true;
          _hydrationError = 'Unable to load profile data.';
        });
        return;
      }

      _setController(_firstNameController, profile.firstName);
      _setController(_lastNameController, profile.lastName);
      _setController(_contactEmailController, profile.contactEmail);
      _photoUrl = (profile.photoUrl).trim();

      final storedPhone = profile.phone.trim();
      if (storedPhone.isNotEmpty) {
        if (storedPhone.startsWith('+')) {
          try {
            final parsed = await PhoneNumber.getRegionInfoFromPhoneNumber(
              storedPhone,
            );
            if (!mounted) {
              return;
            }
            final parsedIso = (parsed.isoCode ?? '').trim().toUpperCase();
            if (_supportedCountryCodes.contains(parsedIso)) {
              _phoneNumber = parsed;
              _phoneInputKey = ValueKey('profile_$storedPhone');
            } else {
              _phoneNumber = PhoneNumber(
                isoCode: 'US',
                phoneNumber: storedPhone,
              );
              _phoneInputKey = ValueKey('profile_phone_us_fallback_$storedPhone');
              _setController(_phoneController, storedPhone);
            }
          } catch (_) {
            _phoneNumber = PhoneNumber(isoCode: 'US', phoneNumber: storedPhone);
            _phoneInputKey = ValueKey('profile_phone_parse_fallback_$storedPhone');
            _setController(_phoneController, storedPhone);
          }
        } else {
          _phoneNumber = PhoneNumber(isoCode: 'US', phoneNumber: storedPhone);
          _phoneInputKey = ValueKey('profile_phone_local_$storedPhone');
          _setController(_phoneController, storedPhone);
        }
      }

      setState(() {
        _hydrated = true;
        _hydrationError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _hydrated = true;
        _hydrationError = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _isHydrating = false);
      }
    }
  }

  void _setController(TextEditingController controller, String value) {
    if (value.trim().isNotEmpty) {
      controller.text = value.trim();
    }
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _statusMessage = null;
      _statusIsError = false;
    });

    final ok = await widget.controller.saveProfile(
      uid: widget.uid,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      contactEmail: _contactEmailController.text,
      phone: _phoneNumber.phoneNumber ?? _phoneController.text,
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      setState(() {
        _statusMessage = 'Profile saved.';
        _statusIsError = false;
      });
    } else {
      setState(() {
        _statusMessage = widget.controller.errorMessage ?? 'Update failed.';
        _statusIsError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Profile Settings')),
          body: _isHydrating && !_hydrated
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_statusMessage != null) ...[
                            FlockMessageBanner(
                              message: _statusMessage!,
                              isError: _statusIsError,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_hydrationError != null) ...[
                            FlockMessageBanner(
                              message: _hydrationError!,
                              isError: true,
                            ),
                            const SizedBox(height: 12),
                          ],
                          const Text(
                            'Your Info',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: FlockColors.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: FlockColors.darkGreen,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 52,
                                    backgroundColor: FlockColors.tan,
                                    backgroundImage: (_photoUrl ?? '').isNotEmpty
                                      ? NetworkImage(_photoUrl!)
                                        : null,
                                    child: (_photoUrl ?? '').isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            size: 52,
                                            color: FlockColors.darkGreen,
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'First name is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Last name is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _contactEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Contact Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Contact email is required.';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          InternationalPhoneNumberInput(
                            key: _phoneInputKey,
                            onInputChanged: (PhoneNumber number) {
                              _phoneNumber = number;
                            },
                            initialValue: _phoneNumber,
                            textFieldController: _phoneController,
                            countries: ['US', 'MX', 'GB', 'FR', 'DE', 'IT', 'ES', 'NL'],
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
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                borderSide: BorderSide(
                                  color: FlockColors.darkGreen,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                                borderSide: BorderSide(
                                  color: FlockColors.darkGreen,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            formatInput: true,
                            validator: (value) => null,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: widget.controller.isLoading
                                ? null
                                : _save,
                            icon: widget.controller.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Save Profile'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
