import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ea_master_demo/const/appTheme.dart';
import 'train_models.dart';
import 'train_detail_screen.dart';

class TrainScreenMain extends StatefulWidget {
  const TrainScreenMain({super.key});

  @override
  State<TrainScreenMain> createState() => _TrainScreenMainState();
}

class _TrainScreenMainState extends State<TrainScreenMain> {
  
  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<TrainController>()) {
      Get.put(TrainController());
    }
  }

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
              _buildDashboard(),
              const SizedBox(height: 24),
              _buildShotList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Obx(() {
      final controller = TrainController.to;
      // Trigger rebuild on shotStats changes
      final stats = controller.shotStats.values.toList();
      return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accent.withOpacity(0.2)),
          ),
          child: Stack(
            children: [
              // Glow effects
              Positioned(
                top: 0, right: 0,
                child: Container(
                  width: 128, height: 128,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 0, left: 0,
                child: Container(
                  width: 128, height: 128,
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.sports_cricket, color: AppColors.accentGreen, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Shot Training', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('AI-powered technique mastery system', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.show_chart, color: AppColors.accentGreen, size: 14),
                                  const SizedBox(width: 4),
                                  Text('${controller.shots.length} Shots Available', style: const TextStyle(color: AppColors.accentGreen, fontSize: 12)),
                                  const SizedBox(width: 8),
                                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.textDim, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Text('${controller.totalSessions} Sessions', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Overall Mastery', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('${controller.overallMastery.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total Sessions', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('${controller.totalSessions}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildShotList() {
    return Obx(() {
      final controller = TrainController.to;
      final stats = controller.shotStats.values.toList(); // trigger reactivity
      return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.shots.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final shot = controller.shots[index];
            return GestureDetector(
              onTap: () {
                Get.to(() => TrainDetailScreen(shot: shot));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Header
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        image: DecorationImage(
                          image: NetworkImage(shot.imageUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 12, right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${shot.mastery.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.accentGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Positioned(
                            bottom: 12, left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                              ),
                              child: Text(shot.level, style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                            ),
                          )
                        ],
                      ),
                    ),
                    // Details
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shot.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(shot.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${shot.sessions} sessions completed', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                              Row(
                                children: const [
                                  Icon(Icons.trending_up, color: AppColors.accentGreen, size: 14),
                                  SizedBox(width: 4),
                                  Text('+8%', style: TextStyle(color: AppColors.accentGreen, fontSize: 12)),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: shot.mastery / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }
}
