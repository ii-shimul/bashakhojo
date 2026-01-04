import 'package:bashakhojo/common/components/ListingCard.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedCategoryIndex = 0;

  static const List<_Category> _categories = [
    _Category(label: 'ফ্যামিলি (Family)', icon: Icons.family_restroom),
    _Category(label: 'ব্যাচেলর (Bachelor)', icon: Icons.person),
    _Category(label: 'মেস (সিট)', icon: Icons.chair),
    _Category(label: 'মেস (রুম)', icon: Icons.meeting_room),
  ];

  // Sample property data
  static const List<_PropertyData> _properties = [
    _PropertyData(
      title: "ফ্ল্যাট ভাড়া হবে",
      category: "Family Apartment",
      price: "৳25,000",
      location: "বাড়ি ১২, রোড ৫, ধানমন্ডি, ঢাকা",
      beds: "3 Bed",
      baths: "2 Bath",
      imageUrl: "https://placehold.co/600x400/png",
      isVerified: true,
    ),
    _PropertyData(
      title: "একটি সিট ভাড়া হবে",
      category: "Bachelor Mess (Seat)",
      price: "৳5,500",
      location: "সেক্টর ৭, উত্তরা, ঢাকা",
      feature1: "1 Seat",
      feature2: "WiFi",
      featureIcon1: Icons.single_bed,
      featureIcon2: Icons.wifi,
      imageUrl: "https://placehold.co/600x400/e6e6e6/png",
      isPopular: true,
    ),
    _PropertyData(
      title: "ছোট রুম ভাড়া হবে",
      category: "Mess (Room)",
      price: "৳8,000",
      location: "মিরপুর ১০, ঢাকা",
      feature1: "120 Sqft",
      featureIcon1: Icons.square_foot,
      imageUrl: "https://placehold.co/600x400/cccccc/png",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPadding + 16)),
              // App Bar
              SliverToBoxAdapter(
                child: _AppBar(colorScheme: colorScheme, textTheme: textTheme),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              // Search Bar
              SliverToBoxAdapter(child: _SearchBar(colorScheme: colorScheme)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              // Category Chips
              SliverToBoxAdapter(
                child: _CategoryChips(
                  categories: _categories,
                  selectedIndex: _selectedCategoryIndex,
                  onSelected: (index) {
                    setState(() => _selectedCategoryIndex = index);
                  },
                  colorScheme: colorScheme,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              // Property List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: _properties.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    return _PropertyCard(
                      property: _properties[index],
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    );
                  },
                ),
              ),
              // Bottom padding for floating nav
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          // Floating Bottom Navigation
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: _BottomNavBar(colorScheme: colorScheme),
          ),
        ],
      ),
    );
  }
}

// --- Data Classes ---

class _Category {
  final String label;
  final IconData icon;

  const _Category({required this.label, required this.icon});
}

class _PropertyData {
  final String title;
  final String category;
  final String price;
  final String location;
  final String imageUrl;
  final String? beds;
  final String? baths;
  final String? feature1;
  final String? feature2;
  final IconData? featureIcon1;
  final IconData? featureIcon2;
  final bool isVerified;
  final bool isPopular;

  const _PropertyData({
    required this.title,
    required this.category,
    required this.price,
    required this.location,
    required this.imageUrl,
    this.beds,
    this.baths,
    this.feature1,
    this.feature2,
    this.featureIcon1,
    this.featureIcon2,
    this.isVerified = false,
    this.isPopular = false,
  });
}

// --- Extracted Widgets ---

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
                    "স্বাগতম (Welcome)",
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
                  hintText: "অবস্থান খুঁজুন (Search Location)...",
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(categories.length, (index) {
          final isSelected = selectedIndex == index;
          final category = categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(100),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                        fontFamily: 'Noto Sans Bengali',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final _PropertyData property;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _PropertyCard({
    required this.property,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    property.imageUrl,
                    fit: BoxFit.cover,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: frame != null
                                ? child
                                : Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                          );
                        },
                    errorBuilder: (_, __, ___) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              // Badge (Verified or Popular)
              if (property.isVerified || property.isPopular)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          property.isVerified ? Icons.verified : Icons.star,
                          size: 14,
                          color: property.isVerified
                              ? colorScheme.primary
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          property.isVerified ? "VERIFIED" : "POPULAR",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Favorite Button
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bookmark_add_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Details Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.category,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            property.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Noto Sans Bengali',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          property.price,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          "/ month",
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.location,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'Noto Sans Bengali',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),

                // Features & Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (property.beds != null)
                            ListingCard(
                              icon: Icons.bed,
                              text: property.beds!,
                              colorScheme: colorScheme,
                            ),
                          if (property.feature1 != null)
                            ListingCard(
                              icon: property.featureIcon1 ?? Icons.square_foot,
                              text: property.feature1!,
                              colorScheme: colorScheme,
                            ),
                          if (property.baths != null)
                            ListingCard(
                              icon: Icons.bathtub,
                              text: property.baths!,
                              colorScheme: colorScheme,
                            ),
                          if (property.feature2 != null)
                            ListingCard(
                              icon: property.featureIcon2 ?? Icons.wifi,
                              text: property.feature2!,
                              colorScheme: colorScheme,
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 4,
                        shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 0,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        "Rent Now",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final ColorScheme colorScheme;

  const _BottomNavBar({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(icon: Icons.home, label: "Home", isActive: true),
          _NavItem(
            icon: Icons.bookmark_border,
            label: "Saved",
            isActive: false,
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline,
            label: "Inbox",
            isActive: false,
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: "Profile",
            isActive: false,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 26,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
