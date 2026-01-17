import 'package:bashakhojo/common/utils/amenity_utils.dart';
import 'package:bashakhojo/common/widgets/custom_snackbar.dart';
import 'package:bashakhojo/screens/home/tenant_home.dart';
import 'package:bashakhojo/screens/property_details/property_details.dart';
import 'package:bashakhojo/services/saved_properties_notifier.dart';
import 'package:bashakhojo/services/user_service.dart';
import 'package:flutter/material.dart';

class PropertyCard extends StatefulWidget {
  final PropertyData property;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const PropertyCard({
    super.key,
    required this.property,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  State<PropertyCard> createState() {
    return _PropertyCardState();
  }
}

class _PropertyCardState extends State<PropertyCard> {
  bool _isSaved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    if (widget.property.id == null) {
      return;
    }

    bool saved = await UserService.isPropertySaved(widget.property.id!);

    if (mounted) {
      setState(() {
        _isSaved = saved;
      });
    }
  }

  Future<void> _toggleSave() async {
    if (widget.property.id == null || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSaved) {
        await UserService.unsaveProperty(widget.property.id!);

        if (mounted) {
          setState(() {
            _isSaved = false;
          });
          SavedPropertiesNotifier().notifyChange();
          CustomSnackbar.show(
            context,
            'Property removed from saved',
            isError: false,
          );
        }
      } else {
        await UserService.saveProperty(widget.property.id!);

        if (mounted) {
          setState(() {
            _isSaved = true;
          });
          SavedPropertiesNotifier().notifyChange();
          CustomSnackbar.show(
            context,
            'Property saved successfully',
            isError: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context, 'Failed to save: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatCategory(String category) {
    String formatted = category.replaceAll('_', ' ');
    List<String> words = formatted.split(' ');
    List<String> capitalizedWords = [];

    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      if (word.isEmpty) {
        capitalizedWords.add(word);
      } else {
        String capitalized = word[0].toUpperCase() + word.substring(1);
        capitalizedWords.add(capitalized);
      }
    }

    return capitalizedWords.join(' ');
  }

  void _navigateToDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return PropertyDetails(property: widget.property);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = widget.colorScheme;
    TextTheme textTheme = widget.textTheme;
    PropertyData property = widget.property;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: BoxBorder.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Column(
        children: [
          _buildImageSection(colorScheme, property),
          const SizedBox(height: 16),
          _buildContentSection(colorScheme, textTheme, property),
        ],
      ),
    );
  }

  Widget _buildImageSection(ColorScheme colorScheme, PropertyData property) {
    // Save button
    Color buttonBgColor = _isSaved
        ? colorScheme.primary
        : colorScheme.primary.withValues(alpha: 0.7);
    Widget saveButtonChild;
    if (_isLoading) {
      saveButtonChild = Padding(
        padding: const EdgeInsets.all(8),
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    } else {
      IconData icon = _isSaved ? Icons.bookmark : Icons.bookmark_add_outlined;
      Color iconColor = _isSaved ? Colors.white : Colors.tealAccent;
      saveButtonChild = Icon(icon, color: iconColor, size: 18);
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
              ),
              child: Image.network(
                property.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                frameBuilder:
                    (
                      BuildContext context,
                      Widget child,
                      int? frame,
                      bool wasSynchronouslyLoaded,
                    ) {
                      if (wasSynchronouslyLoaded) return child;
                      if (frame != null) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: child,
                        );
                      }
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      );
                    },
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
              ),
            ),
          ),
        ),
        // Save Button
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: _toggleSave,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: buttonBgColor,
                shape: BoxShape.circle,
              ),
              child: saveButtonChild,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
    PropertyData property,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatCategory(property.category),
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
          _buildFeaturesAndButton(colorScheme, property),
        ],
      ),
    );
  }

  Widget _buildFeaturesAndButton(
    ColorScheme colorScheme,
    PropertyData property,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(children: _buildFeatureChips(colorScheme, property)),
        ),
        ElevatedButton(
          onPressed: _navigateToDetails,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 4,
            shadowColor: colorScheme.primary.withValues(alpha: 0.3),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text(
            "See Details",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFeatureChips(
    ColorScheme colorScheme,
    PropertyData property,
  ) {
    List<Widget> chips = [];

    if (property.category == 'family' || property.category == 'bachelor') {
      if (property.bedroomCount != null) {
        chips.add(
          FeatureChip(
            icon: Icons.bed,
            text: '${property.bedroomCount} Bed',
            colorScheme: colorScheme,
          ),
        );
      }
      if (property.bathroomCount != null) {
        chips.add(
          FeatureChip(
            icon: Icons.bathtub_outlined,
            text: '${property.bathroomCount} Bath',
            colorScheme: colorScheme,
          ),
        );
      }
    } else {
      List<String> amenities = property.amenities ?? [];
      int count = 0;

      for (int i = 0; i < amenities.length && count < 2; i++) {
        String amenity = amenities[i];
        chips.add(
          FeatureChip(
            icon: getAmenityIcon(amenity),
            text: amenity,
            colorScheme: colorScheme,
          ),
        );
        count++;
      }
    }

    return chips;
  }
}

class FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;

  const FeatureChip({
    super.key,
    required this.icon,
    required this.text,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
