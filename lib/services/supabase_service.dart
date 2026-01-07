import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static SupabaseClient get client {
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      throw FileNotFoundError();
    }

    String supabaseUrl = dotenv.env['SUPABASE_URL']!;
    String supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  }
}
