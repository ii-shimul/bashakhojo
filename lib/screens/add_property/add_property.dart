import 'dart:io';
import 'dart:typed_data';

import 'package:bashakhojo/common/utils/amenity_utils.dart';
import 'package:bashakhojo/common/widgets/custom_snackbar.dart';
import 'package:bashakhojo/services/property_service.dart';
import 'package:bashakhojo/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() {
    return _AddPropertyScreenState();
  }
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int _selectedTypeIndex = 0;
  int _bedroomCount = 2;
  int _bathroomCount = 1;
  final Set<String> _selectedAmenities = {};
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  List<String> get _categories {
    return ['family', 'bachelor', 'mess_seat', 'mess_room'];
  }

  List<String> get _categoryLabels {
    return ['Family', 'Bachelor', 'Mess (Seat)', 'Mess (Room)'];
  }

  List<String> get _amenitiesList {
    return [
      'WiFi',
      'AC',
      'Parking',
      'Bike Parking',
      'Lift',
      'Generator',
      'Security',
      'Furnished',
      'Attached Bath',
      'Shared Washroom',
      'Balcony',
      'Rooftop',
      'Shared Kitchen',
      'Kitchen',
      'Line Gas',
      'Water Filter',
      'Tiled Floor',
      'Meal System',
      '24/7 Water',
      'Open View',
      'Drawing Room',
      'Dining Space',
    ];
  }

  bool get _isApartmentType {
    return _selectedTypeIndex == 0 || _selectedTypeIndex == 1;
  }

  bool get _isMobile {
    double width = MediaQuery.of(context).size.width;
    return width < 600;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    ImagePicker picker = ImagePicker();
    List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        int remaining = 10 - _selectedImages.length;
        List<XFile> imagesToAdd = [];

        for (int i = 0; i < images.length && i < remaining; i++) {
          imagesToAdd.add(images[i]);
        }

        _selectedImages.addAll(imagesToAdd);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    List<String> urls = [];

    String? userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      return urls;
    }

    for (int i = 0; i < _selectedImages.length; i++) {
      XFile image = _selectedImages[i];

      Uint8List bytes = await File(image.path).readAsBytes();

      String path = image.path;
      List<String> parts = path.split('.');
      String ext = parts.last.toLowerCase();

      String contentType;
      if (ext == 'png') {
        contentType = 'image/png';
      } else if (ext == 'gif') {
        contentType = 'image/gif';
      } else {
        contentType = 'image/jpeg';
      }

      int timestamp = DateTime.now().millisecondsSinceEpoch;
      String fileName = '$userId/$timestamp.$ext';

      await SupabaseService.client.storage
          .from('property-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      String url = SupabaseService.client.storage
          .from('property-images')
          .getPublicUrl(fileName);

      urls.add(url);
    }

    return urls;
  }

  Future<void> _submitProperty() async {
    bool isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    if (_selectedImages.isEmpty) {
      CustomSnackbar.show(context, 'Please add at least one photo');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      List<String> imageUrls = await _uploadImages();

      String title = _titleController.text.trim();
      String priceText = _priceController.text.trim().replaceAll(',', '');
      num price = num.parse(priceText);
      String category = _categories[_selectedTypeIndex];

      String? description;
      if (_descriptionController.text.trim().isNotEmpty) {
        description = _descriptionController.text.trim();
      }

      String? address;
      if (_addressController.text.trim().isNotEmpty) {
        address = _addressController.text.trim();
      }

      int? bedroomCountValue;
      int? bathroomCountValue;
      if (_isApartmentType) {
        bedroomCountValue = _bedroomCount;
        bathroomCountValue = _bathroomCount;
      }

      List<String>? amenities;
      if (_selectedAmenities.isNotEmpty) {
        amenities = _selectedAmenities.toList();
      }

      List<String>? images;
      if (imageUrls.isNotEmpty) {
        images = imageUrls;
      }

      await PropertyService.createProperty(
        title: title,
        price: price,
        category: category,
        description: description,
        address: address,
        city: 'Sylhet',
        bedroomCount: bedroomCountValue,
        bathroomCount: bathroomCountValue,
        amenities: amenities,
        images: images,
      );

      if (mounted) {
        CustomSnackbar.show(
          context,
          'Property listed successfully!',
          isError: false,
        );
        Navigator.pop(context, true);
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
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _toggleAmenity(String amenity) {
    setState(() {
      bool isSelected = _selectedAmenities.contains(amenity);
      if (isSelected) {
        _selectedAmenities.remove(amenity);
      } else {
        _selectedAmenities.add(amenity);
      }
    });
  }

  void _selectType(int index) {
    setState(() {
      _selectedTypeIndex = index;
    });
  }

  void _updateBedroomCount(int value) {
    setState(() {
      _bedroomCount = value;
    });
  }

  void _updateBathroomCount(int value) {
    setState(() {
      _bathroomCount = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(colorScheme, textTheme),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: _isMobile
                ? _buildMobileLayout(colorScheme, textTheme)
                : _buildDesktopLayout(colorScheme, textTheme),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomSheet(colorScheme),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        onPressed: () {
          Navigator.pop(context);
        },
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
    );
  }

  Widget _buildMobileLayout(ColorScheme colorScheme, TextTheme textTheme) {
    double bottomPadding = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 100 + bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhotosSection(colorScheme, textTheme),
          const SizedBox(height: 24),
          _buildPropertyNameField(colorScheme),
          const SizedBox(height: 16),
          _buildPriceField(colorScheme),
          const SizedBox(height: 16),
          _buildPropertyTypeSection(colorScheme),
          const SizedBox(height: 24),
          if (_isApartmentType) _buildRoomsSection(colorScheme, textTheme),
          _buildAddressField(colorScheme),
          const SizedBox(height: 24),
          _buildAmenitiesSection(colorScheme, textTheme),
          const SizedBox(height: 24),
          _buildDescriptionField(colorScheme),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(ColorScheme colorScheme, TextTheme textTheme) {
    double bottomPadding = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 40,
        right: 40,
        top: 24,
        bottom: 100 + bottomPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotosSection(colorScheme, textTheme),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPropertyNameField(colorScheme),
                        const SizedBox(height: 20),
                        _buildPriceField(colorScheme),
                        const SizedBox(height: 20),
                        _buildAddressField(colorScheme),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPropertyTypeSection(colorScheme),
                        const SizedBox(height: 24),
                        if (_isApartmentType)
                          _buildRoomsSection(colorScheme, textTheme),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildAmenitiesSection(colorScheme, textTheme),
              const SizedBox(height: 32),
              _buildDescriptionField(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosSection(ColorScheme colorScheme, TextTheme textTheme) {
    double photoSize = _isMobile ? 112 : 140;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          height: photoSize,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: _buildPhotosList(colorScheme, photoSize),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPhotosList(ColorScheme colorScheme, double photoSize) {
    List<Widget> widgets = [];

    if (_selectedImages.length < 10) {
      widgets.add(_buildAddPhotoButton(colorScheme, photoSize));
    }

    for (int i = 0; i < _selectedImages.length; i++) {
      widgets.add(
        _buildPhotoPreview(_selectedImages[i], i, colorScheme, photoSize),
      );
    }

    return widgets;
  }

  Widget _buildAddPhotoButton(ColorScheme colorScheme, double photoSize) {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: photoSize,
        height: photoSize,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
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
    );
  }

  Widget _buildPhotoPreview(
    XFile image,
    int index,
    ColorScheme colorScheme,
    double photoSize,
  ) {
    return Container(
      width: photoSize,
      height: photoSize,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(image.path),
              width: photoSize,
              height: photoSize,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                _removeImage(index);
              },
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

  Widget _buildPropertyNameField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(colorScheme, "Property Name"),
        _buildTextFormField(
          colorScheme: colorScheme,
          controller: _titleController,
          hint: "e.g. Sunny 3BHK in Dhanmondi",
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a property name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriceField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(colorScheme, "Monthly Rent"),
        _buildTextFormField(
          colorScheme: colorScheme,
          controller: _priceController,
          hint: "25000",
          prefixText: "৳ ",
          keyboardType: TextInputType.number,
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter rent amount';
            }
            String cleanValue = value.replaceAll(',', '');
            num? price = num.tryParse(cleanValue);
            if (price == null || price <= 0) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPropertyTypeSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(colorScheme, "Property Type"),
        if (_isMobile)
          _buildMobileTypePills(colorScheme)
        else
          _buildDesktopTypePills(colorScheme),
      ],
    );
  }

  Widget _buildMobileTypePills(ColorScheme colorScheme) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categoryLabels.length,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(width: 10);
        },
        itemBuilder: (BuildContext context, int index) {
          return _buildMobileTypePill(
            colorScheme,
            _categoryLabels[index],
            index,
          );
        },
      ),
    );
  }

  Widget _buildMobileTypePill(ColorScheme colorScheme, String text, int index) {
    bool isSelected = _selectedTypeIndex == index;

    Color backgroundColor;
    if (isSelected) {
      backgroundColor = colorScheme.primary;
    } else {
      backgroundColor = colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.3,
      );
    }

    Color textColor;
    if (isSelected) {
      textColor = colorScheme.onPrimary;
    } else {
      textColor = colorScheme.onSurfaceVariant;
    }

    return GestureDetector(
      onTap: () {
        _selectType(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(100),
          border: isSelected
              ? null
              : Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTypePills(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: _buildTypePills(colorScheme)),
    );
  }

  List<Widget> _buildTypePills(ColorScheme colorScheme) {
    List<Widget> pills = [];

    for (int i = 0; i < _categoryLabels.length; i++) {
      pills.add(_buildTypePill(colorScheme, _categoryLabels[i], i));
    }

    return pills;
  }

  Widget _buildTypePill(ColorScheme colorScheme, String text, int index) {
    bool isSelected = _selectedTypeIndex == index;

    Color backgroundColor;
    if (isSelected) {
      backgroundColor = colorScheme.surface;
    } else {
      backgroundColor = Colors.transparent;
    }

    Color textColor;
    if (isSelected) {
      textColor = colorScheme.primary;
    } else {
      textColor = colorScheme.onSurfaceVariant;
    }

    FontWeight fontWeight;
    if (isSelected) {
      fontWeight = FontWeight.bold;
    } else {
      fontWeight = FontWeight.w500;
    }

    List<BoxShadow>? boxShadow;
    if (isSelected) {
      boxShadow = [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
      ];
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _selectType(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: boxShadow,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: fontWeight,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
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
                colorScheme,
                "Bedrooms",
                Icons.bed,
                _bedroomCount,
                _updateBedroomCount,
              ),
              Divider(
                height: 32,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              _buildCounterRow(
                colorScheme,
                "Bathrooms",
                Icons.bathtub_outlined,
                _bathroomCount,
                _updateBathroomCount,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCounterRow(
    ColorScheme colorScheme,
    String title,
    IconData icon,
    int count,
    void Function(int) onChanged,
  ) {
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
              _buildRoundButton(colorScheme, Icons.remove, () {
                int newValue = count - 1;
                if (newValue < 1) {
                  newValue = 1;
                }
                onChanged(newValue);
              }, false),
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
              _buildRoundButton(colorScheme, Icons.add, () {
                onChanged(count + 1);
              }, true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoundButton(
    ColorScheme colorScheme,
    IconData icon,
    VoidCallback onTap,
    bool isPrimary,
  ) {
    Color backgroundColor;
    if (isPrimary) {
      backgroundColor = colorScheme.surface;
    } else {
      backgroundColor = Colors.transparent;
    }

    Color iconColor;
    if (isPrimary) {
      iconColor = colorScheme.primary;
    } else {
      iconColor = colorScheme.onSurfaceVariant;
    }

    List<BoxShadow>? boxShadow;
    if (isPrimary) {
      boxShadow = [
        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
      ];
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: boxShadow,
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }

  Widget _buildAddressField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(colorScheme, "Address"),
        _buildTextFormField(
          colorScheme: colorScheme,
          controller: _addressController,
          hint: "e.g. House 12, Road 4, Sector 7, Uttara",
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          children: _buildAmenityChips(colorScheme),
        ),
      ],
    );
  }

  List<Widget> _buildAmenityChips(ColorScheme colorScheme) {
    List<Widget> chips = [];

    for (int i = 0; i < _amenitiesList.length; i++) {
      String amenity = _amenitiesList[i];
      chips.add(_buildAmenityChip(colorScheme, amenity));
    }

    return chips;
  }

  Widget _buildAmenityChip(ColorScheme colorScheme, String amenity) {
    bool isSelected = _selectedAmenities.contains(amenity);

    Color backgroundColor;
    if (isSelected) {
      backgroundColor = colorScheme.primary.withValues(alpha: 0.1);
    } else {
      backgroundColor = colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.3,
      );
    }

    Color borderColor;
    if (isSelected) {
      borderColor = colorScheme.primary.withValues(alpha: 0.3);
    } else {
      borderColor = colorScheme.outlineVariant.withValues(alpha: 0.3);
    }

    IconData icon;
    if (isSelected) {
      icon = Icons.check;
    } else {
      icon = getAmenityIcon(amenity);
    }

    Color iconColor;
    if (isSelected) {
      iconColor = colorScheme.primary;
    } else {
      iconColor = colorScheme.onSurfaceVariant;
    }

    Color textColor;
    if (isSelected) {
      textColor = colorScheme.primary;
    } else {
      textColor = colorScheme.onSurfaceVariant;
    }

    FontWeight fontWeight;
    if (isSelected) {
      fontWeight = FontWeight.w600;
    } else {
      fontWeight = FontWeight.w500;
    }

    return InkWell(
      onTap: () {
        _toggleAmenity(amenity);
      },
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(
              amenity,
              style: TextStyle(
                color: textColor,
                fontWeight: fontWeight,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(colorScheme, "Description (Optional)"),
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
    );
  }

  Widget _buildLabel(ColorScheme colorScheme, String text) {
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
    required ColorScheme colorScheme,
    required TextEditingController controller,
    required String hint,
    String? prefixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
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

  Widget _buildBottomSheet(ColorScheme colorScheme) {
    double bottomPadding = MediaQuery.of(context).padding.bottom;

    double horizontalPadding;
    if (_isMobile) {
      horizontalPadding = 20;
    } else {
      horizontalPadding = 40;
    }

    Widget buttonChild;
    if (_isSubmitting) {
      buttonChild = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.onPrimary,
        ),
      );
    } else {
      buttonChild = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "List Property",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 20),
        ],
      );
    }

    VoidCallback? onPressed;
    if (!_isSubmitting) {
      onPressed = _submitProperty;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        16 + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onPressed,
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
              child: buttonChild,
            ),
          ),
        ),
      ),
    );
  }
}
