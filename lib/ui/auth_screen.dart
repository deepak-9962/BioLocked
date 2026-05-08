import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/web_app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.length < 6) {
      setState(() {
        _message = 'Enter an email and a password with at least 6 characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final auth = Supabase.instance.client.auth;
      if (_isSignUp) {
        await auth.signUp(email: email, password: password);
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
    } on AuthException catch (error) {
      setState(() => _message = error.message);
    } catch (_) {
      setState(() => _message = 'Authentication failed. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'bio-locked://login-callback',
      );
    } on AuthException catch (error) {
      setState(() => _message = error.message);
    } catch (_) {
      setState(() => _message = 'Google sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: WebAppScaffold(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BIO-LOCKED', style: WebAppText.brand),
              const SizedBox(height: 48),
              const Text(
                'Sign in to sync your focus life across Android and web.',
                style: WebAppText.title,
              ),
              const SizedBox(height: 18),
              const Text(
                'Your phone stays the strict lock engine. The web dashboard keeps sessions, streaks, coins, presets, and schedules visible from the same account.',
                style: WebAppText.body,
              ),
              const SizedBox(height: 34),
              WebCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Account access', style: WebAppText.sectionTitle),
                    const SizedBox(height: 8),
                    const Text(
                      'Use the same email, password, or Google account on Android and web.',
                      style: WebAppText.body,
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      WebCard(
                        backgroundColor: WebAppColors.gold.withValues(alpha: 0.1),
                        borderColor: WebAppColors.gold.withValues(alpha: 0.3),
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _message!,
                          style: const TextStyle(color: Color(0xFFF3D98A)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    WebSecondaryButton(
                      label: 'Continue with Google',
                      icon: Icons.g_mobiledata,
                      onPressed: _isLoading ? null : _signInWithGoogle,
                    ),
                    const SizedBox(height: 20),
                    const _DividerLabel(label: 'EMAIL'),
                    const SizedBox(height: 20),
                    _field(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      controller: _passwordController,
                      label: 'Password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    WebPrimaryButton(
                      label: _isSignUp ? 'Create account' : 'Sign in',
                      icon: _isSignUp ? Icons.person_add_alt : Icons.login,
                      onPressed: _isLoading ? null : _submit,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account',
                        style: const TextStyle(color: WebAppColors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: WebAppColors.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: WebAppColors.textMuted),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WebAppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WebAppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: WebAppColors.blue),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  final String label;

  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: WebAppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: WebAppColors.textFaint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: WebAppColors.border)),
      ],
    );
  }
}
