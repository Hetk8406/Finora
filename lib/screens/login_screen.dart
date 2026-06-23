import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _otpController = TextEditingController();
  
  String _phoneNumber = '';
  String _verificationId = '';
  bool _isOTPSent = false;
  bool _isLoading = false;

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final user = await _authService.signInWithGoogle(context);
    setState(() => _isLoading = false);

    if (user != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  void _sendOTP() async {
    if (_phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid phone number')));
      return;
    }

    setState(() => _isLoading = true);
    await _authService.verifyPhone(
      phoneNumber: _phoneNumber,
      onCodeSent: (id) {
        setState(() {
          _verificationId = id;
          _isOTPSent = true;
          _isLoading = false;
        });
      },
      onError: (msg) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      },
    );
  }

  void _verifyOTP() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.isEmpty || smsCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter 6-digit OTP')));
      return;
    }

    setState(() => _isLoading = true);
    final user = await _authService.signInWithOTP(_verificationId, smsCode);
    setState(() => _isLoading = false);

    if (user != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo & Branding
              Hero(
                tag: 'logo',
                child: Image.asset('assets/logo.png', width: 90, height: 90),
              ),
              const SizedBox(height: 16),
              const Text(
                'Finora',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF2563EB), letterSpacing: 0.5),
              ),
              const Text(
                'Professional Financial Management',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
              ),
              
              const SizedBox(height: 60),

              if (!_isOTPSent) ...[
                // Phone Input Section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Sign in via Phone Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 16),
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  initialCountryCode: 'IN',
                  onChanged: (phone) => _phoneNumber = phone.completeNumber,
                ),
                const SizedBox(height: 16),
                _button(
                  label: 'Send Verification Code',
                  onPressed: _sendOTP,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 32),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: TextStyle(color: Colors.grey))),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 32),

                // Google Sign-In
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: Image.asset('assets/logo.png', width: 24, height: 24), // Google Logo Placeholder or use Finora Logo
                  label: const Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ] else ...[
                // OTP Input Section
                const Text('Enter Code Sent to Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text('We have sent an SMS code to $_phoneNumber', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: '000000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                _button(
                  label: 'Verify & Login',
                  onPressed: _verifyOTP,
                  isLoading: _isLoading,
                ),
                TextButton(
                  onPressed: () => setState(() => _isOTPSent = false),
                  child: const Text('Change Phone Number', style: TextStyle(color: Colors.grey)),
                ),
              ],
              
              const SizedBox(height: 60),
              const Text(
                'Security & Privacy Guaranteed',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button({required String label, required VoidCallback onPressed, bool isLoading = false}) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: isLoading 
        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
        : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
