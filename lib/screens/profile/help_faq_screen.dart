import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ea_master_demo/const/appTheme.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {
        'q': 'How does the AI Shot Tracking work?',
        'a': 'The app uses your device camera and Google ML Kit Pose Detection to analyze your body movements in real-time. It compares your joints to professional benchmarks to calculate accuracy and identify areas of improvement.'
      },
      {
        'q': 'What is Scenario Mode?',
        'a': 'Scenario Mode simulates real match pressure. You choose a tournament and team, and the app generates a random target (e.g. 15 runs in 6 balls). You must execute specific shots to score runs and win the match.'
      },
      {
        'q': 'What is Train Mode?',
        'a': 'Train Mode focuses on mastering individual shots. It is highly strict and will only reward points if you execute the exact shot you selected. This helps build muscle memory.'
      },
      {
        'q': 'How do I earn XP and level up?',
        'a': 'You earn XP by successfully completing levels in Career Mode and hitting targets in Scenario Mode. Accumulating XP unlocks higher levels.'
      },
      {
        'q': 'Why does the app say "No Shot Detected"?',
        'a': 'This happens if you are in Train Mode and you execute a shot different from the one you selected, or if the camera cannot see your full body clearly. Ensure good lighting and that your entire body is in the frame.'
      }
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Help & FAQ', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: faqs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withOpacity(0.1)),
              ),
              child: ExpansionTile(
                iconColor: AppColors.accent,
                collapsedIconColor: AppColors.textDim,
                title: Text(faqs[index]['q']!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Text(faqs[index]['a']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
