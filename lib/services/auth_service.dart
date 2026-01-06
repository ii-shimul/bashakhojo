import 'package:bashakhojo/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  Future<AuthResponse> signUpWithEmailPass(
    String email,
    String password,
    String fullName,
  ) async {
    return await SupabaseService.client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signInWithEmailPass(
    String email,
    String password,
  ) async {
    return await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  void signOut() async {
    await SupabaseService.client.auth.signOut();
  }
}
