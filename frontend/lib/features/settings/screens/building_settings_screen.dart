import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/flock_theme.dart';
import '../../../core/widgets/flock_message_banner.dart';
import '../../onboarding/services/maps_service.dart';
import '../controllers/settings_controller.dart';
import '../models/settings_property_info.dart';
import '../models/settings_user_profile.dart';

class BuildingSettingsScreen extends StatefulWidget {
  final String uid;
  final SettingsController controller;

  const BuildingSettingsScreen({
    super.key,
    required this.uid,
    required this.controller,
  });

  @override
  State<BuildingSettingsScreen> createState() => _BuildingSettingsScreenState();
}

class _BuildingSettingsScreenState extends State<BuildingSettingsScreen> {
  String? _statusMessage;
  bool _statusIsError = false;

  Future<void> _rerollInviteCode() async {
    final ok = await widget.controller.rerollInviteCode(uid: widget.uid);
    if (!mounted) {
      return;
    }

    setState(() {
      _statusMessage = ok
          ? (widget.controller.successMessage ?? 'Invite code updated.')
          : (widget.controller.errorMessage ?? 'Could not reroll invite code.');
      _statusIsError = !ok;
    });
  }
  Future<void> _pickVerificationDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        
        setState(() {
          _statusMessage = 'Uploading ${pickedFile.name}...';
          _statusIsError = false;
        });
        
        final ok = await widget.controller.uploadVerificationDocument(
          uid: widget.uid,
          fileBytes: pickedFile.bytes!,
          fileName: pickedFile.name,
        );

        setState(() {
          _statusMessage = ok ? 'Upload successful!' : 'Upload failed.';
          _statusIsError = !ok;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _statusIsError = true;
      });
    }
  }

  TextSpan _verificationMessage({
    required String status,
    required bool isBuildingOwner,
  }) {
    final normalizedStatus = status.toLowerCase().trim();

    // if status is officially verified
    // need to manually set it to verified in firebase console
    if (normalizedStatus == 'verified') {
      return const TextSpan(
        text: 'Verified!',
        style: TextStyle(
          color: FlockColors.darkGreen,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    
    // if status is pending
    if (normalizedStatus == 'pending') {
      return const TextSpan(
        text: 'Pending Review',
        style: TextStyle(
          color: Colors.yellow, // temp color
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // rejected
    if (normalizedStatus == 'rejected') {
      return const TextSpan(
        text: 'Rejected',
        style: TextStyle(
          color: FlockColors.errorRed,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final contactTarget = isBuildingOwner ? 'support' : 'building management';
    return TextSpan(
      style: const TextStyle(
        color: FlockColors.darkGreen,
        fontWeight: FontWeight.w600,
      ),
      children: [
        const TextSpan(
          text: 'Unverified',
          style: TextStyle(
            color: FlockColors.errorRed,
            fontWeight: FontWeight.w700,
          ),
        ),
        const TextSpan(
          text: '. Please upload a document below to verify your account or contact ',
        ),
        TextSpan(text: contactTarget),
        const TextSpan(text: '.'),
      ],
    );
  }

  String _managerRoleLabel(String? roleFromManagerDoc) {
    final normalized = (roleFromManagerDoc ?? '').trim();
    if (normalized.isEmpty) {
      return 'Manager';
    }

    return normalized;
  }

  List<String> _addressLines(SettingsPropertyInfo info) {
    final line2 = [
      info.city,
      info.region,
      info.postalCode,
    ].where((part) => part.trim().isNotEmpty).join(', ').replaceAll(', ,', ',');

    final line3 = info.countryCode.trim().toUpperCase();

    final lines = <String>[];
    if (info.addressLine.trim().isNotEmpty) {
      lines.add(info.addressLine.trim());
    }
    if (line2.trim().isNotEmpty) {
      lines.add(line2.trim());
    }
    if (line3.isNotEmpty) {
      lines.add(line3);
    }

    if (lines.isEmpty && info.displayAddress.trim().isNotEmpty) {
      return info.displayAddress
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
    }

    return lines;
  }

  Widget _infoRow({
    required String label,
    required Object value,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    final valueWidget = value is Widget
        ? value
        : Text(
            value.toString(),
            style: const TextStyle(
              color: FlockColors.darkGreen,
              fontWeight: FontWeight.w600,
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: FlockColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  Widget _mapPreview(SettingsPropertyInfo info) {
    final lat = info.latitude;
    final lon = info.longitude;
    if (lat == null || lon == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: FlockColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FlockColors.divider),
        ),
        child: const Center(
          child: Text(
            'Map location unavailable for this building.',
            style: TextStyle(color: FlockColors.textSecondary),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(initialCenter: LatLng(lat, lon), initialZoom: 16),
          children: [
            TileLayer(
              urlTemplate: MapTileConfig.urlTemplate,
              userAgentPackageName: MapTileConfig.userAgentPackageName,
            ),
            RichAttributionWidget(
              showFlutterMapAttribution: false,
              attributions: [TextSourceAttribution(MapTileConfig.attribution)],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(lat, lon),
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.location_pin,
                    color: FlockColors.darkGreen,
                    size: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _propertySection(
    BuildContext context,
    SettingsUserProfile profile,
    bool isManager,
  ) {
    if (profile.propertyId.isEmpty) {
      return Text(
        'No building is linked to this account yet.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return StreamBuilder<SettingsPropertyInfo?>(
      stream: widget.controller.propertyStream(profile.propertyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final property = snapshot.data;
        if (property == null) {
          return const Text('Building details could not be loaded.');
        }

        final addressLines = _addressLines(property);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Full Address',
                      style: TextStyle(
                        color: FlockColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (addressLines.isEmpty)
                      const Text('Address unavailable')
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: addressLines
                            .map(
                              (line) => Text(
                                line,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 12),
                    _mapPreview(property),
                  ],
                ),
              ),
            ),
            if (isManager) ...[
              const SizedBox(height: 20),
              const Text(
                'Invite Code',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: FlockColors.darkGreen,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
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
                        property.inviteCode.isEmpty
                            ? '--- ---'
                            : property.inviteCode,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
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
                            ClipboardData(
                              text: property.inviteCode.isEmpty
                                  ? '--- ---'
                                  : property.inviteCode,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: widget.controller.isLoading
                      ? null
                      : _rerollInviteCode,
                  icon: widget.controller.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Reroll Invite Code'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Building Settings')),
          backgroundColor: FlockColors.cream,
          body: SafeArea(
            child: StreamBuilder<SettingsUserProfile?>(
              stream: widget.controller.profileStream(widget.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final profile = snapshot.data;
                if (profile == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Could not load account settings.'),
                    ),
                  );
                }

                final isManager = profile.role == 'manager';
                final membershipState = widget.controller
                    .membershipVerificationStream(
                      uid: widget.uid,
                      propertyId: profile.propertyId,
                      role: profile.role,
                    );

                final normalizedStatus = profile.verificationStatus.toLowerCase().trim();
                final isRejected = normalizedStatus == 'rejected';
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    if (_statusMessage != null) ...[
                      FlockMessageBanner(
                        message: _statusMessage!,
                        isError: _statusIsError,
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
                    const SizedBox(height: 10),
                    if (profile.propertyId.isEmpty)
                      _infoRow(
                        label: 'Verification',
                        value: 'No building linked yet.',
                      )
                    else
                      _infoRow(
                        label: 'Verification',
                        value: Text.rich(
                          _verificationMessage(
                            status: profile.verificationStatus,
                            isBuildingOwner: isManager,
                          ),
                        ),
                      ),
                    if (normalizedStatus != 'verified')
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isRejected ? 'Your Document Was Rejected' : 'Upload Proof of Ownership',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: isRejected ? FlockColors.errorRed : null,
                                    ),
                                  ),
                                  Text(
                                    isRejected 
                                      ? 'Your document was not accepted. Please upload a clearer version.' 
                                      : 'ex: Property Tax Document, any official document that contains the address of the building',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: FlockColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filled(
                              onPressed: _pickVerificationDocument,
                              icon: const Icon(Icons.upload_file),
                              tooltip: 'Upload document',
                              style: IconButton.styleFrom(
                                // Button turns red if rejected to get attention
                                backgroundColor: isRejected ? FlockColors.errorRed : FlockColors.darkGreen,
                                foregroundColor: FlockColors.cream,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 18),
                    _infoRow(
                      label: 'Apartment',
                      value: profile.apartmentNumber.trim().isEmpty
                          ? 'Not set'
                          : profile.apartmentNumber,
                    ),
                    const Divider(height: 18),
                    if (isManager && profile.propertyId.isNotEmpty)
                      StreamBuilder<String?>(
                        stream: widget.controller.managerRoleStream(
                          uid: widget.uid,
                          propertyId: profile.propertyId,
                        ),
                        builder: (context, managerSnapshot) {
                          final managerRole = _managerRoleLabel(
                            managerSnapshot.data,
                          );
                          return _infoRow(label: 'Role', value: managerRole);
                        },
                      )
                    else
                      _infoRow(label: 'Role', value: 'Resident'),
                    const SizedBox(height: 8),
                    Card(
                      child: SwitchListTile(
                        title: const Text('Hide apartment number from other residents'),
                        value: profile.hideApartmentNumber,
                        onChanged: widget.controller.isLoading
                            ? null
                            : (val) async {
                                final ok = await widget.controller.setHideApartmentNumber(
                                  uid: widget.uid,
                                  hide: val,
                                );
                                if (!mounted) return;
                                setState(() {
                                  _statusMessage = ok
                                      ? (widget.controller.successMessage ?? '')
                                      : (widget.controller.errorMessage ?? 'Could not update setting.');
                                  _statusIsError = !ok;
                                });
                              },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Building Info',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: FlockColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _propertySection(context, profile, isManager),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
