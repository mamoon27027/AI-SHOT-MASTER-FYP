import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ea_master_demo/const/appTheme.dart';
import 'package:ea_master_demo/pipeline/career_levels.dart';
import 'package:ea_master_demo/services/career_service.dart';
import 'package:ea_master_demo/screens/career/level_detail_screen.dart';

class CareerScreen extends StatelessWidget {
  const CareerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final careerService = Get.find<CareerService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final maxUnlocked = careerService.maxUnlockedLevel;
          final completedCount = careerService.completedLevels.length;
          final totalLevels = CareerLevelsData.levels.length;
          final progressPercent = (completedCount / totalLevels) * 100;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1E293B),
                        const Color(0xFF1E293B),
                        const Color(0xFF0F172A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                  ),
                  child: Stack(
                    children: [
                      // Glow effects
                      Positioned(
                        top: -40,
                        right: -40,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        left: -40,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentGreen.withOpacity(0.05),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                                  ),
                                  child: const Icon(Icons.sports_cricket, size: 36, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Career Progression',
                                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentGreen.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppColors.accentGreen.withOpacity(0.2)),
                                            ),
                                            child: const Text('ACTIVE', style: TextStyle(color: AppColors.accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('40 levels of elite mastery', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.accent.withOpacity(0.1)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.bolt, color: AppColors.accent, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Overall Progress', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                            Text('Level $maxUnlocked of $totalLevels', style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      Text('${progressPercent.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.accent, fontSize: 22, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: progressPercent / 100,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _statBox(maxUnlocked.toString(), 'Current', AppColors.accent),
                                      const SizedBox(width: 12),
                                      _statBox(completedCount.toString(), 'Complete', Colors.white),
                                      const SizedBox(width: 12),
                                      _statBox((totalLevels - completedCount).toString(), 'Locked', AppColors.accentGreen),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Grid Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Training Levels', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: const [
                        Icon(Icons.check_circle, size: 14, color: AppColors.accentGreen),
                        SizedBox(width: 4),
                        Text('Complete', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        SizedBox(width: 12),
                        Icon(Icons.lock, size: 14, color: AppColors.textSecondary),
                        SizedBox(width: 4),
                        Text('Locked', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Grid of Levels
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: CareerLevelsData.levels.length,
                  itemBuilder: (context, index) {
                    final level = CareerLevelsData.levels[index];
                    final isUnlocked = level.levelNumber <= maxUnlocked;
                    final isCompleted = careerService.completedLevels.contains(level.levelNumber);

                    return GestureDetector(
                      onTap: isUnlocked
                          ? () {
                              Get.to(() => LevelDetailScreen(level: level));
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUnlocked ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.accentGreen
                                : isUnlocked
                                    ? AppColors.accent
                                    : const Color(0xFF1E293B),
                            width: 2,
                          ),
                          boxShadow: isUnlocked
                              ? [BoxShadow(color: AppColors.accent.withOpacity(0.1), blurRadius: 8, spreadRadius: 1)]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isCompleted)
                              const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 26)
                            else if (isUnlocked)
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.accent),
                                ),
                                child: Center(
                                  child: Text(
                                    '${level.levelNumber}',
                                    style: const TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            else
                              const Icon(Icons.lock, color: AppColors.textSecondary, size: 26),
                            
                            const SizedBox(height: 4),
                            Text(
                              isUnlocked ? 'Level ${level.levelNumber}' : 'Locked',
                              style: TextStyle(
                                color: isUnlocked ? Colors.white : AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
