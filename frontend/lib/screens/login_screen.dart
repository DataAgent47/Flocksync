import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  static String? pendingMessage;
  static bool pendingMessageIsError = false;

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _infoMessage;
  bool _infoIsError = false;

  @override
  void initState() {
    super.initState();
    _consumePendingMessage();
  }

  void _consumePendingMessage() {
    if (LoginScreen.pendingMessage != null) {
      _infoMessage = LoginScreen.pendingMessage;
      _infoIsError = LoginScreen.pendingMessageIsError;
      LoginScreen.pendingMessage = null;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final credential = await _authService.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final user = credential.user;
      if (user != null && !user.emailVerified) {
        // Set message before async ops to survive widget recreation
        LoginScreen.pendingMessage =
            'Your email is not yet verified. A new verification link has been sent to ${user.email}.';
        LoginScreen.pendingMessageIsError = true;
        try {
          await user.sendEmailVerification();
        } catch (_) {
          LoginScreen.pendingMessage =
              'Your email is not yet verified. Please check your inbox or try again later.';
        }
        await _authService.signOut();
        // signOut triggers auth state change; a new LoginScreen will read pendingMessage
        return;
      }
      // Auth state stream in main.dart handles navigation
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'sign_in_cancelled') {
        setState(() => _errorMessage = _friendlyError(e.code));
      }
    } catch (e) {
      // ignore: avoid_print
      print('[Google Sign-In Error] $e');
      setState(() => _errorMessage = 'Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled. Please try again.';
      default:
        return 'Sign-in failed ($code). Please try again.';
    }
  }

  Widget _buildBanner({
    required String message,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required Color textColor,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Backup: consume pending message if initState missed it
    if (_infoMessage == null && LoginScreen.pendingMessage != null) {
      _infoMessage = LoginScreen.pendingMessage;
      _infoIsError = LoginScreen.pendingMessageIsError;
      LoginScreen.pendingMessage = null;
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    const Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: AppColors.darkGreen,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your account',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.green2,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Info / warning / error banner
                    if (_errorMessage != null)
                      _buildBanner(
                        message: _errorMessage!,
                        bgColor: Color.alphaBlend(
                          const Color(0x26C62828),
                          AppColors.background,
                        ),
                        borderColor: Color.alphaBlend(
                          const Color(0x66C62828),
                          AppColors.middleground,
                        ),
                        iconColor: AppColors.darkGreen,
                        textColor: AppColors.darkGreen,
                        icon: Icons.error_outline,
                      )
                    else if (_infoMessage != null)
                      _infoIsError
                          ? _buildBanner(
                              message: _infoMessage!,
                              bgColor: Color.alphaBlend(
                                const Color(0x26F9A825),
                                AppColors.background,
                              ),
                              borderColor: Color.alphaBlend(
                                const Color(0x66F9A825),
                                AppColors.middleground,
                              ),
                              iconColor: AppColors.darkGreen,
                              textColor: AppColors.darkGreen,
                              icon: Icons.warning_amber_rounded,
                            )
                          : _buildBanner(
                              message: _infoMessage!,
                              bgColor: Color.alphaBlend(
                                const Color(0x262E7D32),
                                AppColors.background,
                              ),
                              borderColor: Color.alphaBlend(
                                const Color(0x662E7D32),
                                AppColors.middleground,
                              ),
                              iconColor: AppColors.darkGreen,
                              textColor: AppColors.darkGreen,
                              icon: Icons.mark_email_read_outlined,
                            ),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required.';
                        if (!v.contains('@')) return 'Enter a valid email.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Sign in button
                    FilledButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: const Text(
                            'or',
                            style: TextStyle(color: AppColors.green2),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google sign-in button (frontend only for now)
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const _GoogleIcon(),
                      label: const Text('Continue with Google'),
                    ),
                    const SizedBox(height: 24),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: const TextStyle(color: AppColors.green2),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          ),
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              color: AppColors.darkGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple inline Google 'G' logo using a colored container.
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335),
            Color(0xFF4285F4),
          ],
        ),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
