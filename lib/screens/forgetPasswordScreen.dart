import 'package:ea_master_demo/auth/authService.dart';
import 'package:ea_master_demo/const/appTheme.dart';
import 'package:ea_master_demo/const/authWidgets.dart';
import 'package:ea_master_demo/screens/loginScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _emailSent = false;

  final _auth = Get.find<AuthService>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final success =
        await _auth.sendPasswordResetEmail(_emailCtrl.text);
    if (mounted) {
      setState(() {
        _loading = false;
        if (success) _emailSent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: appBackgroundDecoration,
        child: Stack(
          children: [
            glowOrb(top: -60, right: -60, color: AppColors.accent),
            glowOrb(bottom: -60, left: -60, color: AppColors.accentGreen),
            SafeArea(
              child: _emailSent ? _successView() : _formView(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Success State ─────────────────────────────────────────────────────────
  Widget _successView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border:
                Border.all(color: AppColors.accent.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGreen.withOpacity(0.1),
                  border: Border.all(
                      color: AppColors.accentGreen, width: 2),
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: AppColors.accentGreen, size: 42),
              ),
              const SizedBox(height: 20),
              const Text('Check Your Email',
                  style: AppTextStyles.heading),
              const SizedBox(height: 10),
              const Text(
                "We've sent password reset instructions to",
                textAlign: TextAlign.center,
                style: AppTextStyles.subheading,
              ),
              const SizedBox(height: 8),
              Text(
                _emailCtrl.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                "Didn't receive the email? Check your spam folder or try again.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textDim, fontSize: 12),
              ),
              const SizedBox(height: 24),
              AuthButton(
                text: 'Back to Sign In',
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Form State ────────────────────────────────────────────────────────────
  Widget _formView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            GestureDetector(
              onTap: () => Get.back(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.arrow_back_ios,
                      color: AppColors.accent, size: 16),
                  SizedBox(width: 4),
                  Text('Back to Sign In', style: AppTextStyles.link),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logo centered
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.accent.withOpacity(0.2)),
                ),
                child: const Center(
                  child: Icon(Icons.sports_cricket,
                      size: 42, color: AppColors.accent),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Center(
                child: Text('Reset Password', style: AppTextStyles.heading)),
            const SizedBox(height: 6),
            const Center(
                child: Text(
                    'Enter your email to receive reset instructions',
                    style: AppTextStyles.subheading,
                    textAlign: TextAlign.center)),

            const SizedBox(height: 32),

            // Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border:
                    Border.all(color: AppColors.accent.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthTextField(
                    label: 'Email Address',
                    hint: 'Enter your email',
                    prefixIcon: Icons.email_outlined,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Email is required';
                      }
                      if (!GetUtils.isEmail(v)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  AuthButton(
                    text: 'Send Reset Link',
                    loading: _loading,
                    onTap: _sendReset,
                  ),

                  const SizedBox(height: 16),

                  // Info box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.accent.withOpacity(0.1)),
                    ),
                    child: const Text(
                      'You will receive an email with instructions on how to reset your password in a few minutes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}