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
  State<LandlordHomeScreen> createState() {
    return _LandlordHomeScreenState();
  }
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen> {
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;
  String? _userName;
  String? _profileImageUrl;

  bool get _isMobile {
    double width = MediaQuery.of(context).size.width;
    return width < 600;
  }

  int get _gridCrossAxisCount {
    double width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 1;
    } else if (width < 900) {
      return 2;
    } else {
      return 3;
    }
  }

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
      String? userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        return;
      }

      Map<String, dynamic>? profile = await UserService.getUser(userId);

      if (mounted && profile != null) {
        setState(() {
          _userName = profile['full_name'] ?? 'User';
          _profileImageUrl = profile['avatar_url'];
        });
      }
    } catch (e) {
      // Silent fail for profile loading
    }
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? userId = SupabaseService.client.auth.currentUser?.id;

      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> properties =
          await PropertyService.getPropertiesByOwner(userId);

      if (mounted) {
        setState(() {
          _properties = properties;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onAddProperty() async {
    bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return const AddPropertyScreen();
        },
      ),
    );

    if (result == true) {
      _loadProperties();
    }
  }

  void _onEditProperty(String propertyId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit property feature coming soon!')),
    );
  }

  int _getAvailableCount() {
    int count = 0;
    for (int i = 0; i < _properties.length; i++) {
      if (_properties[i]['is_available'] == true) {
        count = count + 1;
      }
    }
    return count;
  }

  int _getRentedCount() {
    int count = 0;
    for (int i = 0; i < _properties.length; i++) {
      if (_properties[i]['is_available'] == false) {
        count = count + 1;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;
    double topPadding = MediaQuery.of(context).padding.top;

    double horizontalPadding;
    if (_isMobile) {
      horizontalPadding = 20;
    } else {
      horizontalPadding = 40;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: _buildFloatingActionButton(colorScheme),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topPadding + 16)),
            SliverToBoxAdapter(
              child: LandlordAppBar(
                colorScheme: colorScheme,
                textTheme: textTheme,
                userName: _userName,
                profileImageUrl: _profileImageUrl,
                horizontalPadding: horizontalPadding,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: StatsSection(
                colorScheme: colorScheme,
                textTheme: textTheme,
                totalProperties: _properties.length,
                availableCount: _getAvailableCount(),
                rentedCount: _getRentedCount(),
                horizontalPadding: horizontalPadding,
                isMobile: _isMobile,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _buildListingsHeader(
                colorScheme,
                textTheme,
                horizontalPadding,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            _buildPropertiesSection(colorScheme, textTheme, horizontalPadding),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton(
        onPressed: _onAddProperty,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildListingsHeader(
    ColorScheme colorScheme,
    TextTheme textTheme,
    double horizontalPadding,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Your Listings',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (_properties.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }

  Widget _buildPropertiesSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
    double horizontalPadding,
  ) {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_properties.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          colorScheme: colorScheme,
          textTheme: textTheme,
          onAddProperty: _onAddProperty,
        ),
      );
    }

    if (_isMobile) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        sliver: SliverList.separated(
          itemCount: _properties.length,
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(height: 20);
          },
          itemBuilder: (BuildContext context, int index) {
            return _buildPropertyCard(index, colorScheme, textTheme);
          },
        ),
      );
    } else {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridCrossAxisCount,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.85,
          ),
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int index,
          ) {
            return _buildPropertyCard(index, colorScheme, textTheme);
          }, childCount: _properties.length),
        ),
      );
    }
  }

  Widget _buildPropertyCard(
    int index,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    Map<String, dynamic> property = _properties[index];

    List<String> images = [];
    if (property['images'] != null) {
      List<dynamic> imagesRaw = property['images'] as List<dynamic>;
      for (int i = 0; i < imagesRaw.length; i++) {
        images.add(imagesRaw[i].toString());
      }
    }

    String imageUrl = 'https://placehold.co/600x400/e6e6e6/png';
    if (images.isNotEmpty) {
      imageUrl = images[0];
    }

    String price = '৳0';
    if (property['price'] != null) {
      double priceValue = (property['price'] as num).toDouble();
      price = '৳${priceValue.toStringAsFixed(0)}';
    }

    String location = property['address'] ?? property['city'] ?? '';

    List<String>? amenities;
    if (property['amenities'] != null) {
      List<dynamic> amenitiesRaw = property['amenities'] as List<dynamic>;
      amenities = [];
      for (int i = 0; i < amenitiesRaw.length; i++) {
        amenities.add(amenitiesRaw[i].toString());
      }
    }

    bool isAvailable = property['is_available'] ?? true;

    PropertyData propertyData = PropertyData(
      id: property['id'],
      title: property['title'] ?? '',
      category: property['category'] ?? '',
      price: price,
      location: location,
      imageUrl: imageUrl,
      bedroomCount: property['bedroom_count'],
      bathroomCount: property['bathroom_count'],
      amenities: amenities,
      description: property['description'],
      images: images,
      owner_id: property['owner_id'],
      isAvailable: isAvailable,
    );

    return LandlordPropertyCard(
      property: propertyData,
      colorScheme: colorScheme,
      textTheme: textTheme,
      onDeleted: _loadProperties,
      onEdit: () {
        _onEditProperty(property['id']);
      },
    );
  }
}

class LandlordAppBar extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String? userName;
  final String? profileImageUrl;
  final double horizontalPadding;

  const LandlordAppBar({
    super.key,
    required this.colorScheme,
    required this.textTheme,
    this.userName,
    this.profileImageUrl,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarChild;
    if (profileImageUrl != null) {
      avatarChild = Image.network(
        profileImageUrl!,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return Icon(Icons.person, color: colorScheme.onSurfaceVariant);
            },
      );
    } else {
      avatarChild = Icon(Icons.person, color: colorScheme.onSurfaceVariant);
    }

    String displayName = userName ?? 'Loading...';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
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
            child: ClipOval(child: avatarChild),
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
                displayName,
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
    );
  }
}

class StatsSection extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final int totalProperties;
  final int availableCount;
  final int rentedCount;
  final double horizontalPadding;
  final bool isMobile;

  const StatsSection({
    super.key,
    required this.colorScheme,
    required this.textTheme,
    required this.totalProperties,
    required this.availableCount,
    required this.rentedCount,
    required this.horizontalPadding,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    Widget statsRow = Row(
      children: [
        Expanded(
          child: StatCard(
            colorScheme: colorScheme,
            textTheme: textTheme,
            icon: Icons.home_work,
            label: 'Total',
            value: totalProperties.toString(),
            color: colorScheme.primary,
          ),
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: StatCard(
            colorScheme: colorScheme,
            textTheme: textTheme,
            icon: Icons.check_circle_outline,
            label: 'Available',
            value: availableCount.toString(),
            color: Colors.green,
          ),
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: StatCard(
            colorScheme: colorScheme,
            textTheme: textTheme,
            icon: Icons.people_outline,
            label: 'Rented',
            value: rentedCount.toString(),
            color: Colors.orange,
          ),
        ),
      ],
    );

    if (isMobile) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: statsRow,
      );
    } else {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: statsRow,
          ),
        ),
      );
    }
  }
}

class StatCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatCard({
    super.key,
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

class EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onAddProperty;

  const EmptyState({
    super.key,
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
