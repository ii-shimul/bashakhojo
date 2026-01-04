import 'package:bashakhojo/core/main_shell.dart';
import 'package:bashakhojo/pages/auth/auth.dart';
import 'package:bashakhojo/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();

  runApp(const BashaKhojo());
}

class BashaKhojo extends StatelessWidget {
  const BashaKhojo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BashaKhojo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A99D),
          primary: const Color(0xFF00A99D),
          surface: Colors.white,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = SupabaseService.client.auth.currentSession;

        if (session != null) {
          return const MainShell();
        }

        return const Auth();
      },
    );
  }
}
