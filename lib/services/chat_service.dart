import 'package:bashakhojo/services/supabase_service.dart';

class ChatService {
  static String? getCurrentUserId() {
    return SupabaseService.client.auth.currentUser?.id;
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    String? userId = getCurrentUserId();
    if (userId == null) {
      return [];
    }

    final response = await SupabaseService.client
        .from('conversations')
        .select('''
          *,
          tenant:profiles!conversations_tenant_id_fkey(id, full_name, avatar_url),
          landlord:profiles!conversations_landlord_id_fkey(id, full_name, avatar_url)
        ''')
        .or('tenant_id.eq.$userId,landlord_id.eq.$userId')
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> conversations = [];
    for (var item in response) {
      conversations.add(Map<String, dynamic>.from(item));
    }
    return conversations;
  }

  static Future<Map<String, dynamic>?> findConversation({
    required String tenantId,
    required String landlordId,
  }) async {
    final existingConversation = await SupabaseService.client
        .from('conversations')
        .select()
        .eq('tenant_id', tenantId)
        .eq('landlord_id', landlordId)
        .maybeSingle();

    return existingConversation;
  }

  static Future<void> deleteConversation(String conversationId) async {
    await SupabaseService.client
        .from("conversations")
        .delete()
        .eq("id", conversationId);
  }

  static Future<Map<String, dynamic>> getOrCreateConversation({
    required String tenantId,
    required String landlordId,
  }) async {
    final existingConversation = await findConversation(
      tenantId: tenantId,
      landlordId: landlordId,
    );

    if (existingConversation != null) {
      return existingConversation;
    }

    final newConversation = await SupabaseService.client
        .from('conversations')
        .insert({'tenant_id': tenantId, 'landlord_id': landlordId})
        .select()
        .single();

    return newConversation;
  }

  static Future<List<Map<String, dynamic>>> getMessages(
    String conversationId,
  ) async {
    final response = await SupabaseService.client
        .from('messages')
        .select('''
          *,
          sender:profiles!messages_sender_id_fkey(id, full_name, avatar_url)
        ''')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    List<Map<String, dynamic>> messages = [];
    for (var item in response) {
      messages.add(Map<String, dynamic>.from(item));
    }
    return messages;
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    String? userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await SupabaseService.client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'content': content,
        })
        .select('''
          *,
          sender:profiles!messages_sender_id_fkey(id, full_name, avatar_url)
        ''')
        .single();

    return response;
  }

  static Future<void> markMessagesAsRead(String conversationId) async {
    String? userId = getCurrentUserId();
    if (userId == null) {
      return;
    }

    await SupabaseService.client
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId);
  }

  static Future<int> getUnreadCount(String conversationId) async {
    String? userId = getCurrentUserId();
    if (userId == null) {
      return 0;
    }

    final response = await SupabaseService.client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .eq('is_read', false)
        .neq('sender_id', userId);

    List<dynamic> messages = response as List;
    return messages.length;
  }

  static Future<Map<String, dynamic>?> getLastMessage(
    String conversationId,
  ) async {
    final response = await SupabaseService.client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }

  static Stream<List<Map<String, dynamic>>> subscribeToMessages(
    String conversationId,
  ) {
    return SupabaseService.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
  }
}
