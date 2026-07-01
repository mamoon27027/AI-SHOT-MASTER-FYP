import 'package:ea_master_demo/auth/authService.dart';
import 'package:ea_master_demo/const/appTheme.dart';
import 'package:ea_master_demo/const/authWidgets.dart';
import 'package:ea_master_demo/screens/loginScreen.dart';
import 'package:ea_master_demo/screens/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;
  bool _showConfirm = false;
  bool _agreedToTerms = false;
  bool _loading = false;

  final _auth = Get.find<AuthService>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      Get.snackbar(
        'Terms Required',
        'Please agree to Terms of Service and Privacy Policy.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accent,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    setState(() => _loading = true);
    final result = await _auth.signUp(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );
    if (mounted) setState(() => _loading = false);
    
    if (result != null) {
      Get.offAll(() => const HomeScreen());
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
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Logo
                      Container(
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

                      const SizedBox(height: 20),
                      const Text('Create Account',
                          style: AppTextStyles.heading),
                      const SizedBox(height: 6),
                      const Text('Start your cricket mastery journey',
                          style: AppTextStyles.subheading),

                      const SizedBox(height: 28),

                      // Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Full Name
                            AuthTextField(
                              label: 'Full Name',
                              hint: 'Enter your full name',
                              prefixIcon: Icons.person_outline,
                              controller: _nameCtrl,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Full name is required';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Email
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

                            const SizedBox(height: 16),

                            // Password
                            AuthTextField(
                              label: 'Password',
                              hint: 'Create a password',
                              prefixIcon: Icons.lock_outline,
                              controller: _passCtrl,
                              obscure: !_showPass,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textDim,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _showPass = !_showPass),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                if (v.length < 6) {
                                  return 'Minimum 6 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Confirm Password
                            AuthTextField(
                              label: 'Confirm Password',
                              hint: 'Confirm your password',
                              prefixIcon: Icons.lock_outline,
                              controller: _confirmCtrl,
                              obscure: !_showConfirm,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textDim,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _showConfirm = !_showConfirm),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (v != _passCtrl.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Terms checkbox
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: (v) =>
                                      setState(() => _agreedToTerms = v!),
                                  activeColor: AppColors.accent,
                                  side: BorderSide(
                                      color: AppColors.accent.withOpacity(0.4)),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 4),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Text(
                                      'I agree to the Terms of Service and Privacy Policy',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            AuthButton(
                              text: 'Create Account',
                              loading: _loading,
                              onTap: _createAccount,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14)),
                          GestureDetector(
                            onTap: () =>
                                Get.off(() => const LoginScreen()),
                            child: const Text('Sign In',
                                style: AppTextStyles.link),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}