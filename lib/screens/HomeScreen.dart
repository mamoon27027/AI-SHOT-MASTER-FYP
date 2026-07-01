import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:ea_master_demo/auth/authService.dart';
import 'package:ea_master_demo/const/appTheme.dart';
import 'package:ea_master_demo/screens/TabScreens.dart';
import 'package:ea_master_demo/screens/career/career_screen.dart';
import 'package:ea_master_demo/screens/profile/profile_screen.dart';
import 'package:ea_master_demo/services/career_service.dart';
import 'package:ea_master_demo/screens/train/train_models.dart';

// ─── Nav Item Model ──────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}

// ─── Home Screen ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 2; // Home is center (index 2), selected by default

  final List<_NavItem> _navItems = [
    _NavItem(Icons.person_outline, 'Profile'),
    _NavItem(Icons.fitness_center_outlined, 'Train'),
    _NavItem(Icons.home_rounded, 'Home'),
    _NavItem(Icons.bolt_outlined, 'Career'),
    _NavItem(Icons.emoji_events_outlined, 'Scenarios'),
  ];

  final List<Widget> _pages = const [
    ProfileScreenTab(),
    TrainScreen(),
    _HomeContent(),
    CareerScreen(),
    ScenariosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _CustomBottomNav(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Custom Bottom Navigation Bar ────────────────────────────────────────────
class _CustomBottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CustomBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.navBg,
        border: const Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isSelected = i == currentIndex;
          final isCenter = i == 2; 

          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCenter)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.accentGreen : AppColors.surface,
                      ),
                      child: Icon(
                        items[i].icon,
                        size: 24,
                        color: isSelected ? Colors.white : AppColors.textDim,
                      ),
                    )
                  else
                    Icon(
                      items[i].icon,
                      size: 24,
                      color: isSelected ? AppColors.textPrimary : AppColors.textDim,
                    ),

                  const SizedBox(height: 4),

                  Text(
                    items[i].label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? (isCenter ? AppColors.accentGreen : AppColors.textPrimary)
                          : AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Main Home Tab Content ────────────────────────────────────────────────────
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    final career = Get.find<CareerService>();
    if (!Get.isRegistered<TrainController>()) Get.put(TrainController());
    final trainController = TrainController.to;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Card
              _buildHeroCard(auth, career, trainController),
              const SizedBox(height: 16),

              // Metric Cards Grid
              Row(
                children: [
                  Expanded(child: _buildMetricCard(
                    icon: Icons.bolt,
                    iconColor: AppColors.accent,
                    title: 'This Week',
                    value: '${trainController.totalSessions}',
                    subtitle: 'Training Sessions',
                    trend: '+12% from last week',
                    trendColor: AppColors.accentGreen,
                    trendIcon: Icons.trending_up,
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: Obx(() {
                    final streakVal = auth.streak.value;
                    return _buildMetricCard(
                      icon: Icons.calendar_month,
                      iconColor: AppColors.accentGreen,
                      title: 'Streak',
                      value: '$streakVal Day${streakVal == 1 ? "" : "s"}',
                      subtitle: 'Current Streak',
                      trend: 'Keep it going!',
                      trendColor: AppColors.accent,
                      trendIcon: Icons.emoji_events,
                    );
                  })),
                ],
              ),
              const SizedBox(height: 16),

              // Weekly Accuracy Trend Chart
              _buildLineChartCard(trainController),
              const SizedBox(height: 16),

              // Overall Progress Radial Chart
              _buildRadialChartCard(trainController),
              const SizedBox(height: 16),

              // Shot Performance Analytics
              _buildShotAnalyticsList(trainController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(AuthService auth, CareerService career, TrainController trainController) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -20, right: -20,
            child: Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), shape: BoxShape.circle)),
          ),
          Positioned(
            bottom: -20, left: -20,
            child: Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.accentGreen.withOpacity(0.1), shape: BoxShape.circle)),
          ),
          
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Image.asset('assets/images/app-logo.png', width: 40, height: 40, errorBuilder: (_,__,___) => const Icon(Icons.sports_cricket, color: AppColors.accent)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('AI Short Master', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                              ),
                              child: const Text('PRO', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Elite Performance Analytics', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('Active Training', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                  const SizedBox(width: 8),
                  const Text('•', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                  const SizedBox(width: 8),
                  const Text('Last session: 2 hours ago', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 24),
              Obx(() {
                return Row(
                  children: [
                    _buildHeroStatBox(Icons.emoji_events, AppColors.accent, '${career.maxUnlockedLevel}', 'Level'),
                    const SizedBox(width: 12),
                    _buildHeroStatBox(Icons.trending_up, AppColors.accent, '${career.totalXp}', 'XP'),
                    const SizedBox(width: 12),
                    _buildHeroStatBox(Icons.radar, AppColors.accentGreen, '${trainController.overallMastery.toStringAsFixed(0)}%', 'Mastery'),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatBox(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({required IconData icon, required Color iconColor, required String title, required String value, required String subtitle, required String trend, required Color trendColor, required IconData trendIcon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(trendIcon, color: trendColor, size: 12),
              const SizedBox(width: 4),
              Expanded(child: Text(trend, style: TextStyle(color: trendColor, fontSize: 10), overflow: TextOverflow.ellipsis)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLineChartCard(TrainController trainController) {
    return Obx(() {
      final double baseline = trainController.overallMastery;
      
      // Generate some dummy data points oscillating around baseline to look like the React chart
      List<FlSpot> spots = [
        FlSpot(0, (baseline - 9).clamp(0, 100)),
        FlSpot(1, (baseline - 4).clamp(0, 100)),
        FlSpot(2, (baseline - 6).clamp(0, 100)),
        FlSpot(3, (baseline + 1).clamp(0, 100)),
        FlSpot(4, (baseline + 4).clamp(0, 100)),
        FlSpot(5, (baseline).clamp(0, 100)),
        FlSpot(6, (baseline + 6).clamp(0, 100)),
      ];

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Weekly Accuracy Trend', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.accentGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Text('↑ 15%', style: TextStyle(color: AppColors.accentGreen, fontSize: 10)),
                )
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          return Text(days[value.toInt() % 7], style: const TextStyle(color: AppColors.textDim, fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.accentGreen,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: AppColors.accentGreen, strokeWidth: 0)),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRadialChartCard(TrainController trainController) {
    return Obx(() {
      final double mastery = trainController.overallMastery;
      
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overall Progress', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${mastery.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.accentGreen, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: 270,
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                      sections: [
                        PieChartSectionData(
                          value: mastery,
                          color: AppColors.accentGreen,
                          radius: 20,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: 100 - mastery,
                          color: const Color(0xFF0F172A),
                          radius: 20,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${mastery.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const Text('Mastery', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Average Shot Mastery', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    });
  }

  Widget _buildShotAnalyticsList(TrainController trainController) {
    return Obx(() {
      final shots = trainController.shots;

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Shot Performance Analytics', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('${shots.length} Shots', style: const TextStyle(color: AppColors.accent, fontSize: 10)),
              )
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shots.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final shot = shots[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.radar, color: AppColors.accent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(shot.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('${shot.mastery.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.accentGreen, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: Text(shot.level, style: const TextStyle(color: AppColors.accent, fontSize: 10)),
                              ),
                              const SizedBox(width: 12),
                              Text('${shot.sessions} sessions', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: (shot.mastery / 100).clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentGreen]),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          )
        ],
      );
    });
  }
}