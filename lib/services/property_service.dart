import 'package:bashakhojo/services/supabase_service.dart';

class PropertyService {
  static final _client = SupabaseService.client;

  static Future<List<Map<String, dynamic>>> getProperties() async {
    final response = await _client
        .from('properties')
        .select()
        .eq('is_available', true)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getPropertiesByCategory(
    String category,
  ) async {
    final response = await _client
        .from('properties')
        .select()
        .eq('category', category)
        .eq('is_available', true)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>?> getProperty(String propertyId) async {
    final response = await _client
        .from('properties')
        .select()
        .eq('id', propertyId)
        .maybeSingle();
    return response;
  }

  static Future<List<Map<String, dynamic>>> getPropertiesByOwner(
    String ownerId,
  ) async {
    final response = await _client
        .from('properties')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
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
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _client
        .from('properties')
        .insert({
          'owner_id': user.id,
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
        })
        .select()
        .single();
    return response;
  }

  static Future<void> updateProperty(
    String propertyId,
    Map<String, dynamic> updates,
  ) async {
    await _client.from('properties').update(updates).eq('id', propertyId);
  }

  static Future<void> deleteProperty(String propertyId) async {
    await _client.from('properties').delete().eq('id', propertyId);
  }
}
