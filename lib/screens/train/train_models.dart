import 'package:ea_master_demo/services/train_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TrainingShot {
  final String name;
  double mastery;
  final String level;
  int sessions;
  final String description;
  final String imageUrl;
  final String demoUrl;
  final List<String> focusPoints;

  TrainingShot({
    required this.name,
    required this.mastery,
    required this.level,
    required this.sessions,
    required this.description,
    required this.imageUrl,
    required this.demoUrl,
    required this.focusPoints,
  });
}

// Global state controller for Train Mode to persist data across screens
//import 'package:ea_master_demo/services/train_service.dart';

class TrainController extends GetxController {
  static TrainController get to => Get.find();

  // Get service instance
  final TrainService _service = Get.find<TrainService>();

  // Calculate total sessions dynamically from service data
  int get totalSessions {
    int sum = 0;
    for (var stat in _service.shotStats.values) {
      sum += (stat['sessions'] ?? 0) as int;
    }
    return sum;
  }
  
  // Calculate overall mastery dynamically based on shots
  double get overallMastery {
    if (_service.shotStats.isEmpty) return 0.0;
    
    double totalMastery = 0.0;
    int shotsWithData = 0;
    
    for (var stat in _service.shotStats.values) {
      int sessions = (stat['sessions'] ?? 0) as int;
      if (sessions > 0) {
        totalMastery += (stat['mastery'] ?? 0.0).toDouble();
        shotsWithData++;
      }
    }
    
    if (shotsWithData == 0) return 0.0;
    return totalMastery / shotsWithData;
  }

  // Base shot configurations
  final List<TrainingShot> baseShots = [
    TrainingShot(
      name: 'Cover Drive',
      mastery: 0.0,
      level: 'Expert',
      sessions: 0,
      description: 'Classic off-side stroke with perfect timing and placement',
      imageUrl: 'https://images.unsplash.com/photo-1624526368410-b552dbf2e743?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400',
      demoUrl: 'assets/videos/cover_drive_shot_demo.mp4',
      focusPoints: [
        'Keep your head steady and eyes on the ball',
        'Execute complete follow-through motion',
        'Position feet correctly for optimal balance',
        'Maintain stable body position throughout'
      ],
    ),
    TrainingShot(
      name: 'Pull Shot',
      mastery: 0.0,
      level: 'Advanced',
      sessions: 0,
      description: 'Aggressive stroke against short-pitched deliveries',
      imageUrl: 'https://images.unsplash.com/photo-1624526088797-334889636305?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400',
      demoUrl: 'assets/videos/pull_shot_demo.mp4',
      focusPoints: [
        'Watch the head position',
        'Transfer weight to the back foot',
        'Roll the wrists to keep the ball down',
      ],
    ),
    TrainingShot(
      name: 'Sweep Shot',
      mastery: 0.0,
      level: 'Advanced',
      sessions: 0,
      description: 'Effective weapon against spin bowling',
      imageUrl: 'https://images.unsplash.com/photo-1593341646782-e0b495cff86d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400',
      demoUrl: 'assets/videos/sweep_shot_demo.mp4',
      focusPoints: [
        'Get down low quickly',
        'Watch the ball onto the bat',
        'Control the swing path',
      ],
    ),
    TrainingShot(
      name: 'Cut Shot',
      mastery: 0.0,
      level: 'Intermediate',
      sessions: 0,
      description: 'Precision stroke through backward point region',
      imageUrl: 'https://images.unsplash.com/photo-1624526368410-b552dbf2e743?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400',
      demoUrl: 'assets/videos/cut_shot_demo.mp4',
      focusPoints: [
        'Wait for the ball',
        'Use the pace of the delivery',
        'Extend arms fully through the shot',
      ],
    ),
    TrainingShot(
      name: 'Straight Drive',
      mastery: 0.0,
      level: 'Expert',
      sessions: 0,
      description: 'The most elegant and powerful stroke in cricket',
      imageUrl: 'https://images.unsplash.com/photo-1624526088797-334889636305?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400',
      demoUrl: 'assets/videos/straight_drive_shot_demo.mp4',
      focusPoints: [
        'Present the full face of the bat',
        'Keep the head over the ball',
        'Perfect timing over power',
      ],
    ),
  ];

  // Dynamic list getter that merges baseShots with Firebase stats
  List<TrainingShot> get shots {
    return baseShots.map((baseShot) {
      final stats = _service.shotStats[baseShot.name];
      if (stats != null) {
        return TrainingShot(
          name: baseShot.name,
          mastery: (stats['mastery'] ?? 0.0).toDouble(),
          level: baseShot.level,
          sessions: (stats['sessions'] ?? 0) as int,
          description: baseShot.description,
          imageUrl: baseShot.imageUrl,
          demoUrl: baseShot.demoUrl,
          focusPoints: baseShot.focusPoints,
        );
      }
      return baseShot;
    }).toList();
  }

  // Exposed for UI updates (UI should use Obx or GetX watching _service.shotStats)
  RxMap<String, Map<String, dynamic>> get shotStats => _service.shotStats;
}
