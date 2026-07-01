class ShotObjective {
  final String shotName;
  final int count;
  final int minAccuracy;
  final int? allowedAttempts;

  const ShotObjective({
    required this.shotName,
    required this.count,
    required this.minAccuracy,
    this.allowedAttempts,
  });

  int get maxAttempts => allowedAttempts ?? count * 2;
}

class CareerLevel {
  final int levelNumber;
  final List<ShotObjective> objectives;
  final int xpReward;
  final int skillReward;

  const CareerLevel({
    required this.levelNumber,
    required this.objectives,
    required this.xpReward,
    required this.skillReward,
  });

  int get totalShots => objectives.fold(0, (sum, obj) => sum + obj.count);
}

class CareerLevelsData {
  static const List<CareerLevel> levels = [
    // Levels 1-5
    CareerLevel(levelNumber: 1, xpReward: 50, skillReward: 10, objectives: [ShotObjective(shotName: 'Pull Shot', count: 5, minAccuracy: 30)]),
    CareerLevel(levelNumber: 2, xpReward: 100, skillReward: 20, objectives: [ShotObjective(shotName: 'Straight Drive', count: 5, minAccuracy: 30)]),
    CareerLevel(levelNumber: 3, xpReward: 150, skillReward: 30, objectives: [ShotObjective(shotName: 'Cover Drive', count: 5, minAccuracy: 35)]),
    CareerLevel(levelNumber: 4, xpReward: 200, skillReward: 40, objectives: [ShotObjective(shotName: 'Straight Drive', count: 5, minAccuracy: 35)]),
    CareerLevel(levelNumber: 5, xpReward: 250, skillReward: 50, objectives: [ShotObjective(shotName: 'Cut Shot', count: 5, minAccuracy: 35)]),

    // Levels 6-10
    CareerLevel(levelNumber: 6, xpReward: 300, skillReward: 60, objectives: [ShotObjective(shotName: 'Pull Shot', count: 4, minAccuracy: 35), ShotObjective(shotName: 'Cover Drive', count: 4, minAccuracy: 35)]),
    CareerLevel(levelNumber: 7, xpReward: 350, skillReward: 70, objectives: [ShotObjective(shotName: 'Sweep Shot', count: 4, minAccuracy: 35), ShotObjective(shotName: 'Straight Drive', count: 4, minAccuracy: 35)]),
    CareerLevel(levelNumber: 8, xpReward: 400, skillReward: 80, objectives: [ShotObjective(shotName: 'Pull Shot', count: 4, minAccuracy: 40), ShotObjective(shotName: 'Cut Shot', count: 4, minAccuracy: 40)]),
    CareerLevel(levelNumber: 9, xpReward: 450, skillReward: 90, objectives: [ShotObjective(shotName: 'Sweep Shot', count: 4, minAccuracy: 40), ShotObjective(shotName: 'Cover Drive', count: 4, minAccuracy: 40)]),
    CareerLevel(levelNumber: 10, xpReward: 500, skillReward: 100, objectives: [ShotObjective(shotName: 'Pull Shot', count: 4, minAccuracy: 40), ShotObjective(shotName: 'Straight Drive', count: 4, minAccuracy: 40)]),

    // Levels 11-15
    CareerLevel(levelNumber: 11, xpReward: 550, skillReward: 110, objectives: [ShotObjective(shotName: 'Pull Shot', count: 6, minAccuracy: 45), ShotObjective(shotName: 'Sweep Shot', count: 6, minAccuracy: 45)]),
    CareerLevel(levelNumber: 12, xpReward: 600, skillReward: 120, objectives: [ShotObjective(shotName: 'Cover Drive', count: 6, minAccuracy: 45), ShotObjective(shotName: 'Pull Shot', count: 6, minAccuracy: 45)]),
    CareerLevel(levelNumber: 13, xpReward: 650, skillReward: 130, objectives: [ShotObjective(shotName: 'Straight Drive', count: 6, minAccuracy: 45), ShotObjective(shotName: 'Sweep Shot', count: 6, minAccuracy: 45)]),
    CareerLevel(levelNumber: 14, xpReward: 700, skillReward: 140, objectives: [ShotObjective(shotName: 'Cut Shot', count: 6, minAccuracy: 50), ShotObjective(shotName: 'Pull Shot', count: 6, minAccuracy: 50)]),
    CareerLevel(levelNumber: 15, xpReward: 750, skillReward: 150, objectives: [ShotObjective(shotName: 'Cover Drive', count: 6, minAccuracy: 50), ShotObjective(shotName: 'Sweep Shot', count: 6, minAccuracy: 50)]),

    // Levels 16-20
    CareerLevel(levelNumber: 16, xpReward: 800, skillReward: 160, objectives: [ShotObjective(shotName: 'Straight Drive', count: 5, minAccuracy: 50), ShotObjective(shotName: 'Pull Shot', count: 5, minAccuracy: 50), ShotObjective(shotName: 'Sweep Shot', count: 5, minAccuracy: 50)]),
    CareerLevel(levelNumber: 17, xpReward: 850, skillReward: 170, objectives: [ShotObjective(shotName: 'Cut Shot', count: 5, minAccuracy: 50), ShotObjective(shotName: 'Pull Shot', count: 5, minAccuracy: 50), ShotObjective(shotName: 'Sweep Shot', count: 5, minAccuracy: 50)]),
    CareerLevel(levelNumber: 18, xpReward: 900, skillReward: 180, objectives: [ShotObjective(shotName: 'Pull Shot', count: 10, minAccuracy: 55), ShotObjective(shotName: 'Cover Drive', count: 5, minAccuracy: 55)]),
    CareerLevel(levelNumber: 19, xpReward: 950, skillReward: 190, objectives: [ShotObjective(shotName: 'Sweep Shot', count: 10, minAccuracy: 55), ShotObjective(shotName: 'Straight Drive', count: 5, minAccuracy: 55)]),
    CareerLevel(levelNumber: 20, xpReward: 1000, skillReward: 200, objectives: [ShotObjective(shotName: 'Cover Drive', count: 5, minAccuracy: 55), ShotObjective(shotName: 'Pull Shot', count: 5, minAccuracy: 55), ShotObjective(shotName: 'Sweep Shot', count: 5, minAccuracy: 55)]),

    // Levels 21-25
    CareerLevel(levelNumber: 21, xpReward: 1050, skillReward: 210, objectives: [ShotObjective(shotName: 'Pull Shot', count: 10, minAccuracy: 60), ShotObjective(shotName: 'Sweep Shot', count: 10, minAccuracy: 60)]),
    CareerLevel(levelNumber: 22, xpReward: 1100, skillReward: 220, objectives: [ShotObjective(shotName: 'Cover Drive', count: 10, minAccuracy: 60), ShotObjective(shotName: 'Pull Shot', count: 10, minAccuracy: 60)]),
    CareerLevel(levelNumber: 23, xpReward: 1150, skillReward: 230, objectives: [ShotObjective(shotName: 'Straight Drive', count: 10, minAccuracy: 60), ShotObjective(shotName: 'Sweep Shot', count: 10, minAccuracy: 60)]),
    CareerLevel(levelNumber: 24, xpReward: 1200, skillReward: 240, objectives: [ShotObjective(shotName: 'Cut Shot', count: 10, minAccuracy: 65), ShotObjective(shotName: 'Pull Shot', count: 10, minAccuracy: 65)]),
    CareerLevel(levelNumber: 25, xpReward: 1250, skillReward: 250, objectives: [ShotObjective(shotName: 'Cover Drive', count: 8, minAccuracy: 65), ShotObjective(shotName: 'Pull Shot', count: 6, minAccuracy: 65), ShotObjective(shotName: 'Sweep Shot', count: 6, minAccuracy: 65)]),

    // Levels 26-30
    CareerLevel(levelNumber: 26, xpReward: 1300, skillReward: 260, objectives: [ShotObjective(shotName: 'Straight Drive', count: 10, minAccuracy: 65), ShotObjective(shotName: 'Pull Shot', count: 8, minAccuracy: 65), ShotObjective(shotName: 'Sweep Shot', count: 7, minAccuracy: 65)]),
    CareerLevel(levelNumber: 27, xpReward: 1350, skillReward: 270, objectives: [ShotObjective(shotName: 'Cut Shot', count: 10, minAccuracy: 70), ShotObjective(shotName: 'Pull Shot', count: 8, minAccuracy: 70), ShotObjective(shotName: 'Sweep Shot', count: 7, minAccuracy: 70)]),
    CareerLevel(levelNumber: 28, xpReward: 1400, skillReward: 280, objectives: [ShotObjective(shotName: 'Pull Shot', count: 15, minAccuracy: 70), ShotObjective(shotName: 'Cover Drive', count: 10, minAccuracy: 70)]),
    CareerLevel(levelNumber: 29, xpReward: 1450, skillReward: 290, objectives: [ShotObjective(shotName: 'Sweep Shot', count: 15, minAccuracy: 75), ShotObjective(shotName: 'Straight Drive', count: 10, minAccuracy: 75)]),
    CareerLevel(levelNumber: 30, xpReward: 1500, skillReward: 300, objectives: [ShotObjective(shotName: 'Pull Shot', count: 10, minAccuracy: 80), ShotObjective(shotName: 'Sweep Shot', count: 10, minAccuracy: 80), ShotObjective(shotName: 'Cover Drive', count: 5, minAccuracy: 80)]),

    // Levels 31-35
    CareerLevel(levelNumber: 31, xpReward: 1550, skillReward: 310, objectives: [ShotObjective(shotName: 'Pull Shot', count: 15, minAccuracy: 82), ShotObjective(shotName: 'Cut Shot', count: 15, minAccuracy: 82)]),
    CareerLevel(levelNumber: 32, xpReward: 1600, skillReward: 320, objectives: [ShotObjective(shotName: 'Sweep Shot', count: 15, minAccuracy: 82), ShotObjective(shotName: 'Cover Drive', count: 15, minAccuracy: 82)]),
    CareerLevel(levelNumber: 33, xpReward: 1650, skillReward: 330, objectives: [ShotObjective(shotName: 'Straight Drive', count: 10, minAccuracy: 84), ShotObjective(shotName: 'Pull Shot', count: 10, minAccuracy: 84), ShotObjective(shotName: 'Sweep Shot', count: 10, minAccuracy: 84)]),
    CareerLevel(levelNumber: 34, xpReward: 1700, skillReward: 340, objectives: [ShotObjective(shotName: 'Cut Shot', count: 10, minAccuracy: 86), ShotObjective(shotName: 'Pull Shot', count: 10, minAccuracy: 86), ShotObjective(shotName: 'Sweep Shot', count: 10, minAccuracy: 86)]),
    CareerLevel(levelNumber: 35, xpReward: 1750, skillReward: 350, objectives: [ShotObjective(shotName: 'Pull Shot', count: 20, minAccuracy: 88), ShotObjective(shotName: 'Cover Drive', count: 10, minAccuracy: 88)]),

    // Levels 36-40
    CareerLevel(levelNumber: 36, xpReward: 1800, skillReward: 360, objectives: [ShotObjective(shotName: 'Sweep Shot', count: 20, minAccuracy: 90), ShotObjective(shotName: 'Straight Drive', count: 15, minAccuracy: 90)]),
    CareerLevel(levelNumber: 37, xpReward: 1850, skillReward: 370, objectives: [ShotObjective(shotName: 'Cover Drive', count: 15, minAccuracy: 90), ShotObjective(shotName: 'Pull Shot', count: 10, minAccuracy: 90), ShotObjective(shotName: 'Sweep Shot', count: 10, minAccuracy: 90)]),
    CareerLevel(levelNumber: 38, xpReward: 1900, skillReward: 380, objectives: [ShotObjective(shotName: 'Cut Shot', count: 15, minAccuracy: 92), ShotObjective(shotName: 'Pull Shot', count: 20, minAccuracy: 92)]),
    CareerLevel(levelNumber: 39, xpReward: 1950, skillReward: 390, objectives: [ShotObjective(shotName: 'Straight Drive', count: 15, minAccuracy: 94), ShotObjective(shotName: 'Sweep Shot', count: 20, minAccuracy: 94)]),
    CareerLevel(levelNumber: 40, xpReward: 2000, skillReward: 400, objectives: [ShotObjective(shotName: 'Pull Shot', count: 20, minAccuracy: 95), ShotObjective(shotName: 'Sweep Shot', count: 15, minAccuracy: 95), ShotObjective(shotName: 'Cover Drive', count: 15, minAccuracy: 95)]),
  ];
}
