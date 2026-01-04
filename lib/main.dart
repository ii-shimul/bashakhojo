import 'package:bashakhojo/pages/auth/auth.dart';
import 'package:bashakhojo/services/supabase_service.dart';
import 'package:flutter/material.dart';

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
      home: const Login(),
    );
  }
}
