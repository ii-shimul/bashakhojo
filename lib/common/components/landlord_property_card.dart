import 'package:bashakhojo/common/utils/amenity_utils.dart';
import 'package:bashakhojo/common/widgets/custom_snackbar.dart';
import 'package:bashakhojo/screens/home/tenant_home.dart';
import 'package:bashakhojo/services/property_service.dart';
import 'package:flutter/material.dart';

class LandlordPropertyCard extends StatefulWidget {
  final PropertyData property;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback? onDeleted;
  final VoidCallback? onEdit;

  const LandlordPropertyCard({
    super.key,
    required this.property,
    required this.colorScheme,
    required this.textTheme,
    this.onDeleted,
    this.onEdit,
  });

  @override
  State<LandlordPropertyCard> createState() {
    return _LandlordPropertyCardState();
  }
}

class _LandlordPropertyCardState extends State<LandlordPropertyCard> {
  late bool _isAvailable;
  bool _isUpdating = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.property.isAvailable;
  }

  @override
  void didUpdateWidget(LandlordPropertyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property.isAvailable != widget.property.isAvailable) {
      _isAvailable = widget.property.isAvailable;
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    if (widget.property.id == null || _isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await PropertyService.updateProperty(widget.property.id!, {
        'is_available': value,
      });

      if (mounted) {
        setState(() {
          _isAvailable = value;
        });

        String message;
        if (value) {
          message = 'Listing marked as available';
        } else {
          message = 'Listing marked as rented';
        }

        CustomSnackbar.show(context, message, isError: false);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context, 'Failed to update: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _deleteProperty() async {
    if (widget.property.id == null || _isDeleting) {
      return;
    }

    bool? confirmed = await _showDeleteDialog();

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await PropertyService.deleteProperty(widget.property.id!);

      if (mounted) {
        CustomSnackbar.show(
          context,
          'Listing deleted successfully',
          isError: false,
        );

        if (widget.onDeleted != null) {
          widget.onDeleted!();
        }
      }
    } catch (e) {
      debugPrint('Delete error: $e');

      if (mounted) {
        CustomSnackbar.show(context, 'Failed to delete listing');
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Listing'),
          content: const Text(
            'Are you sure you want to delete this listing? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = widget.colorScheme;
    TextTheme textTheme = widget.textTheme;
    PropertyData property = widget.property;

    double opacity;
    if (_isDeleting) {
      opacity = 0.5;
    } else {
      opacity = 1.0;
    }

    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: BoxBorder.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildImageSection(colorScheme, property),
            _buildContentSection(colorScheme, textTheme, property),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(ColorScheme colorScheme, PropertyData property) {
    ColorFilter colorFilter;
    if (!_isAvailable) {
      colorFilter = const ColorFilter.mode(Colors.grey, BlendMode.saturation);
    } else {
      colorFilter = const ColorFilter.mode(
        Colors.transparent,
        BlendMode.multiply,
      );
    }

    Color badgeColor;
    String badgeText;
    if (_isAvailable) {
      badgeColor = Colors.green.withValues(alpha: 0.9);
      badgeText = 'AVAILABLE';
    } else {
      badgeColor = Colors.grey[700]!.withValues(alpha: 0.9);
      badgeText = 'RENTED';
    }

    return SizedBox(
      height: 250,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: colorFilter,
            child: Image.network(
              property.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              frameBuilder:
                  (
                    BuildContext context,
                    Widget child,
                    int? frame,
                    bool wasSynchronouslyLoaded,
                  ) {
                    if (wasSynchronouslyLoaded || frame != null) {
                      return child;
                    }
                    return Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                    );
                  },
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
            ),
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),

          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
              ),
              child: RichText(
                text: TextSpan(
                  text: property.price,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '/month',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
    PropertyData property,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
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
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: _buildFeatureChips(colorScheme, property)),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          _buildActionsRow(colorScheme),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureChips(
    ColorScheme colorScheme,
    PropertyData property,
  ) {
    bool isApartment =
        property.category == 'family' || property.category == 'bachelor';

    List<Widget> chips = [];

    if (isApartment) {
      if (property.bedroomCount != null) {
        chips.add(
          LandlordFeatureChip(
            icon: Icons.bed,
            text: '${property.bedroomCount} Bed',
            colorScheme: colorScheme,
          ),
        );
      }
      if (property.bathroomCount != null) {
        chips.add(
          LandlordFeatureChip(
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
          LandlordFeatureChip(
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

  Widget _buildActionsRow(ColorScheme colorScheme) {
    Widget switchWidget = _isUpdating
        ? SizedBox(
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          )
        : Switch.adaptive(
            value: _isAvailable,
            activeColor: colorScheme.primary,
            onChanged: _toggleAvailability,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );

    String statusText = _isAvailable ? 'Available' : 'Rented';
    Color statusColor = _isAvailable
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(height: 24, child: switchWidget),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),

        Row(
          children: [
            ActionButton(
              icon: Icons.edit_outlined,
              label: 'Edit',
              colorScheme: colorScheme,
              onTap: widget.onEdit,
            ),
            const SizedBox(width: 8),
            IconActionButton(
              icon: Icons.delete_outline,
              color: Colors.red,
              onTap: _deleteProperty,
            ),
          ],
        ),
      ],
    );
  }
}

class LandlordFeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;

  const LandlordFeatureChip({
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

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.colorScheme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IconActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const IconActionButton({
    super.key,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: color.withValues(alpha: 0.7)),
      ),
    );
  }
}
