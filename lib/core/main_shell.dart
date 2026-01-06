import 'package:bashakhojo/common/widgets/bottom_nav_bar.dart';
import 'package:bashakhojo/screens/home/landlord_home.dart';
import 'package:bashakhojo/screens/home/tenant_home.dart';
import 'package:bashakhojo/screens/inbox/inbox.dart';
import 'package:bashakhojo/screens/profile/profile.dart';
import 'package:bashakhojo/screens/saved/saved.dart';
import 'package:bashakhojo/services/supabase_service.dart';
import 'package:bashakhojo/services/user_role_notifier.dart';
import 'package:bashakhojo/services/user_service.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _isLoading = true;
  final _roleNotifier = UserRoleNotifier();

  @override
  void initState() {
    super.initState();
    _roleNotifier.addListener(_onRoleChanged);
    _loadUserRole();
  }

  @override
  void dispose() {
    _roleNotifier.removeListener(_onRoleChanged);
    super.dispose();
  }

  void _onRoleChanged() {
    if (mounted) {
      setState(() {
        _userRole = _roleNotifier.role;
      });
    }
  }

  Future<void> _loadUserRole() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId != null) {
        final profile = await UserService.getUser(userId);
        if (mounted) {
          final role = profile?['role'] as String?;
          _roleNotifier.setRole(role);
          setState(() {
            _userRole = role;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Widget> get _screens => [
    _userRole == 'landlord'
        ? const LandlordHomeScreen()
        : const TenantHomeScreen(),
    const SavedScreen(),
    const InboxScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo/logo.png', width: 120, height: 120),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _screens),
          Positioned(
            bottom: 15,
            left: 15,
            right: 15,
            child: BottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}
