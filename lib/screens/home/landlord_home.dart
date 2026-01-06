import 'package:bashakhojo/common/components/landlord_property_card.dart';
import 'package:bashakhojo/screens/add_property/add_property.dart';
import 'package:bashakhojo/screens/home/tenant_home.dart';
import 'package:bashakhojo/services/property_service.dart';
import 'package:bashakhojo/services/supabase_service.dart';
import 'package:bashakhojo/services/user_service.dart';
import 'package:flutter/material.dart';

class LandlordHomeScreen extends StatefulWidget {
  const LandlordHomeScreen({super.key});

  @override
  State<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen> {
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;
  String? _userName;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadProperties(), _loadUserProfile()]);
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final profile = await UserService.getUser(userId);
      if (mounted && profile != null) {
        setState(() {
          _userName = profile['full_name'] ?? 'User';
          _profileImageUrl = profile['avatar_url'];
        });
      }
    } catch (e) {
      // fail for profile loading
    }
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final properties = await PropertyService.getPropertiesByOwner(userId);
      if (mounted) {
        setState(() {
          _properties = properties;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onAddProperty() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
    );
    if (result == true) {
      _loadProperties();
    }
  }

  void _onEditProperty(String propertyId) {
    // TODO: Navigate to edit property screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit property feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: _onAddProperty,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 8,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topPadding + 16)),
            // App Bar
            SliverToBoxAdapter(
              child: _LandlordAppBar(
                colorScheme: colorScheme,
                textTheme: textTheme,
                userName: _userName,
                profileImageUrl: _profileImageUrl,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Stats Section
            SliverToBoxAdapter(
              child: _StatsSection(
                colorScheme: colorScheme,
                textTheme: textTheme,
                totalProperties: _properties.length,
                availableCount: _properties
                    .where((p) => p['is_available'] == true)
                    .length,
                rentedCount: _properties
                    .where((p) => p['is_available'] == false)
                    .length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Properties',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_properties.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_properties.length}',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Properties List
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_properties.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyState(
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  onAddProperty: _onAddProperty,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: _properties.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final property = _properties[index];
                    final images =
                        (property['images'] as List?)?.cast<String>() ?? [];

                    return LandlordPropertyCard(
                      property: PropertyData(
                        id: property['id'],
                        title: property['title'] ?? '',
                        category: property['category'] ?? '',
                        price:
                            '৳${property['price']?.toStringAsFixed(0) ?? '0'}',
                        location: property['address'] ?? property['city'] ?? '',
                        imageUrl: images.isNotEmpty
                            ? images[0]
                            : 'https://placehold.co/600x400/e6e6e6/png',
                        bedroomCount: property['bedroom_count'],
                        bathroomCount: property['bathroom_count'],
                        amenities: (property['amenities'] as List?)
                            ?.cast<String>(),
                        description: property['description'],
                        images: images,
                        ownerId: property['owner_id'],
                        isAvailable: property['is_available'] ?? true,
                      ),
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      onDeleted: _loadProperties,
                      onEdit: () => _onEditProperty(property['id']),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _LandlordAppBar extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String? userName;
  final String? profileImageUrl;

  const _LandlordAppBar({
    required this.colorScheme,
    required this.textTheme,
    this.userName,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Profile Image
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withAlpha(60),
                        width: 2,
                      ),
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: ClipOval(
                      child: profileImageUrl != null
                          ? Image.network(
                              profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              color: colorScheme.onSurfaceVariant,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello,",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Noto Sans Bengali',
                    ),
                  ),
                  Text(
                    userName ?? 'Loading...',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      fontFamily: 'Noto Sans Bengali',
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // TODO: Notifications
            },
            icon: Badge(
              smallSize: 8,
              child: Icon(
                Icons.notifications_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final int totalProperties;
  final int availableCount;
  final int rentedCount;

  const _StatsSection({
    required this.colorScheme,
    required this.textTheme,
    required this.totalProperties,
    required this.availableCount,
    required this.rentedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              colorScheme: colorScheme,
              textTheme: textTheme,
              icon: Icons.home_work,
              label: 'Total',
              value: totalProperties.toString(),
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              colorScheme: colorScheme,
              textTheme: textTheme,
              icon: Icons.check_circle_outline,
              label: 'Available',
              value: availableCount.toString(),
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              colorScheme: colorScheme,
              textTheme: textTheme,
              icon: Icons.people_outline,
              label: 'Rented',
              value: rentedCount.toString(),
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.colorScheme,
    required this.textTheme,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onAddProperty;

  const _EmptyState({
    required this.colorScheme,
    required this.textTheme,
    required this.onAddProperty,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No Properties Yet",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Start by adding your first property",
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddProperty,
              icon: const Icon(Icons.add),
              label: const Text('Add Property'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
