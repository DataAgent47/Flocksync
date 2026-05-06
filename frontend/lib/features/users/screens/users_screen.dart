import 'package:flutter/material.dart';
import 'package:flocksync/core/theme/flock_theme.dart';
import 'package:flocksync/models/building_user.dart';
import '../../settings/services/settings_firestore_service.dart';
import '../services/users_service.dart';
import '../widgets/filter_button.dart';
import '../widgets/user_row.dart';

class UsersScreen extends StatefulWidget {
  final String userId;
  final String buildingId;
  final bool isManagement;

  const UsersScreen({
    super.key,
    required this.userId,
    required this.buildingId,
    required this.isManagement,
  });

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late final UsersService _service;
  late final SettingsFirestoreService _settingsService;
  String _selectedFilter = 'all';

  bool get _canSeeUnverifiedFilter => widget.isManagement;

  void _setFilter(String filter) {
    if (filter == 'unverified' && !_canSeeUnverifiedFilter) {
      return;
    }

    setState(() => _selectedFilter = filter);
  }

  @override
  void initState() {
    super.initState();
    _service = UsersService();
    _settingsService = SettingsFirestoreService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlockColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Users',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: FlockColors.darkGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect with neighbors in your building',
                    style: TextStyle(
                      fontSize: 16,
                      color: FlockColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Filter btns
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        UserFilterButton(
                          label: 'All',
                          isSelected: _selectedFilter == 'all',
                          onTap: () => _setFilter('all'),
                        ),
                        if (_canSeeUnverifiedFilter) ...[
                          const SizedBox(width: 8),
                          UserFilterButton(
                            label: 'Unverified',
                            isSelected: _selectedFilter == 'unverified',
                            onTap: () => _setFilter('unverified'),
                          ),
                        ],
                        const SizedBox(width: 8),
                        UserFilterButton(
                          label: 'Residents',
                          isSelected: _selectedFilter == 'residents',
                          onTap: () => _setFilter('residents'),
                        ),
                        const SizedBox(width: 8),
                        UserFilterButton(
                          label: 'Management',
                          isSelected: _selectedFilter == 'management',
                          onTap: () => _setFilter('management'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Users list
            Expanded(
              child: StreamBuilder<bool?>(
                stream: _settingsService.membershipVerificationStream(
                  uid: widget.userId,
                  propertyId: widget.buildingId,
                  role: widget.isManagement ? 'manager' : 'resident',
                ),
                builder: (context, verificationSnapshot) {
                  if (verificationSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: FlockColors.darkGreen,
                      ),
                    );
                  }

                  if (verificationSnapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error loading users',
                        style: TextStyle(
                          color: FlockColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  final currentUserIsVerified =
                      verificationSnapshot.data ?? false;

                  return StreamBuilder<List<BuildingUser>>(
                    stream: _service.buildingUsersStream(
                      propertyId: widget.buildingId,
                      currentUserId: widget.userId,
                      currentUserRole:
                          widget.isManagement ? 'manager' : 'resident',
                      currentUserIsVerified: currentUserIsVerified,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: FlockColors.darkGreen,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Error loading users',
                            style: TextStyle(
                              color: FlockColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      final allUsers = snapshot.data ?? [];
                      if (_selectedFilter == 'unverified' &&
                          !_canSeeUnverifiedFilter) {
                        _selectedFilter = 'all';
                      }
                      final filteredUsers = _service.filterUsers(
                        allUsers,
                        _selectedFilter,
                      );

                      if (filteredUsers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 48,
                                color: FlockColors.tan,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No users found',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: FlockColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return UserRow(user: user);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
