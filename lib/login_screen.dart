import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

// ─────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────
const Color kAccent   = Color(0xFFCAF135);
const Color kFieldBg  = Color(0xFF0D1A30);
const Color kCardBg   = Color(0xFF070F1E);
const Color kPageBg   = Color(0xFF030810);

// ─────────────────────────────────────────────
// LOGIN SCREEN
// ─────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _obscurePassword = true; // ✅ حالة إظهار/إخفاء الباسورد

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openForgotPassword() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => const _ResetPasswordDialog(),
    );
  }

  void _signIn() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username == 'admin' && password == 'admin123') {
      setState(() => _errorMessage = null);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      setState(() => _errorMessage = 'Invalid username or password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.4,
            colors: [Color(0xFF0A1A3A), Color(0xFF060E20), kPageBg],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Login to IRAS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Incident Response Automation System',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 32),

                    const _FieldLabel('Username'),
                    const SizedBox(height: 6),
                    _DarkTextField(
                      controller: _usernameController,
                      hint: 'username',
                    ),
                    const SizedBox(height: 16),

                    const _FieldLabel('Password'),
                    const SizedBox(height: 6),

                    // ✅ خانة الباسورد مع أيقونة العين
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'password',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: kFieldBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: kAccent, width: 1.5),
                        ),
                        // ✅ أيقونة العين
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white38,
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 15),
                            const SizedBox(width: 8),
                            Text(_errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _openForgotPassword,
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(color: kAccent, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 4,
                        ),
                        onPressed: _signIn,
                        child: const Text('Sign in',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
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

// ─────────────────────────────────────────────
// RESET PASSWORD DIALOG
// ─────────────────────────────────────────────
class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog();

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _emailController = TextEditingController();
  bool _showError = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _showError = true);
    } else {
      setState(() { _showError = false; _sent = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _sent ? _successView() : _formView(),
        ),
      ),
    );
  }

  Widget _formView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: kFieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kAccent.withOpacity(0.6), width: 1.5),
              ),
              child: const Icon(Icons.email_outlined, color: kAccent, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reset Password',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Forgot your password?',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close, color: Colors.white54, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text(
          "Enter your registered email address and we'll send you a password reset link",
          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 14),

        const _FieldLabel('Email Address'),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) { if (_showError) setState(() => _showError = false); },
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'e.g. admin@iras.com',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            filled: true,
            fillColor: kFieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: _showError
                  ? const BorderSide(color: Colors.redAccent, width: 1.5)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _showError ? Colors.redAccent : kAccent, width: 1.5),
            ),
          ),
        ),

        if (_showError) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 15),
                SizedBox(width: 6),
                Text('Please enter your email address',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 3,
                ),
                onPressed: _sendResetLink,
                child: const Text('Send Reset Link',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _successView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: kAccent.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: kAccent, width: 2),
          ),
          child: const Icon(Icons.check, color: kAccent, size: 28),
        ),
        const SizedBox(height: 14),
        const Text('Email Sent!',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'A reset link has been sent to\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
      );
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _DarkTextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: kFieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kAccent, width: 1.5),
        ),
      ),
    );
  }
}