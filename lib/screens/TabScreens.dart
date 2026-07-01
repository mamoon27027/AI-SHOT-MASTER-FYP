import 'package:ea_master_demo/const/appTheme.dart';
import 'package:ea_master_demo/screens/profile/profile_screen.dart';
import 'package:ea_master_demo/screens/scenario/scenario_screen.dart';
import 'package:ea_master_demo/screens/train/train_screen.dart';
import 'package:flutter/material.dart';

// ─── Profile Screen ────────────────────────────────────────────────────────────
class ProfileScreenTab extends StatelessWidget {
  const ProfileScreenTab({super.key});

  @override
  Widget build(BuildContext context) => const ProfileScreen();
}

// ─── Train Screen ────────────────────────────────────────────────────────────
class TrainScreen extends StatelessWidget {
  const TrainScreen({super.key});

  @override
  Widget build(BuildContext context) => const TrainScreenMain();
}

// CareerScreen has been moved to lib/screens/career/career_screen.dart
// ─── Scenarios Screen ────────────────────────────────────────────────────────
// import 'package:ea_master_demo/screens/scenario/scenario_screen.dart';

class ScenariosScreen extends StatelessWidget {
  const ScenariosScreen({super.key});

  @override
  Widget build(BuildContext context) => const ScenarioScreenMain();
}

// ─── Shared placeholder widget ───────────────────────────────────────────────
class _DummyTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DummyTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.accent.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}