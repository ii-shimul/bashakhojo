import 'package:bashakhojo/screens/auth/signup.dart';
import 'package:bashakhojo/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../common/widgets/custom_text_field.dart';
import '../../common/widgets/custom_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() {
    return _LoginScreenState();
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      CustomSnackbar.show(context, 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await _authService.signInWithEmailPass(email, password);

      if (!mounted) {
        return;
      }

      if (response.user != null) {
        CustomSnackbar.show(context, 'Login successful!', isError: false);

        if (mounted) {
          Navigator.of(context).popUntil((route) {
            return route.isFirst;
          });
        }
      } else {
        CustomSnackbar.show(context, 'Login failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      CustomSnackbar.show(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _navigateToSignup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return const SignupScreen();
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
                    _buildTitle(colors, textTheme),
                    const SizedBox(height: 8),
                    _buildSubtitle(colors, textTheme),
                    const SizedBox(height: 32),
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 12),
                    _buildForgotPassword(colors, textTheme),
                    const SizedBox(height: 16),
                    _buildLoginButton(colors),
                    const SizedBox(height: 32),
                    _buildSignupLink(colors, textTheme),
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
          _buildBackButton(colors),
          _buildLogo(colors, textTheme),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBackButton(ColorScheme colors) {
    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(Icons.arrow_back, color: colors.onSurface),
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme colors, TextTheme textTheme) {
    return Row(
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
    );
  }

  Widget _buildImage(ColorScheme colors) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: colors.primary.withValues(alpha: 0.1),
        image: const DecorationImage(
          image: AssetImage("assets/image/house-searching2.png"),
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

  Widget _buildTitle(ColorScheme colors, TextTheme textTheme) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: "Welcome "),
          TextSpan(text: "Back", style: TextStyle(color: colors.primary)),
        ],
      ),
      textAlign: TextAlign.center,
      style: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: colors.onSurface,
      ),
    );
  }

  Widget _buildSubtitle(ColorScheme colors, TextTheme textTheme) {
    return Text(
      "Sign in to continue your home search.",
      textAlign: TextAlign.center,
      style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
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
      hint: "Enter your password",
      icon: Icons.lock_outline,
      isPassword: true,
      isObscure: !_isPasswordVisible,
      controller: _passwordController,
      onTogglePassword: _togglePasswordVisibility,
    );
  }

  Widget _buildForgotPassword(ColorScheme colors, TextTheme textTheme) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        child: Text(
          "Forgot Password?",
          style: textTheme.bodySmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(ColorScheme colors) {
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
        "Log In",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
    }

    VoidCallback? onPressed;
    if (!_isLoading) {
      onPressed = _login;
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

  Widget _buildSignupLink(ColorScheme colors, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: _navigateToSignup,
          child: Text(
            "Sign Up",
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
