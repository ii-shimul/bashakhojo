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
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<Map<String, dynamic>> _savedProperties = [];
  bool _isLoading = true;
  final _notifier = SavedPropertiesNotifier();

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
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final profile = await UserService.getUser(userId);
      final savedIds = List<String>.from(profile?['saved_properties'] ?? []);

      if (savedIds.isEmpty) {
        setState(() {
          _savedProperties = [];
          _isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> properties = [];
      for (final id in savedIds) {
        try {
          final property = await PropertyService.getProperty(id);
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Saved Properties",
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (_savedProperties.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_savedProperties.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_outline,
                        size: 80,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No Saved Properties",
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Properties you save will appear here",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _savedProperties.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final property = _savedProperties[index];
                    final images =
                        (property['images'] as List?)?.cast<String>() ?? [];

                    return _SavedPropertyItem(
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
                      ),
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      onRemoved: _loadSavedProperties,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SavedPropertyItem extends StatelessWidget {
  final PropertyData property;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onRemoved;

  const _SavedPropertyItem({
    required this.property,
    required this.colorScheme,
    required this.textTheme,
    required this.onRemoved,
  });

  String _formatCategory(String category) {
    return category
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetails(property: property),
          ),
        ).then((_) => onRemoved());
      },
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
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image_outlined,
                    size: 40,
                    color: colorScheme.onSurfaceVariant,
                  ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Noto Sans Bengali',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCategory(property.category),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
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
