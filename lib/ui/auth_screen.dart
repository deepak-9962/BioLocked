import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/bio_theme.dart';

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
    return Scaffold(
      backgroundColor: BioColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BIO-LOCKED',
                style: BioTextStyles.labelCaps.copyWith(
                  color: BioColors.primaryFixed,
                  fontSize: 13,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Sign in to sync your focus life across Android and web.',
                style: BioTextStyles.headlineLg.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Your phone stays the strict lock engine. The web dashboard keeps sessions, streaks, coins, presets, and schedules visible from the same account.',
                style: BioTextStyles.bodyMd.copyWith(
                  color: BioColors.onSurfaceVariant,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 34),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BioColors.surface,
                  border: Border.all(color: BioColors.outlineVariant.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Account access',
                      style: BioTextStyles.headlineLg.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use the same email, password, or Google account on Android and web.',
                      style: BioTextStyles.bodyMd.copyWith(
                        color: BioColors.onSurfaceVariant,
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BioColors.primaryFixed.withValues(alpha: 0.1),
                          border: Border.all(
                            color: BioColors.primaryFixed.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _message!,
                          style: TextStyle(color: BioColors.primaryFixed.withValues(alpha: 0.9)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Google button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 18),
                        label: const Text('Continue with Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BioColors.onSurface,
                          side: BorderSide(color: BioColors.outlineVariant.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
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
                    // Primary submit button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: Icon(_isSignUp ? Icons.person_add_alt : Icons.login, size: 18),
                        label: Text(_isSignUp ? 'Create account' : 'Sign in'),
                        style: FilledButton.styleFrom(
                          backgroundColor: BioColors.primaryFixed,
                          foregroundColor: BioColors.onPrimaryFixed,
                          disabledBackgroundColor: BioColors.surfaceContainerHighest,
                          disabledForegroundColor: BioColors.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
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
                        style: const TextStyle(color: BioColors.blue400),
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
      style: const TextStyle(color: BioColors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: BioColors.onSurfaceVariant),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BioColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BioColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: BioColors.blue400),
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
        const Expanded(child: Divider(color: BioColors.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: BioColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: BioColors.outlineVariant)),
      ],
    );
  }
}
