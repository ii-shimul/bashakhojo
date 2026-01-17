import 'package:bashakhojo/common/components/property_card.dart';
import 'package:bashakhojo/common/utils/amenity_utils.dart';
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
  List<Map<String, dynamic>> _filteredProperties = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProperties() {
    if (_searchQuery.isEmpty) {
      _filteredProperties = List.from(_properties);
    } else {
      _filteredProperties = [];
      String queryLower = _searchQuery.toLowerCase();

      for (int i = 0; i < _properties.length; i++) {
        Map<String, dynamic> property = _properties[i];

        String address = property['address'] ?? '';
        String city = property['city'] ?? '';
        String location = '$address $city'.toLowerCase();

        if (location.contains(queryLower)) {
          _filteredProperties.add(property);
        }
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterProperties();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filterProperties();
    });
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
          _filterProperties();
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
      scrollBehavior: ScrollBehavior(),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: topPadding + 16)),
        SliverToBoxAdapter(
          child: AppBarSection(
            colorScheme: colorScheme,
            textTheme: textTheme,
            horizontalPadding: horizontalPadding,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: SearchBarSection(
            colorScheme: colorScheme,
            horizontalPadding: horizontalPadding,
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
            searchQuery: _searchQuery,
            onFilter: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const FilterBottomSheet(),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: CategoryChips(
            categories: _categories,
            selectedIndex: _selectedCategoryIndex,
            onSelected: _onCategorySelected,
            colorScheme: colorScheme,
            horizontalPadding: horizontalPadding,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        _buildPropertiesSection(colorScheme, textTheme, horizontalPadding),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
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

    if (_filteredProperties.isEmpty) {
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
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        sliver: SliverList.separated(
          itemCount: _filteredProperties.length,
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
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int index,
          ) {
            return _buildPropertyCard(index, colorScheme, textTheme);
          }, childCount: _filteredProperties.length),
        ),
      );
    }
  }

  Widget _buildPropertyCard(
    int index,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    Map<String, dynamic> property = _filteredProperties[index];

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
        children: [
          Container(
            padding: EdgeInsets.all(5),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Image.asset("assets/logo/logo.png"),
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
    );
  }
}

class SearchBarSection extends StatelessWidget {
  final ColorScheme colorScheme;
  final double horizontalPadding;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilter;
  final String searchQuery;

  const SearchBarSection({
    super.key,
    required this.colorScheme,
    required this.horizontalPadding,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilter,
    required this.searchQuery,
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
                  child: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      hintText: "Search by location...",
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'Noto Sans Bengali',
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                _buildTrailingButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingButton() {
    if (searchQuery.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: GestureDetector(
          onTap: onClear,
          child: CircleAvatar(
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurfaceVariant,
            child: const Icon(Icons.close, size: 20),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: GestureDetector(
          onTap: onFilter,
          child: CircleAvatar(
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurfaceVariant,
            child: const Icon(Icons.tune, size: 20),
          ),
        ),
      );
    }
  }
}

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String _selectedCity = "Dhaka";
  final TextEditingController _minPriceController = TextEditingController(
    text: "5000",
  );
  final TextEditingController _maxPriceController = TextEditingController(
    text: "30000",
  );
  int _selectedBeds = 3;
  int _selectedBaths = 2;
  final Set<String> _selectedAmenities = {};

  final List<String> _cities = ["Dhaka", "Sylhet", "Chittagong", "Rajshahi"];

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = const Color(0xFF00a89d);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(100),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filter",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSectionHeader("City"),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _cities.map((city) {
                      final isSelected = _selectedCity == city;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text(city),
                          selected: isSelected,
                          onSelected: (val) =>
                              setState(() => _selectedCity = city),
                          selectedColor: primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          backgroundColor: Colors.transparent,
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.grey[300]!,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 32),

                _buildSectionHeader("Price Range"),
                Row(
                  children: [
                    Expanded(
                      child: _buildPriceInputField(
                        controller: _minPriceController,
                        label: "Min",
                        colorScheme: colorScheme,
                        primaryColor: primaryColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "–",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildPriceInputField(
                        controller: _maxPriceController,
                        label: "Max",
                        colorScheme: colorScheme,
                        primaryColor: primaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Bedrooms"),
                          Row(
                            children: [1, 2, 3].map((num) {
                              final isSelected = _selectedBeds == num;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _selectedBeds = num),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : Colors.grey[300]!,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: primaryColor.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      num == 3 ? "3+" : num.toString(),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Bathrooms"),
                          Row(
                            children: [1, 2, 3].map((num) {
                              final isSelected = _selectedBaths == num;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _selectedBaths = num),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : Colors.grey[300]!,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: primaryColor.withValues(
                                                  alpha: 0.3,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      num == 3 ? "3+" : num.toString(),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                _buildSectionHeader("Amenities"),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 48,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: amenityList.length,
                  itemBuilder: (context, index) {
                    final item = amenityList[index];
                    final isChecked = _selectedAmenities.contains(item);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          isChecked
                              ? _selectedAmenities.remove(item)
                              : _selectedAmenities.add(item);
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isChecked
                                  ? primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isChecked
                                    ? Colors.transparent
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: isChecked
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      "Reset",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: primaryColor.withValues(alpha: 0.4),
                    ),
                    child: const Text(
                      "Apply Filter",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPriceInputField({
    required TextEditingController controller,
    required String label,
    required ColorScheme colorScheme,
    required Color primaryColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
          prefixText: "৳ ",
          prefixStyle: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
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
      height: 38,
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
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: borderColor),
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
