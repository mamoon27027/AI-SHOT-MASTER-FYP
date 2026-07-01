import 'package:flutter/material.dart';

class Tournament {
  final String name;
  final String description;
  final String difficulty;
  final String type;

  Tournament({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.type,
  });
}

class Team {
  final String name;
  final String shortName;
  final Color color;
  final Color textColor;
  final String? flag;

  Team({
    required this.name,
    required this.shortName,
    required this.color,
    required this.textColor,
    this.flag,
  });
}

class Scenario {
  final int runsNeeded;
  final int ballsLeft;
  final Team opponent;
  final String tournamentName;
  final String difficulty;

  Scenario({
    required this.runsNeeded,
    required this.ballsLeft,
    required this.opponent,
    required this.tournamentName,
    required this.difficulty,
  });
}
