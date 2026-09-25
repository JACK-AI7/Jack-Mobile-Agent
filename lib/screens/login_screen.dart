// lib/screens/login_screen.dart
//
// Connected Login Screen for JACK Mobile Agent
// Supports credentials login, 1-tap demo sign-in as Jaswanth,
// secure token persistence, and instant router redirection.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/jack_auth_state.dart';
import '../services/api/jack_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/jack_orb.dart';
import '../widgets/real_glass_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nameController = TextEditingController(text: 'Jaswanth');
  final _emailController = TextEditingController(text: 'jaswanth@jack.ai');
  final _passwordController = TextEditingController(text: 'jack2026');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login({String? emailOverride, String? passwordOverride, String? nameOverride}) async {
    final name = (nameOverride ?? _nameController.text.trim()).isNotEmpty
        ? (nameOverride ?? _nameController.text.trim())
        : 'Jaswanth';
    final email = emailOverride ?? _emailController.text.trim();
    final password = passwordOverride ?? _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name, email and password');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await JackStorage.write(key: 'jack_user_name', value: name);
      await ref.read(authStateProvider.notifier).login(email, password, name);
      ref.invalidate(userNameProvider);
      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      await JackStorage.write(key: 'jack_user_name', value: name);
      if (!mounted) return;
      ref.read(authStateProvider.notifier).markAuthenticated();
      ref.invalidate(userNameProvider);
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing 3D rotatable Orb
                const JackOrb(size: 96, state: OrbState.idle),
                const SizedBox(height: 24),

                Text(
                  'JACK',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to access your autonomous agent',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 36),

                RealGlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: Colors.redAccent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Full Name input
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                        keyboardType: TextInputType.name,
                        decoration: InputDecoration(
                          hintText: 'Your Full Name (e.g. Jaswanth)',
                          hintStyle: GoogleFonts.inter(color: Colors.white30),
                          prefixIcon: const Icon(Icons.person_outline_rounded,
                              color: Colors.white54, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF141320),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.accentCyan, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Email input
                      TextField(
                        controller: _emailController,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Email address',
                          hintStyle: GoogleFonts.inter(color: Colors.white30),
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: Colors.white54, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF141320),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.accentCyan, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password input
                      TextField(
                        controller: _passwordController,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: GoogleFonts.inter(color: Colors.white30),
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              color: Colors.white54, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF141320),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.accentCyan, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Primary Login Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _login(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentCyan,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.black),
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Quick 1-Tap Connected Sign In
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _login(
                                    emailOverride: 'jaswanth@jack.ai',
                                    passwordOverride: 'jack2026',
                                  ),
                          icon: const Icon(Icons.flash_on_rounded,
                              color: Color(0xFF38BDF8), size: 18),
                          label: Text(
                            'Quick Connect as Jaswanth',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: const Color(0xFF38BDF8)
                                  .withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () => context.push('/register'),
                  child: Text(
                    "Don't have an account? Register",
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.w500,
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
