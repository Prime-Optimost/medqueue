// Admin Users Screen
// User management interface for admins to view and manage all user accounts
// Features: Role-based filtering, user status toggle, account activation/deactivation

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/widgets/error_snackbar.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';

class AdminUsersScreen extends StatefulWidget {
  static const routeName = AppConstants.adminUsersRoute;
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMorePages = true;

  // Filters
  String? _selectedRole;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadUsers({bool reset = true}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _hasMorePages = true;
        _isLoading = true;
      });
    }

    try {
      final result = await context.read<AdminService>().getUsers(
        page: _currentPage,
        limit: _pageSize,
        role: _selectedRole,
      );

      setState(() {
        if (reset) {
          _users = result.users;
        } else {
          _users.addAll(result.users);
        }
        _hasMorePages = _currentPage < result.totalPages;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      ErrorSnackbar.show(context, 'Failed to load users: $e');
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _loadUsers(reset: false);
  }

  void _showRoleFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('All Users'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedRole = null);
              _loadUsers();
            },
          ),
          ListTile(
            title: const Text('Patients'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedRole = AppConstants.rolePatient);
              _loadUsers();
            },
          ),
          ListTile(
            title: const Text('Doctors'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedRole = AppConstants.roleDoctor);
              _loadUsers();
            },
          ),
          ListTile(
            title: const Text('Admins'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedRole = AppConstants.roleAdmin);
              _loadUsers();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(User user) async {
    try {
      await context.read<AdminService>().updateUserStatus(user.id, !user.isActive);
      setState(() {
        user.isActive = !user.isActive;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${user.isActive ? 'activated' : 'deactivated'}')),
      );
    } catch (e) {
      ErrorSnackbar.show(context, 'Failed to update user status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showRoleFilter,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadUsers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active Filters Display
          if (_selectedRole != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  const Text('Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('Role: ${_selectedRole!.toUpperCase()}'),
                    onDeleted: () {
                      setState(() => _selectedRole = null);
                      _loadUsers();
                    },
                  ),
                ],
              ),
            ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _loadUsers(),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _users.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _UserCard(
                              user: _users[index],
                              onStatusToggle: () => _toggleUserStatus(_users[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onStatusToggle;

  const _UserCard({
    required this.user,
    required this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRoleColor(user.role),
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(user.email),
                      if (user.phone.isNotEmpty) Text(user.phone),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.role).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getRoleColor(user.role),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: user.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: user.isActive ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: user.isActive,
                  onChanged: (_) => onStatusToggle(),
                  activeColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Joined: ${user.createdAt.toLocal().toString().split(' ')[0]}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'doctor':
        return Colors.blue;
      case 'patient':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Comments for academic documentation:
// - AdminUsersScreen: Complete user account management interface
// - Role-based filtering with bottom sheet selection
// - User status toggle with immediate visual feedback
// - Infinite scroll pagination for large user bases
// - Active filters display with easy removal
// - Avatar-based user cards with role badges
// - Status indicators for account activation state
// - Empty state handling with user-friendly messages