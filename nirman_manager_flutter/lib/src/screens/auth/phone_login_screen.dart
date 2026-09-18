import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import 'otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = '+91${_phoneController.text.trim()}';
    setState(() => _busy = true);

    await AuthService.instance.startPhoneVerification(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() => _busy = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              phoneNumber: phone,
              verificationId: verificationId,
            ),
          ),
        );
      },
      onAutoVerified: () {
        if (!mounted) return;
        // Signed in automatically; pop back so the auth gate shows home.
        Navigator.of(context).popUntil((r) => r.isFirst);
      },
      onFailed: (message) {
        if (!mounted) return;
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Number Login')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Apna mobile number daalein.\nHum aapko ek OTP bhejenge.',
                  style: TextStyle(fontSize: 15, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    prefixText: '+91 ',
                    labelText: 'Mobile Number',
                    hintText: '98765 43210',
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length != 10) {
                      return 'Enter a valid 10-digit mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _busy ? null : _sendOtp,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
