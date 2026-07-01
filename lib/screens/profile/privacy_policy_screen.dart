import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ea_master_demo/const/appTheme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Privacy Policy', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Last updated: May 2026', style: TextStyle(color: AppColors.textDim, fontSize: 14)),
              const SizedBox(height: 24),
              
              _buildSection('1. Information We Collect', 
                'We collect information to provide better services to our users. This includes your name, email address, and profile avatars. We also collect telemetry data during your training sessions such as skeletal tracking coordinates. Video frames are processed locally on your device and are NOT uploaded to our servers.'),
              
              _buildSection('2. How We Use Information', 
                'We use the information we collect to provide, maintain, and improve our services, to develop new ones, and to protect AI Short Master and our users. Your performance data is used exclusively to calculate your XP, levels, and mastery scores.'),
              
              _buildSection('3. Camera & ML Kit Usage', 
                'This application requires camera access to function. We use Google ML Kit Pose Detection to analyze your skeletal movements in real-time. This processing happens entirely on-device. No video recordings are saved or transmitted without your explicit consent.'),
              
              _buildSection('4. Data Storage', 
                'Your profile information, level completions, and training mastery are securely stored in Firebase. You may request deletion of your account and associated data by contacting support.'),
                
              _buildSection('5. Changes to This Policy', 
                'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}
