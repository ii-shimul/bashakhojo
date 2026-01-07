import 'package:bashakhojo/common/components/property_card.dart';
import 'package:bashakhojo/services/property_service.dart';
import 'package:flutter/material.dart';

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() {
    return _TenantHomeScreenState();
  }
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  int _selectedCategoryIndex = 0;
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;

  List<Category> get _categories {
    return [
      Category(label: 'All', icon: Icons.home, value: null),
      Category(label: 'Family', icon: Icons.family_restroom, value: 'family'),
      Category(label: 'Bachelor', icon: Icons.person, value: 'bachelor'),
      Category(label: 'Mess (Seat)', icon: Icons.chair, value: 'mess_seat'),
      Category(
        label: 'Mess (Room)',
        icon: Icons.meeting_room,
        value: 'mess_room',
      ),
    ];
  }

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
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? category = _categories[_selectedCategoryIndex].value;

      List<Map<String, dynamic>> properties;
      if (category == null) {
        properties = await PropertyService.getProperties();
      } else {
        properties = await PropertyService.getPropertiesByCategory(category);
      }

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

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
    _loadProperties();
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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: topPadding + 16)),
        SliverToBoxAdapter(
          child: AppBarSection(
            colorScheme: colorScheme,
            textTheme: textTheme,
            horizontalPadding: horizontalPadding,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: SearchBarSection(
            colorScheme: colorScheme,
            horizontalPadding: horizontalPadding,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: CategoryChips(
            categories: _categories,
            selectedIndex: _selectedCategoryIndex,
            onSelected: _onCategorySelected,
            colorScheme: colorScheme,
            horizontalPadding: horizontalPadding,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        _buildPropertiesSection(colorScheme, textTheme, horizontalPadding),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildPropertiesSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
    double horizontalPadding,
  ) {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_properties.isEmpty) {
      return SliverToBoxAdapter(
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
      );
    }

    if (_isMobile) {
      return _buildMobileList(colorScheme, textTheme, horizontalPadding);
    } else {
      return _buildDesktopGrid(colorScheme, textTheme, horizontalPadding);
    }
  }

  Widget _buildMobileList(
    ColorScheme colorScheme,
    TextTheme textTheme,
    double horizontalPadding,
  ) {
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
  }

  Widget _buildDesktopGrid(
    ColorScheme colorScheme,
    TextTheme textTheme,
    double horizontalPadding,
  ) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridCrossAxisCount,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return _buildPropertyCard(index, colorScheme, textTheme);
          },
          childCount: _properties.length,
        ),
      ),
    );
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
    );

    return PropertyCard(
      property: propertyData,
      colorScheme: colorScheme,
      textTheme: textTheme,
    );
  }
}

class Category {
  final String label;
  final IconData icon;
  final String? value;

  const Category({required this.label, required this.icon, this.value});
}

class PropertyData {
  final String? id;
  final String title;
  final String category;
  final String price;
  final String location;
  final String imageUrl;
  final int? bedroomCount;
  final int? bathroomCount;
  final List<String>? amenities;
  final String? description;
  final List<String>? images;
  final String? owner_id;
  final bool isVerified;
  final bool isPopular;
  final bool isAvailable;

  const PropertyData({
    this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.location,
    required this.imageUrl,
    this.bedroomCount,
    this.bathroomCount,
    this.amenities,
    this.description,
    this.images,
    this.owner_id,
    this.isVerified = false,
    this.isPopular = false,
    this.isAvailable = true,
  });
}

class AppBarSection extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final double horizontalPadding;

  const AppBarSection({
    super.key,
    required this.colorScheme,
    required this.textTheme,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildLogo(),
              const SizedBox(width: 12),
              _buildTitle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.home_work, color: colorScheme.primary, size: 24),
    );
  }

  Widget _buildTitle() {
    return Column(
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
    );
  }
}

class SearchBarSection extends StatelessWidget {
  final ColorScheme colorScheme;
  final double horizontalPadding;

  const SearchBarSection({
    super.key,
    required this.colorScheme,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    double maxWidth;
    if (isMobile) {
      maxWidth = double.infinity;
    } else {
      maxWidth = 600;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
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
        ),
      ),
    );
  }
}

class CategoryChips extends StatelessWidget {
  final List<Category> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ColorScheme colorScheme;
  final double horizontalPadding;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
    required this.colorScheme,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: categories.length,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(width: 12);
        },
        itemBuilder: (BuildContext context, int index) {
          return _buildChip(index);
        },
      ),
    );
  }

  Widget _buildChip(int index) {
    bool isSelected = selectedIndex == index;
    Category category = categories[index];

    Color backgroundColor;
    if (isSelected) {
      backgroundColor = colorScheme.primary;
    } else {
      backgroundColor = colorScheme.surface;
    }

    Color borderColor;
    if (isSelected) {
      borderColor = Colors.transparent;
    } else {
      borderColor = colorScheme.outlineVariant.withValues(alpha: 0.5);
    }

    List<BoxShadow>? boxShadow;
    if (isSelected) {
      boxShadow = [
        BoxShadow(
          color: colorScheme.primary.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
    }

    Color iconColor;
    if (isSelected) {
      iconColor = colorScheme.onPrimary;
    } else {
      iconColor = colorScheme.onSurfaceVariant;
    }

    Color textColor;
    if (isSelected) {
      textColor = colorScheme.onPrimary;
    } else {
      textColor = colorScheme.onSurface;
    }

    return InkWell(
      onTap: () {
        onSelected(index);
      },
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: borderColor),
          boxShadow: boxShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              category.label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
