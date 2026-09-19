import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/jack_auth_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/jack_orb.dart';
import '../widgets/real_glass_card.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).register(name, email, password);
      // Auth state change will trigger the GoRouter redirect to home
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const JackOrb(size: 80, state: OrbState.idle),
                const SizedBox(height: 32),
                Text(
                  'Initialize Identity',
                  style: AppTypography.display(
                    size: 28,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your JACK agent profile',
                  style: AppTypography.body(
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                RealGlassCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.body(size: 13, color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _nameController,
                        style: AppTypography.body(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Full Name',
                          hintStyle: AppTypography.body(color: AppColors.textTertiary),
                          filled: true,
                          fillColor: AppColors.surfaceElevated.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        style: AppTypography.body(color: AppColors.textPrimary),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Email address',
                          hintStyle: AppTypography.body(color: AppColors.textTertiary),
                          filled: true,
                          fillColor: AppColors.surfaceElevated.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        style: AppTypography.body(color: AppColors.textPrimary),
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: AppTypography.body(color: AppColors.textTertiary),
                          filled: true,
                          fillColor: AppColors.surfaceElevated.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _isLoading ? null : _register,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: _isLoading ? null : AppColors.primaryGradient,
                            color: _isLoading ? AppColors.surfaceBorder : null,
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Register',
                                    style: AppTypography.body(
                                      color: Colors.white,
                                      size: 16,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Text(
                    'Already have an account? Login',
                    style: AppTypography.body(
                      size: 14,
                      color: AppColors.accentCyan,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
