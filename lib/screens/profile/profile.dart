import 'dart:io';

import 'package:bashakhojo/common/widgets/custom_snackbar.dart';
import 'package:bashakhojo/services/supabase_service.dart';
import 'package:bashakhojo/services/user_role_notifier.dart';
import 'package:bashakhojo/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLandlordMode = false;
  String? userId = SupabaseService.client.auth.currentUser?.id;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    Map<String, dynamic>? profile = await UserService.getUser(userId!);

    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLandlordMode = profile?['role'] == 'landlord';
        _isLoading = false;
      });
    }
  }

  Future<void> _changeRole(bool isLandlord) async {
    String newRole;
    if (isLandlord) {
      newRole = 'landlord';
    } else {
      newRole = 'tenant';
    }

    setState(() {
      _isLandlordMode = isLandlord;
    });

    try {
      await UserService.updateRole(newRole);
      UserRoleNotifier().setRole(newRole);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLandlordMode = !isLandlord;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change role: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _changeAvatar() async {
    ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      return;
    }

    final File file = File(image.path);
    String ext = image.name.split('.').last.toLowerCase();
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    String fileName = '${userId}_$timestamp.$ext';

    try {
      await SupabaseService.client.storage
          .from("avatars")
          .upload(
            fileName,
            file,
            fileOptions: FileOptions(cacheControl: '3600', upsert: true),
          );
      final String publicUrl = SupabaseService.client.storage
          .from("avatars")
          .getPublicUrl(fileName);
      await UserService.updateAvatar(publicUrl);
      if (mounted) {
        String oldFileName = _userProfile?['avatar_url'].split('/').last;
        await SupabaseService.client.storage.from("avatars").remove([
          oldFileName,
        ]);
        setState(() {
          _userProfile?['avatar_url'] =
              '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        });
        CustomSnackbar.show(
          context,
          'Avatar updated successfully!',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context, 'Error occurred: ${e.toString()}');
      }
    }
  }

  Future<void> _logOut() async {
    try {
      await SupabaseService.client.auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log out: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colorScheme, textTheme),
            _buildBody(colorScheme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profile',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          _buildHeaderButton(context, Icons.settings_outlined, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildAvatar(colorScheme),
            const SizedBox(height: 16),
            _buildUserInfo(colorScheme, textTheme),
            const SizedBox(height: 32),
            _buildLandlordModeCard(colorScheme, textTheme),
            const SizedBox(height: 24),
            _buildMenuItems(colorScheme, textTheme),
            const SizedBox(height: 32),
            _buildLogoutButton(colorScheme),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    String? avatarUrl = _userProfile?['avatar_url'];

    return Stack(
      children: [
        Container(
          width: 128,
          height: 128,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 4),
              image: avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl == null
                ? Icon(
                    Icons.person,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: colorScheme.primary,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              onTap: _changeAvatar,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.edit, size: 18, color: colorScheme.onPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(ColorScheme colorScheme, TextTheme textTheme) {
    String fullName = _userProfile?['full_name'] ?? 'User';
    String email = SupabaseService.client.auth.currentUser?.email ?? '';

    return Column(
      children: [
        Text(
          fullName,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLandlordModeCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Landlord Mode",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Switch to manage properties",
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isLandlordMode,
            activeColor: colorScheme.primary,
            onChanged: _changeRole,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        _buildMenuItem(context, Icons.calendar_month, "My Bookings"),
        const SizedBox(height: 12),
        _buildMenuItem(context, Icons.favorite_border, "Saved Homes"),
        const SizedBox(height: 12),
        _buildMenuItem(context, Icons.credit_card, "Payments"),
        const SizedBox(height: 12),
        _buildMenuItem(context, Icons.help_outline, "Help & Support"),
      ],
    );
  }

  Widget _buildLogoutButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {
          _logOut();
        },
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.error,
          backgroundColor: colorScheme.error.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: BorderSide(color: colorScheme.error.withValues(alpha: 0.2)),
          ),
        ),
        icon: const Icon(Icons.logout),
        label: const Text(
          "Log Out",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeaderButton(
    BuildContext context,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(icon, color: colorScheme.onSurface),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
