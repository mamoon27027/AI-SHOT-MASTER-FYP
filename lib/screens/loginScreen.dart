import 'package:ea_master_demo/auth/authService.dart';
import 'package:ea_master_demo/const/appTheme.dart';
import 'package:ea_master_demo/const/authWidgets.dart';
import 'package:ea_master_demo/screens/forgetPasswordScreen.dart';
import 'package:ea_master_demo/screens/signupScreen.dart';
import 'package:ea_master_demo/screens/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool _rememberMe = false;
  bool _loading = false;

  final _auth = Get.find<AuthService>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await _auth.signIn(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Logo
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: AppColors.accent.withOpacity(0.2)),
                        ),
                        child: const Center(
                          child: Icon(Icons.sports_cricket,
                              size: 48, color: AppColors.accent),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text('Welcome Back',
                          style: AppTextStyles.heading),
                      const SizedBox(height: 6),
                      const Text('Sign in to continue your training',
                          style: AppTextStyles.subheading),

                      const SizedBox(height: 32),

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

                            AuthTextField(
                              label: 'Password',
                              hint: 'Enter your password',
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

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v!),
                                  activeColor: AppColors.accent,
                                  side: BorderSide(
                                      color: AppColors.accent.withOpacity(0.4)),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                const Text('Remember me',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => Get.to(
                                      () => const ForgotPasswordScreen()),
                                  child: const Text('Forgot Password?',
                                      style: AppTextStyles.link),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            AuthButton(
                              text: 'Sign In',
                              loading: _loading,
                              onTap: _signIn,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ",
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14)),
                          GestureDetector(
                            onTap: () =>
                                Get.off(() => const SignUpScreen()),
                            child: const Text('Sign Up',
                                style: AppTextStyles.link),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      const Text(
                          'By continuing, you agree to our Terms & Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textDim, fontSize: 11)),
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

Widget glowOrb({
  double? top,
  double? bottom,
  double? left,
  double? right,
  required Color color,
}) {
  return Positioned(
    top: top,
    bottom: bottom,
    left: left,
    right: right,
    child: Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.08),
      ),
    ),
  );
}