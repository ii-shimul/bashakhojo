import 'package:bashakhojo/pages/auth/login.dart';
import 'package:bashakhojo/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../common/widgets/custom_text_field.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    if (password.length < 8) {
      _showSnackBar('Password must be at least 8 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.signUpWithEmailPass(
        email,
        password,
        name,
      );

      if (!mounted) return;

      if (response.user != null) {
        _showSnackBar(
          'Account created successfully! Please check your email to verify.',
          isError: false,
        );
        // Navigate to home page and clear the navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        _showSnackBar('Sign up failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: colors.surface,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.arrow_back, color: colors.onSurface),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "BASHAKHOJO",
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),

                        color: colors.primary.withValues(alpha: 0.1),
                        image: const DecorationImage(
                          image: AssetImage(
                            "assets/image/house-searching2.png",
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              colors.surface.withValues(alpha: 0.4),
                              colors.surface,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: "Join "),
                          TextSpan(
                            text: "BashaKhojo",
                            style: TextStyle(color: colors.primary),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Find your perfect home in Bangladesh.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 32),

                    CustomTextField(
                      label: "Full Name",
                      hint: "Enter your full name",
                      icon: Icons.person_outline,
                      controller: _nameController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: "Email Address",
                      hint: "hello@example.com",
                      icon: Icons.mail_outline,
                      inputType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: "Password",
                      hint: "At least 8 characters",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isObscure: !_isPasswordVisible,
                      controller: _passwordController,
                      onTogglePassword: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          disabledBackgroundColor: colors.primary.withValues(
                            alpha: 0.6,
                          ),
                          elevation: 8,
                          shadowColor: colors.primary.withValues(alpha: 0.4),
                          shape: const StadiumBorder(),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: colors.onPrimary,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Log In",
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
