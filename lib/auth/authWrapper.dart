import 'package:ea_master_demo/auth/authService.dart';
import 'package:ea_master_demo/screens/HomeScreen.dart';
import 'package:ea_master_demo/screens/loginScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Sits at the root of the widget tree. Reacts to Firebase auth state changes:
/// - Logged in  → HomeScreen
/// - Logged out → LoginScreen
///
/// Because [AuthService.user] is an [Rxn], any sign-in or sign-out will
/// rebuild this widget automatically, without manual navigation calls.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();

    return Obx(() {
      final user = auth.user.value;

      if (user == null) {
        return const LoginScreen();
      } else {
        return const HomeScreen();
      }
    });
  }
}