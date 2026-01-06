import 'dart:io';

import 'package:bashakhojo/common/widgets/custom_snackbar.dart';
import 'package:bashakhojo/services/property_service.dart';
import 'package:bashakhojo/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedTypeIndex = 0;
  int _bedroomCount = 2;
  int _bathroomCount = 1;
  final Set<String> _selectedAmenities = {};
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  final List<String> _categories = [
    'family',
    'bachelor',
    'mess_seat',
    'mess_room',
  ];
  final List<String> _categoryLabels = [
    'Family',
    'Bachelor',
    'Mess (Seat)',
    'Mess (Room)',
  ];

  final List<String> _amenitiesList = [
    'Gas Supply',
    'CCTV',
    'Lift',
    'Generator',
    'WiFi',
    'Parking',
    'Rooftop Access',
    'Security Guard',
    'Fridge',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        // Limit to 10 images
        final remaining = 10 - _selectedImages.length;
        _selectedImages.addAll(images.take(remaining));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    final List<String> urls = [];
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return urls;

    for (final image in _selectedImages) {
      final bytes = await File(image.path).readAsBytes();
      final ext = image.path.split('.').last.toLowerCase();
      final contentType = ext == 'png'
          ? 'image/png'
          : ext == 'gif'
          ? 'image/gif'
          : 'image/jpeg';
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await SupabaseService.client.storage
          .from('property-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      final url = SupabaseService.client.storage
          .from('property-images')
          .getPublicUrl(fileName);

      urls.add(url);
    }

    return urls;
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      CustomSnackbar.show(context, 'Please add at least one photo');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload images first
      final imageUrls = await _uploadImages();

      // Create property
      await PropertyService.createProperty(
        title: _titleController.text.trim(),
        price: num.parse(_priceController.text.trim().replaceAll(',', '')),
        category: _categories[_selectedTypeIndex],
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        city: 'Sylhet',
        bedroomCount: _isApartmentType ? _bedroomCount : null,
        bathroomCount: _isApartmentType ? _bathroomCount : null,
        amenities: _selectedAmenities.isNotEmpty
            ? _selectedAmenities.toList()
            : null,
        images: imageUrls.isNotEmpty ? imageUrls : null,
      );

      if (mounted) {
        CustomSnackbar.show(
          context,
          'Property listed successfully!',
          isError: false,
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          'Failed to list property: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool get _isApartmentType =>
      _selectedTypeIndex == 0 || _selectedTypeIndex == 1;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add New Property",
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            height: 1,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Photos Section ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Property Photos",
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${_selectedImages.length}/10",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 112,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [
                    // Add Button
                    if (_selectedImages.length < 10)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 112,
                          height: 112,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Add Photos",
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Selected Images
                    ..._selectedImages.asMap().entries.map((entry) {
                      return _buildPhotoPreview(entry.value, entry.key);
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- Property Name ---
              _buildLabel(context, "Property Name"),
              _buildTextFormField(
                controller: _titleController,
                hint: "e.g. Sunny 3BHK in Dhanmondi",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a property name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // --- Price ---
              _buildLabel(context, "Monthly Rent"),
              _buildTextFormField(
                controller: _priceController,
                hint: "25000",
                prefixText: "৳ ",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter rent amount';
                  }
                  final price = num.tryParse(value.replaceAll(',', ''));
                  if (price == null || price <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // --- Property Type Pills ---
              _buildLabel(context, "Property Type"),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: List.generate(_categoryLabels.length, (index) {
                    return _buildTypePill(
                      context,
                      _categoryLabels[index],
                      index,
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // --- Rooms & Layout (only for apartment types) ---
              if (_isApartmentType) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Rooms & Layout",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCounterRow(
                        context,
                        "Bedrooms",
                        Icons.bed,
                        _bedroomCount,
                        (val) => setState(() => _bedroomCount = val),
                      ),
                      Divider(
                        height: 32,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      _buildCounterRow(
                        context,
                        "Bathrooms",
                        Icons.bathtub_outlined,
                        _bathroomCount,
                        (val) => setState(() => _bathroomCount = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // --- Location ---
              _buildLabel(context, "Address"),
              _buildTextFormField(
                controller: _addressController,
                hint: "e.g. House 12, Road 4, Sector 7, Uttara",
              ),

              const SizedBox(height: 24),

              // --- Amenities ---
              Text(
                "Amenities",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _amenitiesList.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedAmenities.remove(amenity);
                        } else {
                          _selectedAmenities.add(amenity);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.3,
                              ),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.3,
                                ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? Icons.check : _getAmenityIcon(amenity),
                            size: 18,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            amenity,
                            style: TextStyle(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // --- Description ---
              _buildLabel(context, "Description (Optional)"),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText:
                      "Describe the property features, nearby landmarks, and rules...",
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),

      // --- Sticky Bottom Action ---
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitProperty,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              disabledBackgroundColor: colorScheme.primary.withValues(
                alpha: 0.5,
              ),
              elevation: 4,
              shadowColor: colorScheme.primary.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "List Property",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildLabel(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    String? prefixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixText: prefixText,
        prefixStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildTypePill(BuildContext context, String text, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedTypeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTypeIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterRow(
    BuildContext context,
    String title,
    IconData icon,
    int count,
    ValueChanged<int> onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: colorScheme.onSurfaceVariant, size: 22),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            children: [
              _buildRoundButton(
                context,
                Icons.remove,
                () => onChanged(count > 1 ? count - 1 : 1),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              _buildRoundButton(
                context,
                Icons.add,
                () => onChanged(count + 1),
                isPrimary: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoundButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isPrimary ? colorScheme.surface : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isPrimary ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(XFile image, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 112,
      height: 112,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(image.path),
              width: 112,
              height: 112,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Cover',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String name) {
    switch (name) {
      case 'Lift':
        return Icons.elevator;
      case 'Generator':
        return Icons.bolt;
      case 'WiFi':
        return Icons.wifi;
      case 'Parking':
        return Icons.local_parking;
      case 'Gas Supply':
        return Icons.local_fire_department;
      case 'CCTV':
        return Icons.videocam;
      case 'Rooftop Access':
        return Icons.roofing;
      case 'Security Guard':
        return Icons.security;
      default:
        return Icons.check_circle_outline;
    }
  }
}
