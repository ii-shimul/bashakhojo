import 'package:bashakhojo/screens/auth/login.dart';
import 'package:bashakhojo/screens/auth/signup.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(colors),
                    const SizedBox(height: 16),
                    _buildTitle(colors),
                    const SizedBox(height: 8),
                    _buildSubtitle(),
                    const SizedBox(height: 40),
                    _buildImage(),
                    const SizedBox(height: 40),
                    _buildButtons(context, colors),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              _buildTermsText(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme colors) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildTitle(ColorScheme colors) {
    return Text(
      "BashaKhojo",
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: colors.primary,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      "Find your perfect home",
      style: TextStyle(fontSize: 18, color: Colors.black54),
    );
  }

  Widget _buildImage() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage("assets/image/house-searching.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context, ColorScheme colors) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSignUpButton(context, colors),
          _buildLoginButton(context, colors),
        ],
      ),
    );
  }

  Widget _buildSignUpButton(BuildContext context, ColorScheme colors) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const SignupScreen();
            },
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const StadiumBorder(),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      ),
      child: Text("Sign Up", style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildLoginButton(BuildContext context, ColorScheme colors) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const LoginScreen();
            },
          ),
        );
      },
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        backgroundColor: colors.primary.withValues(alpha: 0.05),
        shape: const StadiumBorder(),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      ),
      child: Text("Login", style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildTermsText(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: Colors.black38),
          children: [
            const TextSpan(text: "By continuing, you agree to our "),
            TextSpan(
              text: "Terms of Service",
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(text: " and "),
            TextSpan(
              text: "Privacy Policy",
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(text: "."),
          ],
        ),
      ),
    );
  }
}
