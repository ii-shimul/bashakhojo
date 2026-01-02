import 'package:bashakhojo/pages/auth/auth.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
