import 'package:bashakhojo/common/widgets/custom_snackbar.dart';
import 'package:bashakhojo/pages/home/home.dart';
import 'package:bashakhojo/pages/property_details/property_details.dart';
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
  State<PropertyCard> createState() => _PropertyCardState();
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
    if (widget.property.id == null) return;
    final saved = await UserService.isPropertySaved(widget.property.id!);
    if (mounted) {
      setState(() => _isSaved = saved);
    }
  }

  Future<void> _toggleSave() async {
    if (widget.property.id == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (_isSaved) {
        await UserService.unsaveProperty(widget.property.id!);
        if (mounted) {
          setState(() => _isSaved = false);
          CustomSnackbar.show(
            context,
            'Property removed from saved',
            isError: false,
          );
        }
      } else {
        await UserService.saveProperty(widget.property.id!);
        if (mounted) {
          setState(() => _isSaved = true);
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    final textTheme = widget.textTheme;
    final property = widget.property;
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
          Stack(
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
                          (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: frame != null
                                  ? child
                                  : Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                            );
                          },
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _toggleSave,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _isSaved
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_add_outlined,
                            color: _isSaved ? Colors.white : Colors.tealAccent,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Row(children: _buildFeatures())),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PropertyDetails(property: property),
                          ),
                        );
                      },
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
                        "See Details",
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

  List<Widget> _buildFeatures() {
    final property = widget.property;
    final colorScheme = widget.colorScheme;
    final isApartment =
        property.category == 'family' || property.category == 'bachelor';

    if (isApartment) {
      return [
        if (property.bedroomCount != null)
          _FeatureText(
            text: '${property.bedroomCount} Bed',
            colorScheme: colorScheme,
          ),
        if (property.bathroomCount != null)
          _FeatureText(
            text: '${property.bathroomCount} Bath',
            colorScheme: colorScheme,
          ),
      ];
    } else {
      final amenities = property.amenities ?? [];
      return amenities
          .take(2)
          .map(
            (amenity) => _FeatureText(text: amenity, colorScheme: colorScheme),
          )
          .toList();
    }
  }
}

class _FeatureText extends StatelessWidget {
  final String text;
  final ColorScheme colorScheme;

  const _FeatureText({required this.text, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
