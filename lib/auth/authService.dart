import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ea_master_demo/screens/loginScreen.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable user state
  Rxn<User> user = Rxn<User>();
  
  // Custom user data from Firestore
  RxString userName = ''.obs;
  RxString userAvatar = ''.obs;
  
  // App-wide preferences
  RxBool isLeftHanded = false.obs;
  RxInt streak = 1.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
    
    // Bind user stream so AuthWrapper reacts to auth state changes
    user.bindStream(_auth.authStateChanges());
    
    // Listen to custom user data whenever the auth user changes
    ever(user, (User? u) {
      if (u != null) {
        _listenToUserData(u.uid);
      } else {
        userName.value = '';
        userAvatar.value = '';
      }
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    isLeftHanded.value = prefs.getBool('isLeftHanded') ?? false;
  }

  Future<void> toggleHandedness() async {
    isLeftHanded.value = !isLeftHanded.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLeftHanded', isLeftHanded.value);
  }

  void _listenToUserData(String uid) {
    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        userName.value = data['name'] ?? '';
        userAvatar.value = data['avatar'] ?? ''; // e.g. 'assets/avatars/avatar_01.png'
        streak.value = data['streak'] ?? 1;
      }
    });
    
    _updateStreak(uid);
  }

  Future<void> _updateStreak(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int currentStreak = data['streak'] ?? 0;
      DateTime? lastLogin;
      if (data['lastLoginDate'] != null) {
        if (data['lastLoginDate'] is Timestamp) {
          lastLogin = (data['lastLoginDate'] as Timestamp).toDate();
        } else if (data['lastLoginDate'] is String) {
          lastLogin = DateTime.tryParse(data['lastLoginDate']);
        }
      }

      if (lastLogin == null) {
        await docRef.update({
          'streak': 1,
          'lastLoginDate': today.toIso8601String(),
        });
      } else {
        final lastLoginDate = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
        final difference = today.difference(lastLoginDate).inDays;

        if (difference == 1) {
          await docRef.update({
            'streak': currentStreak + 1,
            'lastLoginDate': today.toIso8601String(),
          });
        } else if (difference > 1) {
          await docRef.update({
            'streak': 1,
            'lastLoginDate': today.toIso8601String(),
          });
        } else if (difference == 0 && currentStreak == 0) {
          await docRef.update({
            'streak': 1,
            'lastLoginDate': today.toIso8601String(),
          });
        }
      }
    } catch (e) {
      debugPrint("Error updating streak: $e");
    }
  }

  // Update profile data in Firestore
  Future<void> updateProfile({String? name, String? avatar}) async {
    final u = currentUser;
    if (u == null) return;
    
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (avatar != null) updates['avatar'] = avatar;
    
    if (updates.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).update(updates);
    }
  }

  User? get currentUser => _auth.currentUser;

  // ─── Sign Up ────────────────────────────────────────────────────────────────
  Future<UserCredential?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'name': name,
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    }
  }

  // ─── Sign In ────────────────────────────────────────────────────────────────
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    }
  }

  // ─── Forgot Password ────────────────────────────────────────────────────────
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    }
  }

  // ─── Sign Out ───────────────────────────────────────────────────────────────
  /// Call this wherever sign-out is needed; navigation is handled by AuthWrapper.
  Future<void> signOut() async {
    await _auth.signOut();
    Get.offAll(() => const LoginScreen());
  }

  // ─── Error Handler ──────────────────────────────────────────────────────────
  void _handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No account found with this email.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'email-already-in-use':
        message = 'An account with this email already exists.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'weak-password':
        message = 'Password should be at least 6 characters.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later.';
        break;
      default:
        message = e.message ?? 'An unexpected error occurred.';
    }
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1E293B),
      colorText: const Color(0xFFEF4444),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}