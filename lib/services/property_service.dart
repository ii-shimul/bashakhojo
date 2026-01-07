import 'package:bashakhojo/services/supabase_service.dart';

class PropertyService {
  static String? getCurrentUserId() {
    return SupabaseService.client.auth.currentUser?.id;
  }

  static Future<List<Map<String, dynamic>>> getProperties() async {
    final response = await SupabaseService.client
        .from('properties')
        .select()
        .eq('is_available', true)
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> properties = [];
    for (var item in response) {
      properties.add(Map<String, dynamic>.from(item));
    }
    return properties;
  }

  static Future<List<Map<String, dynamic>>> getPropertiesByCategory(
    String category,
  ) async {
    final response = await SupabaseService.client
        .from('properties')
        .select()
        .eq('category', category)
        .eq('is_available', true)
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> properties = [];
    for (var item in response) {
      properties.add(Map<String, dynamic>.from(item));
    }
    return properties;
  }

  static Future<Map<String, dynamic>?> getProperty(String propertyId) async {
    final response = await SupabaseService.client
        .from('properties')
        .select()
        .eq('id', propertyId)
        .maybeSingle();
    return response;
  }

  static Future<List<Map<String, dynamic>>> getPropertiesByOwner(
    String ownerId,
  ) async {
    final response = await SupabaseService.client
        .from('properties')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> properties = [];
    for (var item in response) {
      properties.add(Map<String, dynamic>.from(item));
    }
    return properties;
  }

  static Future<Map<String, dynamic>> createProperty({
    required String title,
    required num price,
    required String category,
    String? description,
    String? address,
    String? city,
    int? bedroomCount,
    int? bathroomCount,
    List<String>? amenities,
    List<String>? images,
  }) async {
    String? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> propertyData = {
      'owner_id': userId,
      'title': title,
      'description': description,
      'address': address,
      'city': city ?? 'Sylhet',
      'price': price,
      'category': category,
      'bedroom_count': bedroomCount,
      'bathroom_count': bathroomCount,
      'amenities': amenities,
      'images': images,
    };

    final response = await SupabaseService.client
        .from('properties')
        .insert(propertyData)
        .select()
        .single();

    return response;
  }

  static Future<void> updateProperty(
    String propertyId,
    Map<String, dynamic> updates,
  ) async {
    await SupabaseService.client
        .from('properties')
        .update(updates)
        .eq('id', propertyId);
  }

  static Future<void> deleteProperty(String propertyId) async {
    Map<String, dynamic>? property = await getProperty(propertyId);

    if (property != null && property['images'] != null) {
      List<String> images = List<String>.from(property['images']);

      for (String imageUrl in images) {
        try {
          Uri uri = Uri.parse(imageUrl);
          List<String> pathSegments = uri.pathSegments;

          int bucketIndex = pathSegments.indexOf('property-images');

          if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
            String filePath = pathSegments.sublist(bucketIndex + 1).join('/');

            await SupabaseService.client.storage.from('property-images').remove(
              [filePath],
            );
          }
        } catch (e) {}
      }
    }

    await SupabaseService.client.rpc(
      'remove_property_from_saved',
      params: {'property_id_to_remove': propertyId},
    );

    await SupabaseService.client
        .from('properties')
        .delete()
        .eq('id', propertyId);
  }
}
