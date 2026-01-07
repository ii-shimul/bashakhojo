import 'package:bashakhojo/services/supabase_service.dart';

class UserService {
  static String? getCurrentUserId() {
    return SupabaseService.client.auth.currentUser?.id;
  }

  static Future<Map<String, dynamic>?> getUser(String userId) async {
    final response = await SupabaseService.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  static Future<void> updateAvatar(String avatarUrl) async {
    String? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await SupabaseService.client
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', userId);
  }

  static Future<void> updateRole(String role) async {
    String? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await SupabaseService.client
        .from('profiles')
        .update({'role': role})
        .eq('id', userId);
  }

  static Future<void> saveProperty(String propertyId) async {
    String? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final profile = await SupabaseService.client
        .from('profiles')
        .select('saved_properties')
        .eq('id', userId)
        .single();

    List<String> savedProperties = [];
    if (profile['saved_properties'] != null) {
      savedProperties = List<String>.from(profile['saved_properties']);
    }

    if (!savedProperties.contains(propertyId)) {
      savedProperties.add(propertyId);

      await SupabaseService.client
          .from('profiles')
          .update({'saved_properties': savedProperties})
          .eq('id', userId);
    }
  }

  static Future<void> unsaveProperty(String propertyId) async {
    String? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final profile = await SupabaseService.client
        .from('profiles')
        .select('saved_properties')
        .eq('id', userId)
        .single();

    List<String> savedProperties = [];
    if (profile['saved_properties'] != null) {
      savedProperties = List<String>.from(profile['saved_properties']);
    }

    savedProperties.remove(propertyId);

    await SupabaseService.client
        .from('profiles')
        .update({'saved_properties': savedProperties})
        .eq('id', userId);
  }

  static Future<bool> isPropertySaved(String propertyId) async {
    String? userId = getCurrentUserId();
    if (userId == null) {
      return false;
    }

    final profile = await SupabaseService.client
        .from('profiles')
        .select('saved_properties')
        .eq('id', userId)
        .single();

    List<String> savedProperties = [];
    if (profile['saved_properties'] != null) {
      savedProperties = List<String>.from(profile['saved_properties']);
    }

    return savedProperties.contains(propertyId);
  }
}
