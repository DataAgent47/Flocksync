import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _state = 1;
  bool _usedInviteCode = false;

  final _inviteCodeController = TextEditingController();
  final _buildingAddressController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aptController = TextEditingController();
  String? _selectedManagementRole;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _buildingAddressController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _aptController.dispose();
    super.dispose();
  }

  void _goTo(int state) => setState(() => _state = state);

  void _goBack() {
    switch (_state) {
      case 1: // This shouldnt happen
        Navigator.of(context).pop();
      case 2:
        _goTo(1);
      case 3:
        _goTo(2);
      case 4:
        _goTo(_usedInviteCode ? 3 : 7);
      case 5:
        _goTo(4);
      case 6:
        _goTo(5);
      case 7:
        _goTo(2);
      case 8:
        _goTo(1);
      case 9:
        _goTo(8);
      case 10:
        _goTo(9);
      case 11:
        _goTo(10);
      default:
        _goTo(1);
    }
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildState(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // We should add state(s) for errors

  Widget _buildState() {
    return switch (_state) {
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
      _ => _stateRoleSelection(),
    };
  }

  Widget _header({required IconData icon, required String title, String? subtitle}) {
    return Column(
      children: [
        Icon(icon, size: 64, color: AppColors.darkGreen),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.green2),
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
          onPressed: () => _goTo(2),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Resident'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _goTo(8),
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
          onPressed: () {
            _usedInviteCode = true;
            _goTo(3);
          },
          icon: const Icon(Icons.vpn_key_outlined),
          label: const Text('I have an invite code'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            _usedInviteCode = false;
            _goTo(7);
          },
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
        TextField(
          controller: _inviteCodeController,
          decoration: const InputDecoration(
            labelText: 'Invite code',
            prefixIcon: Icon(Icons.vpn_key_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _backButton(),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _goTo(4),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                child: const Text('Enter'),
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
                  const Icon(Icons.location_on, color: AppColors.darkGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '123 Example St, New York, 12345',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Mock map
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.middleground.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.middleground.withAlpha(80)),
                ),
                child: const Center(
                  child: Icon(Icons.map_outlined, size: 48, color: AppColors.green2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _goTo(_usedInviteCode ? 3 : 7),
              icon: const Icon(Icons.arrow_back),
              label: const Text('No'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _goTo(5),
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
        TextField(
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'First Name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _lastNameController,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _aptController,
          decoration: const InputDecoration(
            labelText: 'Apt Number',
            prefixIcon: Icon(Icons.door_front_door_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '*We do not display sensitive information',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.green2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _backButton(),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _goTo(6),
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
    final isInvite = _usedInviteCode;
    return Column(
      key: const ValueKey(6),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          icon: isInvite ? Icons.check_circle_outline : Icons.mark_email_read_outlined,
          title: isInvite ? "You're all set! 👏" : "Request sent to your building!",
        ),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
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
        TextField(
          controller: _buildingAddressController,
          decoration: const InputDecoration(
            labelText: 'Building address',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _backButton(),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _goTo(4),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Enter'),
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
        TextField(
          controller: _buildingAddressController,
          decoration: const InputDecoration(
            labelText: 'Building address',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _backButton(),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _goTo(9),
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
        TextField(
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'First Name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _lastNameController,
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
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _aptController,
          decoration: const InputDecoration(
            labelText: 'Apt Number',
            prefixIcon: Icon(Icons.door_front_door_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '*We do not display sensitive information',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.green2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _backButton(),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _goTo(10),
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
        // Mock invite code
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
                  'FLK-ABC123',
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
                      const ClipboardData(text: 'FLK-ABC123'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Mock QR
        Center(
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.middleground),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.qr_code_2, size: 120, color: AppColors.darkGreen),
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
                onPressed: () => _goTo(11),
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
        _header(
          icon: Icons.check_circle_outline,
          title: "You're all set! 👏",
        ),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
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
}
