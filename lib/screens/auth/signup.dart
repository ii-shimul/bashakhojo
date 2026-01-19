import 'package:bashakhojo/screens/auth/login.dart';
import 'package:bashakhojo/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../common/widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() {
    return _SignupScreenState();
  }
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    if (password.length < 8) {
      _showSnackBar('Password must be at least 8 characters');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await _authService.signUpWithEmailPass(
        email,
        password,
        name,
      );

      if (!mounted) {
        return;
      }

      if (response.user != null) {
        _showSnackBar('Account created successfully!', isError: false);

        if (mounted) {
          Navigator.of(context).popUntil((route) {
            return route.isFirst;
          });
        }
      } else {
        _showSnackBar('Sign up failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    Color backgroundColor;
    if (isError) {
      backgroundColor = Colors.red.shade600;
    } else {
      backgroundColor = Colors.green.shade600;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return const LoginScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors, textTheme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _buildImage(colors),
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
                    _buildNameField(),
                    const SizedBox(height: 20),
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 24),
                    _buildSignupButton(colors),
                    const SizedBox(height: 32),
                    _buildLoginLink(colors, textTheme),
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

  Widget _buildHeader(ColorScheme colors, TextTheme textTheme) {
    return Padding(
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
    );
  }

  Widget _buildImage(ColorScheme colors) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: colors.primary.withValues(alpha: 0.1),
        image: const DecorationImage(
          image: AssetImage("assets/image/house-searching.png"),
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
    );
  }

  Widget _buildNameField() {
    return CustomTextField(
      label: "Full Name",
      hint: "Enter your full name",
      icon: Icons.person_outline,
      controller: _nameController,
    );
  }

  Widget _buildEmailField() {
    return CustomTextField(
      label: "Email Address",
      hint: "hello@example.com",
      icon: Icons.mail_outline,
      inputType: TextInputType.emailAddress,
      controller: _emailController,
    );
  }

  Widget _buildPasswordField() {
    return CustomTextField(
      label: "Password",
      hint: "At least 8 characters",
      icon: Icons.lock_outline,
      isPassword: true,
      isObscure: !_isPasswordVisible,
      controller: _passwordController,
      onTogglePassword: _togglePasswordVisibility,
    );
  }

  Widget _buildSignupButton(ColorScheme colors) {
    Widget buttonChild;

    if (_isLoading) {
      buttonChild = SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          color: colors.onPrimary,
          strokeWidth: 2.5,
        ),
      );
    } else {
      buttonChild = const Text(
        "Sign Up",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
    }

    VoidCallback? onPressed;
    if (!_isLoading) {
      onPressed = _signUp;
    }

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.primary.withValues(alpha: 0.6),
          elevation: 8,
          shadowColor: colors.primary.withValues(alpha: 0.4),
          shape: const StadiumBorder(),
        ),
        child: buttonChild,
      ),
    );
  }

  Widget _buildLoginLink(ColorScheme colors, TextTheme textTheme) {
    return Row(
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
          onTap: _navigateToLogin,
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
    );
  }
}
