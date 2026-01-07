import 'package:bashakhojo/common/widgets/custom_snackbar.dart';
import 'package:bashakhojo/screens/home/tenant_home.dart';
import 'package:bashakhojo/screens/inbox/chat_screen.dart';
import 'package:bashakhojo/services/chat_service.dart';
import 'package:bashakhojo/services/saved_properties_notifier.dart';
import 'package:bashakhojo/services/supabase_service.dart';
import 'package:bashakhojo/services/user_service.dart';
import 'package:flutter/material.dart';

class PropertyDetails extends StatefulWidget {
  final PropertyData property;

  const PropertyDetails({super.key, required this.property});

  @override
  State<PropertyDetails> createState() {
    return _PropertyDetailsState();
  }
}

class _PropertyDetailsState extends State<PropertyDetails> {
  int _currentImageIndex = 0;
  Map<String, dynamic>? _ownerProfile;
  bool _isLoadingOwner = true;
  bool _isSaved = false;
  bool _isSaveLoading = false;
  bool _isOpeningChat = false;
  String? _currentUserId;

  List<String> get _images {
    if (widget.property.images != null && widget.property.images!.isNotEmpty) {
      return widget.property.images!;
    }
    return ['https://placehold.co/600x800/png'];
  }

  bool get _isOwner {
    return _currentUserId == widget.property.owner_id;
  }

  @override
  void initState() {
    super.initState();
    _currentUserId = SupabaseService.client.auth.currentUser?.id;
    _loadOwnerProfile();
    _checkIfSaved();
  }

  Future<void> _loadOwnerProfile() async {
    if (widget.property.owner_id != null) {
      Map<String, dynamic>? profile = await UserService.getUser(
        widget.property.owner_id!,
      );

      if (mounted) {
        setState(() {
          _ownerProfile = profile;
          _isLoadingOwner = false;
        });
      }
    } else {
      setState(() {
        _isLoadingOwner = false;
      });
    }
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
    if (widget.property.id == null || _isSaveLoading) {
      return;
    }

    setState(() {
      _isSaveLoading = true;
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
          _isSaveLoading = false;
        });
      }
    }
  }

  Future<void> _openChat() async {
    if (_isOpeningChat) {
      return;
    }
    if (widget.property.owner_id == null) {
      return;
    }
    if (_currentUserId == null) {
      return;
    }

    setState(() {
      _isOpeningChat = true;
    });

    try {
      Map<String, dynamic> conversation =
          await ChatService.getOrCreateConversation(
            tenantId: _currentUserId!,
            landlordId: widget.property.owner_id!,
          );

      if (mounted) {
        String otherUserName = _ownerProfile?['full_name'] ?? 'Property Owner';
        String? otherUserAvatar = _ownerProfile?['avatar_url'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return ChatScreen(
                conversationId: conversation['id'],
                otherUserName: otherUserName,
                otherUserAvatar: otherUserAvatar,
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context, 'Failed to open chat');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningChat = false;
        });
      }
    }
  }

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

  IconData _getAmenityIcon(String amenity) {
    String lowerAmenity = amenity.toLowerCase();

    if (lowerAmenity == 'wifi') {
      return Icons.wifi;
    } else if (lowerAmenity == 'ac') {
      return Icons.ac_unit;
    } else if (lowerAmenity == 'parking') {
      return Icons.local_parking;
    } else if (lowerAmenity == 'gym') {
      return Icons.fitness_center;
    } else if (lowerAmenity == 'pool') {
      return Icons.pool;
    } else {
      return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          _buildImageSlider(size),
          _buildTopBar(colorScheme),
          _buildImageIndicators(size),
          _buildDetailsSheet(context, colorScheme, size),
          if (!_isOwner) _buildBottomBar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildImageSlider(Size size) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: size.height * 0.38,
      child: PageView.builder(
        onPageChanged: (int index) {
          setState(() {
            _currentImageIndex = index;
          });
        },
        itemCount: _images.length,
        itemBuilder: (BuildContext context, int index) {
          return Image.network(_images[index], fit: BoxFit.cover);
        },
      ),
    );
  }

  Widget _buildTopBar(ColorScheme colorScheme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBlurButton(
                context,
                Icons.arrow_back,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              Row(
                children: [
                  _buildBlurButton(context, Icons.share),
                  const SizedBox(width: 12),
                  _buildSaveButton(colorScheme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(ColorScheme colorScheme) {
    Color backgroundColor;
    if (_isSaved) {
      backgroundColor = colorScheme.primary;
    } else {
      backgroundColor = colorScheme.primary.withValues(alpha: 0.2);
    }

    Widget child;
    if (_isSaveLoading) {
      child = const Padding(
        padding: EdgeInsets.all(10),
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    } else {
      IconData icon;
      Color iconColor;

      if (_isSaved) {
        icon = Icons.bookmark;
        iconColor = Colors.white;
      } else {
        icon = Icons.bookmark_add_outlined;
        iconColor = Colors.teal;
      }

      child = Icon(icon, color: iconColor, size: 22);
    }

    return GestureDetector(
      onTap: _toggleSave,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: child,
      ),
    );
  }

  Widget _buildImageIndicators(Size size) {
    List<Widget> indicators = [];

    for (int i = 0; i < _images.length; i++) {
      Color color;
      if (_currentImageIndex == i) {
        color = Colors.white;
      } else {
        color = Colors.white.withValues(alpha: 0.5);
      }

      indicators.add(
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      );
    }

    return Positioned(
      top: (size.height * 0.38) - 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: indicators,
      ),
    );
  }

  Widget _buildDetailsSheet(
    BuildContext context,
    ColorScheme colorScheme,
    Size size,
  ) {
    TextTheme textTheme = Theme.of(context).textTheme;

    return Positioned.fill(
      top: (size.height * 0.38) - 24,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPriceAndTitle(colorScheme, textTheme),
              const SizedBox(height: 8),
              _buildLocation(colorScheme, textTheme),
              const SizedBox(height: 24),
              _buildSpecs(context),
              const SizedBox(height: 24),
              Divider(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              _buildDescription(colorScheme, textTheme),
              _buildAmenities(context, colorScheme, textTheme),
              _buildOwnerCard(colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceAndTitle(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: " ${widget.property.price} ",
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: "/ month",
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.property.title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatCategory(widget.property.category).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocation(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        Icon(Icons.location_on, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.property.location,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecs(BuildContext context) {
    String category = widget.property.category;

    if (category != 'family' && category != 'bachelor') {
      return const SizedBox.shrink();
    }

    List<Widget> specs = [];

    if (widget.property.bedroomCount != null) {
      specs.add(
        _buildSpecChip(
          context,
          Icons.bed,
          "${widget.property.bedroomCount} Bed",
        ),
      );
    }

    if (widget.property.bathroomCount != null) {
      specs.add(
        _buildSpecChip(
          context,
          Icons.bathtub_outlined,
          "${widget.property.bathroomCount} Bath",
        ),
      );
    }

    return Wrap(spacing: 12, runSpacing: 12, children: specs);
  }

  Widget _buildDescription(ColorScheme colorScheme, TextTheme textTheme) {
    if (widget.property.description == null ||
        widget.property.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Description",
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.property.description!,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAmenities(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (widget.property.amenities == null ||
        widget.property.amenities!.isEmpty) {
      return const SizedBox.shrink();
    }

    List<Widget> amenityChips = [];
    for (int i = 0; i < widget.property.amenities!.length; i++) {
      String amenity = widget.property.amenities![i];
      IconData icon = _getAmenityIcon(amenity);
      String label = _formatCategory(amenity);

      amenityChips.add(_buildAmenityChip(context, icon, label));
    }

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
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 12, children: amenityChips),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOwnerCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: _isLoadingOwner
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _buildOwnerRow(colorScheme, textTheme),
    );
  }

  Widget _buildOwnerRow(ColorScheme colorScheme, TextTheme textTheme) {
    String? avatarUrl = _ownerProfile?['avatar_url'];
    String fullName = _ownerProfile?['full_name'] ?? 'Property Owner';

    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl == null
                  ? Icon(Icons.person, color: colorScheme.onSurfaceVariant)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, size: 16, color: Colors.blue),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Landlord",
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!_isOwner)
          GestureDetector(
            onTap: _openChat,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 20,
                color: colorScheme.onSurface,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(ColorScheme colorScheme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            _buildCallButton(colorScheme),
            const SizedBox(width: 16),
            _buildMessageButton(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton(ColorScheme colorScheme) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        color: colorScheme.surface,
      ),
      child: Icon(Icons.call, color: colorScheme.onSurface),
    );
  }

  Widget _buildMessageButton(ColorScheme colorScheme) {
    Widget buttonChild;

    if (_isOpeningChat) {
      buttonChild = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    } else {
      buttonChild = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.message, size: 20, color: Colors.white),
          SizedBox(width: 8),
          Text(
            "Message Landlord",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      );
    }

    return Expanded(
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: _isOpeningChat ? null : _openChat,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.black,
            disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.5),
            elevation: 8,
            shadowColor: colorScheme.primary.withValues(alpha: 0.3),
            shape: const StadiumBorder(),
          ),
          child: buttonChild,
        ),
      ),
    );
  }

  Widget _buildBlurButton(
    BuildContext context,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.teal, size: 22),
      ),
    );
  }

  Widget _buildSpecChip(BuildContext context, IconData icon, String label) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(BuildContext context, IconData icon, String label) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
