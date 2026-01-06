import 'package:bashakhojo/common/components/property_card.dart';
import 'package:bashakhojo/services/property_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategoryIndex = 0;
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;

  static const List<_Category> _categories = [
    _Category(label: 'All', icon: Icons.home, value: null),
    _Category(label: 'Family', icon: Icons.family_restroom, value: 'family'),
    _Category(label: 'Bachelor', icon: Icons.person, value: 'bachelor'),
    _Category(label: 'Mess (Seat)', icon: Icons.chair, value: 'mess_seat'),
    _Category(
      label: 'Mess (Room)',
      icon: Icons.meeting_room,
      value: 'mess_room',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final category = _categories[_selectedCategoryIndex].value;
      final properties = category == null
          ? await PropertyService.getProperties()
          : await PropertyService.getPropertiesByCategory(category);
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: topPadding + 16)),
        SliverToBoxAdapter(
          child: _AppBar(colorScheme: colorScheme, textTheme: textTheme),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(child: _SearchBar(colorScheme: colorScheme)),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: _CategoryChips(
            categories: _categories,
            selectedIndex: _selectedCategoryIndex,
            onSelected: (index) {
              setState(() => _selectedCategoryIndex = index);
              _loadProperties();
            },
            colorScheme: colorScheme,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        if (_isLoading)
          const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_properties.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No properties found',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
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
                return PropertyCard(
                  property: PropertyData(
                    title: property['title'] ?? '',
                    category: property['category'] ?? '',
                    price: '৳${property['price']?.toStringAsFixed(0) ?? '0'}',
                    location: property['address'] ?? property['city'] ?? '',
                    imageUrl: (property['images'] as List?)?.isNotEmpty == true
                        ? property['images'][0]
                        : 'https://placehold.co/600x400/e6e6e6/png',
                    bedroomCount: property['bedroom_count'],
                    bathroomCount: property['bathroom_count'],
                    amenities: (property['amenities'] as List?)?.cast<String>(),
                  ),
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _Category {
  final String label;
  final IconData icon;
  final String? value;

  const _Category({required this.label, required this.icon, this.value});
}

class PropertyData {
  final String title;
  final String category;
  final String price;
  final String location;
  final String imageUrl;
  final int? bedroomCount;
  final int? bathroomCount;
  final List<String>? amenities;
  final bool isVerified;
  final bool isPopular;

  const PropertyData({
    required this.title,
    required this.category,
    required this.price,
    required this.location,
    required this.imageUrl,
    this.bedroomCount,
    this.bathroomCount,
    this.amenities,
    this.isVerified = false,
    this.isPopular = false,
  });
}

class _AppBar extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _AppBar({required this.colorScheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home_work,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome to",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "BashaKhojo",
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant),
              color: colorScheme.surfaceContainerHighest,
            ),
            child: ClipOval(
              child: Image.network(
                'https://placehold.co/100x100/png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.person, color: colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ColorScheme colorScheme;

  const _SearchBar({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 12),
              child: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            ),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search Location...",
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'Noto Sans Bengali',
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurfaceVariant,
                child: const Icon(Icons.tune, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<_Category> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ColorScheme colorScheme;

  const _CategoryChips({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          final category = categories[index];
          return InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.surface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 18,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.label,
                    style: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
