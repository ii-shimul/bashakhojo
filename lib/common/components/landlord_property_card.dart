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
  State<LandlordPropertyCard> createState() => _LandlordPropertyCardState();
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
    if (widget.property.id == null || _isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      await PropertyService.updateProperty(widget.property.id!, {
        'is_available': value,
      });
      if (mounted) {
        setState(() => _isAvailable = value);
        CustomSnackbar.show(
          context,
          value ? 'Property marked as available' : 'Property marked as rented',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context, 'Failed to update: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _deleteProperty() async {
    if (widget.property.id == null || _isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text(
          'Are you sure you want to delete this property? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await PropertyService.deleteProperty(widget.property.id!);
      if (mounted) {
        CustomSnackbar.show(
          context,
          'Property deleted successfully',
          isError: false,
        );
        widget.onDeleted?.call();
      }
    } catch (e) {
      debugPrint('Delete error: $e');
      if (mounted) {
        CustomSnackbar.show(context, 'Failed to delete property');
        setState(() => _isDeleting = false);
      }
    }
  }

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
    final colorScheme = widget.colorScheme;
    final textTheme = widget.textTheme;
    final property = widget.property;

    return Opacity(
      opacity: _isDeleting ? 0.5 : 1.0,
      child: Container(
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Image Section with Status Badge
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    colorFilter: !_isAvailable
                        ? const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          )
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          ),
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
                                      color:
                                          colorScheme.surfaceContainerHighest,
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
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gradient Overlay
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
                  // Price Tag
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                              text: '/mo',
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
                  // Status Badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _isAvailable
                            ? Colors.green.withValues(alpha: 0.9)
                            : Colors.grey[700]!.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isAvailable ? 'AVAILABLE' : 'RENTED',
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
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Text(
                    _formatCategory(property.category),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Title
                  Text(
                    property.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Noto Sans Bengali',
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location
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

                  // Features Row
                  Row(children: _buildFeatures()),

                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),

                  // Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Availability Switch
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            child: _isUpdating
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
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isAvailable ? 'Available' : 'Rented',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isAvailable
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      // Action Buttons
                      Row(
                        children: [
                          _ActionButton(
                            icon: Icons.edit_outlined,
                            label: 'Edit',
                            colorScheme: colorScheme,
                            onTap: widget.onEdit,
                          ),
                          const SizedBox(width: 8),
                          _IconButton(
                            icon: Icons.delete_outline,
                            color: Colors.red,
                            onTap: _deleteProperty,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeatures() {
    final property = widget.property;
    final colorScheme = widget.colorScheme;
    final isApartment =
        property.category == 'family' || property.category == 'bachelor';

    List<_FeatureChip> chips = [];

    if (isApartment) {
      if (property.bedroomCount != null) {
        chips.add(
          _FeatureChip(
            icon: Icons.bed,
            text: '${property.bedroomCount} Bed',
            colorScheme: colorScheme,
          ),
        );
      }
      if (property.bathroomCount != null) {
        chips.add(
          _FeatureChip(
            icon: Icons.bathtub_outlined,
            text: '${property.bathroomCount} Bath',
            colorScheme: colorScheme,
          ),
        );
      }
    } else {
      final amenities = property.amenities ?? [];
      chips = amenities
          .take(2)
          .map(
            (amenity) => _FeatureChip(
              icon: _getAmenityIcon(amenity),
              text: amenity,
              colorScheme: colorScheme,
            ),
          )
          .toList();
    }

    return chips;
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'ac':
        return Icons.ac_unit;
      case 'parking':
        return Icons.local_parking;
      case 'gym':
        return Icons.fitness_center;
      case 'pool':
        return Icons.pool;
      default:
        return Icons.check_circle_outline;
    }
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;

  const _FeatureChip({
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  const _ActionButton({
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

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _IconButton({required this.icon, required this.color, this.onTap});

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
