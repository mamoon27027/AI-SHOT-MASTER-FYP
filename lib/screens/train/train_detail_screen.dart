import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ea_master_demo/const/appTheme.dart';
import 'train_models.dart';
import 'train_demo_screen.dart';
import 'train_camera_screen.dart';

class TrainDetailScreen extends StatelessWidget {
  final TrainingShot shot;

  const TrainDetailScreen({super.key, required this.shot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: AppColors.accent, size: 16),
                label: const Text('Back to Shots', style: TextStyle(color: AppColors.accent)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Image
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                        image: DecorationImage(
                          image: NetworkImage(shot.imageUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                        )
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 12, right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${shot.mastery.toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(shot.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(shot.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bar_chart, color: AppColors.accentGreen, size: 16),
                          const SizedBox(width: 8),
                          Text(shot.level, style: const TextStyle(color: AppColors.accentGreen, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.accent.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mastery Level', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('${shot.mastery.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.accentGreen, fontSize: 24, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: shot.mastery / 100,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.accentGreen,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            )
                          )
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.accent.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sessions', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('${shot.sessions}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  children: const [
                                    Icon(Icons.trending_up, color: AppColors.accentGreen, size: 12),
                                    SizedBox(width: 4),
                                    Text('+5 this week', style: TextStyle(color: AppColors.accentGreen, fontSize: 10)),
                                  ],
                                )
                              ],
                            )
                          )
                        )
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Technical Focus Points
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accent.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.monitor_heart, color: AppColors.accent, size: 20),
                              SizedBox(width: 12),
                              Text('Technique Focus Points', style: TextStyle(color: Colors.white, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...shot.focusPoints.map((point) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGreen.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accentGreen, shape: BoxShape.circle)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(point, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))),
                              ],
                            )
                          )).toList()
                        ],
                      )
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.to(() => TrainDemoScreen(shot: shot));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: AppColors.accent.withOpacity(0.2)),
                              )
                            ),
                            icon: const Icon(Icons.videocam, color: AppColors.accent),
                            label: const Text('Watch Demo', style: TextStyle(color: Colors.white)),
                          )
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.to(() => TrainCameraScreen(shot: shot));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              )
                            ),
                            icon: const Icon(Icons.play_arrow, color: Color(0xFF0F172A)),
                            label: const Text('Start Now', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                          )
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          )
        )
      )
    );
  }
}
