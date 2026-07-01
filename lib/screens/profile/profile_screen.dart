import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ea_master_demo/const/appTheme.dart';
import 'package:ea_master_demo/auth/authService.dart';
import 'package:ea_master_demo/services/career_service.dart';

import 'edit_profile_screen.dart';
import 'help_faq_screen.dart';
import 'privacy_policy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final careerService = Get.find<CareerService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              // Logo
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Image.asset('assets/images/app-logo.png', width: 80, height: 80, errorBuilder: (context, error, stackTrace) => const SizedBox(width: 80, height: 80)),
                ),
              ),

              // User Info Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showAvatarSelection(context, authService),
                          child: Obx(() {
                            final avatarUrl = authService.userAvatar.value;
                            return Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: avatarUrl.isNotEmpty
                                  ? Image.asset(avatarUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person, color: Colors.white, size: 40))
                                  : const Icon(Icons.person, color: Colors.white, size: 40),
                            );
                          }),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(() {
                            final name = authService.userName.value.isNotEmpty ? authService.userName.value : 'User';
                            final email = authService.currentUser?.email ?? '';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              ],
                            );
                          }),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    Obx(() {
                      final level = careerService.maxUnlockedLevel;
                      final xp = careerService.totalXp;
                      final completedLevels = careerService.completedLevels.length;
                      
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text('Level $level', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('Rank', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text('$xp', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('XP Points', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text('$completedLevels/40', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('Levels', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      );
                    })
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Account Settings
              _buildSectionHeader('Account Settings'),
              Obx(() => _buildActionCard(
                icon: Icons.sports_cricket,
                iconBg: AppColors.accent.withOpacity(0.1),
                iconColor: AppColors.accent,
                title: 'Batting Style: ${authService.isLeftHanded.value ? 'Left-Handed' : 'Right-Handed'}',
                onTap: () => authService.toggleHandedness(),
              )),
              _buildActionCard(
                icon: Icons.person_outline,
                iconBg: AppColors.accent.withOpacity(0.1),
                iconColor: AppColors.accent,
                title: 'Edit Profile',
                onTap: () => Get.to(() => const EditProfileScreen()),
              ),
              _buildActionCard(
                icon: Icons.emoji_events_outlined,
                iconBg: AppColors.accentGreen.withOpacity(0.1),
                iconColor: AppColors.accentGreen,
                title: 'Achievements',
                onTap: () => Get.snackbar('Achievements', 'Coming soon!', snackPosition: SnackPosition.BOTTOM),
              ),
              _buildActionCard(
                icon: Icons.notifications_none,
                iconBg: AppColors.accent.withOpacity(0.1),
                iconColor: AppColors.accent,
                title: 'Notifications',
                onTap: () => Get.snackbar('Notifications', 'Coming soon!', snackPosition: SnackPosition.BOTTOM),
              ),
              const SizedBox(height: 24),

              // Support
              _buildSectionHeader('Support'),
              _buildActionCard(
                icon: Icons.help_outline,
                iconBg: AppColors.accent.withOpacity(0.1),
                iconColor: AppColors.accent,
                title: 'Help & FAQ',
                onTap: () => Get.to(() => const HelpFaqScreen()),
              ),
              _buildActionCard(
                icon: Icons.shield_outlined,
                iconBg: AppColors.accent.withOpacity(0.1),
                iconColor: AppColors.accent,
                title: 'Privacy Policy',
                onTap: () => Get.to(() => const PrivacyPolicyScreen()),
              ),
              const SizedBox(height: 24),

              // Sign Out
              GestureDetector(
                onTap: () => authService.signOut(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.logout, color: Colors.red, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Sign Out', style: TextStyle(color: Colors.red, fontSize: 16))),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text('AI Short Master v1.0.0', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required Color iconBg, required Color iconColor, required String title, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16))),
              const Icon(Icons.arrow_forward, color: AppColors.textDim, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarSelection(BuildContext context, AuthService authService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose Avatar', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 15, // avatar_01 to avatar_15
                    itemBuilder: (context, index) {
                      final num = (index + 1).toString().padLeft(2, '0');
                      final assetPath = 'assets/avatars/avatar_$num.png';
                      return GestureDetector(
                        onTap: () {
                          authService.updateProfile(avatar: assetPath);
                          Get.back();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accent.withOpacity(0.5), width: 2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(assetPath, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person, color: Colors.white)),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }
}
