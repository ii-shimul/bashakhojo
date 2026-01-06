import 'package:bashakhojo/services/supabase_service.dart';

class UserService {
  static final _client = SupabaseService.client;

  static Future<Map<String, dynamic>?> getUser(String userId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return response;
  }

  static Future<void> updateAvatar(String avatarUrl) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    await _client
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', user.id);
  }

  static Future<void> updateRole(String role) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    await _client.from('profiles').update({'role': role}).eq('id', user.id);
  }

  static Future<void> saveProperty(String propertyId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final profile = await _client
        .from('profiles')
        .select('saved_properties')
        .eq('id', user.id)
        .single();

    final List<String> savedProperties = List<String>.from(
      profile['saved_properties'] ?? [],
    );

    if (!savedProperties.contains(propertyId)) {
      savedProperties.add(propertyId);
      await _client
          .from('profiles')
          .update({'saved_properties': savedProperties})
          .eq('id', user.id);
    }
  }

  static Future<void> unsaveProperty(String propertyId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final profile = await _client
        .from('profiles')
        .select('saved_properties')
        .eq('id', user.id)
        .single();

    final List<String> savedProperties = List<String>.from(
      profile['saved_properties'] ?? [],
    );

    savedProperties.remove(propertyId);
    await _client
        .from('profiles')
        .update({'saved_properties': savedProperties})
        .eq('id', user.id);
  }

  static Future<bool> isPropertySaved(String propertyId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final profile = await _client
        .from('profiles')
        .select('saved_properties')
        .eq('id', user.id)
        .single();

    final List<String> savedProperties = List<String>.from(
      profile['saved_properties'] ?? [],
    );

    return savedProperties.contains(propertyId);
  }
}
