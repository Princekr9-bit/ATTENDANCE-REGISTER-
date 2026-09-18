import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import 'phone_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;

  Future<void> _googleSignIn() async {
    setState(() => _busy = true);
    try {
      final result = await AuthService.instance.signInWithGoogle();
      if (result == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in cancelled')),
        );
      }
      // On success the auth gate switches to HomeScreen automatically.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🏗️', style: TextStyle(fontSize: 44)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nirman Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'SK Sangam Enterprises\nSite • Labour • Attendance • Payments',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFAEB9CE), fontSize: 14),
                ),
                const SizedBox(height: 48),
                if (_busy)
                  const CircularProgressIndicator(color: Colors.white)
                else ...[
                  // Google (Gmail) login
                  ElevatedButton.icon(
                    onPressed: _googleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.ink,
                    ),
                    icon: const Text('G',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orangeDark,
                        )),
                    label: const Text('Continue with Google (Gmail)'),
                  ),
                  const SizedBox(height: 14),
                  // Phone OTP login
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PhoneLoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                    ),
                    icon: const Icon(Icons.phone_android),
                    label: const Text('Continue with Mobile Number'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
