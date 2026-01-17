import 'package:bashakhojo/screens/home/tenant_home.dart';
import 'package:bashakhojo/screens/property_details/property_details.dart';
import 'package:bashakhojo/services/property_service.dart';
import 'package:bashakhojo/services/saved_properties_notifier.dart';
import 'package:bashakhojo/services/supabase_service.dart';
import 'package:bashakhojo/services/user_service.dart';
import 'package:flutter/material.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() {
    return _SavedScreenState();
  }
}

class _SavedScreenState extends State<SavedScreen> {
  List<Map<String, dynamic>> _savedProperties = [];
  bool _isLoading = true;
  final SavedPropertiesNotifier _notifier = SavedPropertiesNotifier();

  @override
  void initState() {
    super.initState();
    _notifier.addListener(_onSavedPropertiesChanged);
    _loadSavedProperties();
  }

  @override
  void dispose() {
    _notifier.removeListener(_onSavedPropertiesChanged);
    super.dispose();
  }

  void _onSavedPropertiesChanged() {
    _loadSavedProperties();
  }

  Future<void> _loadSavedProperties() async {
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

      Map<String, dynamic>? profile = await UserService.getUser(userId);

      List<dynamic> savedIdsRaw = profile?['saved_properties'] ?? [];
      List<String> savedIds = [];
      for (int i = 0; i < savedIdsRaw.length; i++) {
        savedIds.add(savedIdsRaw[i].toString());
      }

      if (savedIds.isEmpty) {
        setState(() {
          _savedProperties = [];
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> properties = [];

      for (int i = 0; i < savedIds.length; i++) {
        String id = savedIds[i];
        try {
          Map<String, dynamic>? property = await PropertyService.getProperty(
            id,
          );
          if (property != null) {
            properties.add(property);
          }
        } catch (e) {
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _savedProperties = properties;
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
            "Saved Listings",
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          if (_savedProperties.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_savedProperties.length}',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (_savedProperties.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_outline,
                size: 80,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                "No Saved Listings",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Listings you save will appear here",
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _savedProperties.length,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 16);
        },
        itemBuilder: (BuildContext context, int index) {
          Map<String, dynamic> property = _savedProperties[index];
          return _buildPropertyItem(property, colorScheme, textTheme);
        },
      ),
    );
  }

  Widget _buildPropertyItem(
    Map<String, dynamic> property,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
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

    return SavedPropertyItem(
      property: propertyData,
      colorScheme: colorScheme,
      textTheme: textTheme,
      onRemoved: _loadSavedProperties,
    );
  }
}

class SavedPropertyItem extends StatelessWidget {
  final PropertyData property;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onRemoved;

  const SavedPropertyItem({
    super.key,
    required this.property,
    required this.colorScheme,
    required this.textTheme,
    required this.onRemoved,
  });

  String _formatCategory(String category) {
    String replaced = category.replaceAll('_', ' ');
    List<String> words = replaced.split(' ');

    List<String> capitalizedWords = [];
    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      if (word.isEmpty) {
        capitalizedWords.add(word);
      } else {
        String firstLetter = word[0].toUpperCase();
        String restOfWord = word.substring(1);
        capitalizedWords.add(firstLetter + restOfWord);
      }
    }

    return capitalizedWords.join(' ');
  }

  void _onTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return PropertyDetails(property: property);
        },
      ),
    ).then((value) {
      onRemoved();
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedCategory = _formatCategory(property.category);

    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: Image.network(
                  property.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        );
                      },
                ),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Noto Sans Bengali',
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Category
                    Text(
                      formattedCategory,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontFamily: 'Noto Sans Bengali',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          property.price,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          '/ month',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
