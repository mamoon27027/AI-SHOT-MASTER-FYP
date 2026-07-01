import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ea_master_demo/const/appTheme.dart';
import 'dart:math';
import 'scenario_models.dart';
import 'scenario_gameplay_screen.dart';

class ScenarioScreenMain extends StatefulWidget {
  const ScenarioScreenMain({super.key});

  @override
  State<ScenarioScreenMain> createState() => _ScenarioScreenMainState();
}

class _ScenarioScreenMainState extends State<ScenarioScreenMain> {
  Tournament? selectedTournament;
  Team? selectedTeam;
  Scenario? matchScenario;

  final List<Tournament> tournaments = [
    Tournament(name: 'T20 World Cup', description: 'Final Over Chase', difficulty: 'Expert', type: 'international'),
    Tournament(name: 'ODI World Cup', description: 'Last 10 Overs Pressure', difficulty: 'Hard', type: 'international'),
    Tournament(name: 'PSL', description: 'Pakistan Super League', difficulty: 'Medium', type: 'psl'),
    Tournament(name: 'IPL', description: 'Indian Premier League', difficulty: 'Hard', type: 'ipl'),
    Tournament(name: 'The Ashes', description: 'Historic Test Series', difficulty: 'Expert', type: 'ashes'),
  ];

  final List<Team> internationalTeams = [
    Team(name: 'India', shortName: 'IND', color: const Color(0xFF0066CC), textColor: Colors.white, flag: '🇮🇳'),
    Team(name: 'Australia', shortName: 'AUS', color: const Color(0xFFFFD700), textColor: const Color(0xFF0F172A), flag: '🇦🇺'),
    Team(name: 'England', shortName: 'ENG', color: const Color(0xFFCC0000), textColor: Colors.white, flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿'),
    Team(name: 'Pakistan', shortName: 'PAK', color: const Color(0xFF008000), textColor: Colors.white, flag: '🇵🇰'),
    Team(name: 'South Africa', shortName: 'SA', color: const Color(0xFF006633), textColor: Colors.white, flag: '🇿🇦'),
    Team(name: 'New Zealand', shortName: 'NZ', color: const Color(0xFF000000), textColor: Colors.white, flag: '🇳🇿'),
    Team(name: 'West Indies', shortName: 'WI', color: const Color(0xFF7B0041), textColor: Colors.white, flag: '🌴'),
    Team(name: 'Sri Lanka', shortName: 'SL', color: const Color(0xFF003DA5), textColor: Colors.white, flag: '🇱🇰'),
  ];

  final List<Team> pslTeams = [
    Team(name: 'Karachi Kings', shortName: 'KK', color: const Color(0xFF0066CC), textColor: Colors.white),
    Team(name: 'Lahore Qalandars', shortName: 'LQ', color: const Color(0xFF84CC16), textColor: const Color(0xFF0F172A)),
    Team(name: 'Islamabad United', shortName: 'IU', color: const Color(0xFFCC0000), textColor: Colors.white),
    Team(name: 'Peshawar Zalmi', shortName: 'PZ', color: const Color(0xFFFFD700), textColor: const Color(0xFF0F172A)),
    Team(name: 'Quetta Gladiators', shortName: 'QG', color: const Color(0xFF9333EA), textColor: Colors.white),
    Team(name: 'Multan Sultans', shortName: 'MS', color: const Color(0xFFF59E0B), textColor: const Color(0xFF0F172A)),
  ];

  final List<Team> iplTeams = [
    Team(name: 'Mumbai Indians', shortName: 'MI', color: const Color(0xFF0066CC), textColor: Colors.white),
    Team(name: 'Chennai Super Kings', shortName: 'CSK', color: const Color(0xFFFFD700), textColor: const Color(0xFF0F172A)),
    Team(name: 'Royal Challengers', shortName: 'RCB', color: const Color(0xFFCC0000), textColor: Colors.white),
    Team(name: 'Kolkata Knight Riders', shortName: 'KKR', color: const Color(0xFF9333EA), textColor: Colors.white),
    Team(name: 'Delhi Capitals', shortName: 'DC', color: const Color(0xFF38BDF8), textColor: const Color(0xFF0F172A)),
    Team(name: 'Rajasthan Royals', shortName: 'RR', color: const Color(0xFFEC4899), textColor: Colors.white),
    Team(name: 'Punjab Kings', shortName: 'PBKS', color: const Color(0xFFCC0000), textColor: Colors.white),
    Team(name: 'Sunrisers Hyderabad', shortName: 'SRH', color: const Color(0xFFF97316), textColor: const Color(0xFF0F172A)),
  ];

  final List<Team> ashesTeams = [
    Team(name: 'England', shortName: 'ENG', color: const Color(0xFFCC0000), textColor: Colors.white, flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿'),
    Team(name: 'Australia', shortName: 'AUS', color: const Color(0xFFFFD700), textColor: const Color(0xFF0F172A), flag: '🇦🇺'),
  ];

  List<Team> _getTeamsForTournament(String type) {
    switch (type) {
      case 'psl': return pslTeams;
      case 'ipl': return iplTeams;
      case 'ashes': return ashesTeams;
      case 'international':
      default: return internationalTeams;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    if (difficulty == 'Expert') return Colors.redAccent;
    if (difficulty == 'Hard') return Colors.orangeAccent;
    return AppColors.accentGreen;
  }

  Scenario _generateRandomScenario(Team team, Tournament tournament) {
    final availableTeams = _getTeamsForTournament(tournament.type);
    final opponents = availableTeams.where((t) => t.shortName != team.shortName).toList();
    final opponent = opponents[Random().nextInt(opponents.length)];

    int runs = 0;
    int balls = 0;

    final type = tournament.type.toLowerCase();
    final name = tournament.name.toLowerCase();

    if (type == 'psl' || type == 'ipl' || name.contains('t20')) {
      // High pressure T20
      final scenarios = [
        {'runsNeeded': 42, 'ballsLeft': 18},
        {'runsNeeded': 15, 'ballsLeft': 6},
        {'runsNeeded': 50, 'ballsLeft': 24},
        {'runsNeeded': 28, 'ballsLeft': 12},
      ];
      final s = scenarios[Random().nextInt(scenarios.length)];
      runs = s['runsNeeded']!;
      balls = s['ballsLeft']!;
    } else if (name.contains('odi')) {
      // ODI Medium
      final scenarios = [
        {'runsNeeded': 68, 'ballsLeft': 60},
        {'runsNeeded': 45, 'ballsLeft': 45},
        {'runsNeeded': 80, 'ballsLeft': 72},
      ];
      final s = scenarios[Random().nextInt(scenarios.length)];
      runs = s['runsNeeded']!;
      balls = s['ballsLeft']!;
    } else if (type == 'ashes' || name.contains('test')) {
      // Test survival/target
      final scenarios = [
        {'runsNeeded': 35, 'ballsLeft': 60},
        {'runsNeeded': 25, 'ballsLeft': 48},
        {'runsNeeded': 40, 'ballsLeft': 90},
      ];
      final s = scenarios[Random().nextInt(scenarios.length)];
      runs = s['runsNeeded']!;
      balls = s['ballsLeft']!;
    } else {
      // Fallback
      runs = 35;
      balls = 24;
    }

    return Scenario(
      runsNeeded: runs,
      ballsLeft: balls,
      opponent: opponent,
      tournamentName: tournament.name,
      difficulty: tournament.difficulty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: () {
          if (matchScenario != null) return _buildScenarioView();
          if (selectedTournament != null) return _buildTeamsView();
          return _buildMainView();
        }(),
      ),
    );
  }

  Widget _buildMainView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), AppColors.background],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.emoji_events, color: AppColors.accentGreen, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Match Scenarios', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Real tournament pressure situations', style: TextStyle(color: AppColors.textSecondary)),
                    ]
                  )
                )
              ]
            )
          ),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tournaments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final tournament = tournaments[index];
              return InkWell(
                onTap: () => setState(() => selectedTournament = tournament),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tournament.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(tournament.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(tournament.difficulty).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(tournament.difficulty, style: TextStyle(color: _getDifficultyColor(tournament.difficulty), fontSize: 12)),
                          )
                        ]
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.accent),
                    ]
                  )
                )
              );
            }
          )
        ]
      )
    );
  }

  Widget _buildTeamsView() {
    final teams = _getTeamsForTournament(selectedTournament!.type);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => selectedTournament = null),
            icon: const Icon(Icons.arrow_back, color: AppColors.accent, size: 16),
            label: const Text('Back to Tournaments', style: TextStyle(color: AppColors.accent)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          ),
          const SizedBox(height: 16),
          Text(selectedTournament!.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Select your team to begin the challenge', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedTeam = team;
                    matchScenario = _generateRandomScenario(team, selectedTournament!);
                  });
                },
                child: Container(
                   decoration: BoxDecoration(
                     color: const Color(0xFF1E293B),
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(color: team.color.withOpacity(0.4), width: 2),
                   ),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                        Container(
                           width: 64, height: 64,
                           decoration: BoxDecoration(
                             gradient: LinearGradient(
                               colors: [team.color.withOpacity(0.8), team.color],
                               begin: Alignment.topLeft,
                               end: Alignment.bottomRight,
                             ),
                             borderRadius: BorderRadius.circular(16),
                             boxShadow: [
                               BoxShadow(color: team.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                             ]
                           ),
                           alignment: Alignment.center,
                           child: team.flag != null 
                              ? Text(team.flag!, style: const TextStyle(fontSize: 32))
                              : Text(team.shortName, style: TextStyle(color: team.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        Text(team.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(team.shortName, style: TextStyle(color: team.color, fontSize: 12)),
                     ]
                   )
                )
              );
            }
          )
        ]
      )
    );
  }

  Widget _buildScenarioView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => matchScenario = null),
            icon: const Icon(Icons.arrow_back, color: AppColors.accent, size: 16),
            label: const Text('Back', style: TextStyle(color: AppColors.accent)),
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
              children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                      _buildTeamIcon(selectedTeam!),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('vs', style: TextStyle(color: AppColors.textSecondary, fontSize: 24)),
                      ),
                      _buildTeamIcon(matchScenario!.opponent),
                   ]
                 ),
                 const SizedBox(height: 24),
                 Text(matchScenario!.tournamentName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 8),
                 Text(selectedTournament!.description, style: const TextStyle(color: AppColors.textSecondary)),
                 const SizedBox(height: 24),
                 Container(
                   decoration: BoxDecoration(
                     color: AppColors.background,
                     borderRadius: BorderRadius.circular(16),
                   ),
                   padding: const EdgeInsets.all(20),
                   child: Column(
                      children: [
                         Row(
                           children: const [
                             Icon(Icons.gps_fixed, color: AppColors.accentGreen, size: 16),
                             SizedBox(width: 8),
                             Text('Match Situation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                           ]
                         ),
                         const SizedBox(height: 16),
                         _buildSituationRow(Icons.gps_fixed, 'Target', '${matchScenario!.runsNeeded} runs', AppColors.accentGreen),
                         const SizedBox(height: 12),
                         _buildSituationRow(Icons.access_time, 'Balls Left', '${matchScenario!.ballsLeft} balls', AppColors.accent),
                         const SizedBox(height: 12),
                         _buildSituationRow(Icons.emoji_events, 'Difficulty', matchScenario!.difficulty, AppColors.accent, valueColor: _getDifficultyColor(matchScenario!.difficulty)),
                      ]
                   )
                 ),
                 const SizedBox(height: 24),
                 SizedBox(
                   width: double.infinity,
                   height: 56,
                   child: ElevatedButton(
                     onPressed: () {
                       Get.to(() => ScenarioGameplayScreen(scenario: matchScenario!, playerTeam: selectedTeam!));
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.accentGreen,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     ),
                     child: const Text('Start Match', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
                   )
                 )
              ]
            )
          )
        ]
      )
    );
  }

  Widget _buildTeamIcon(Team team) {
    return Column(
      children: [
        Container(
           width: 64, height: 64,
           decoration: BoxDecoration(
             gradient: LinearGradient(
               colors: [team.color.withOpacity(0.8), team.color],
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
             ),
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: team.color, width: 2),
             boxShadow: [
               BoxShadow(color: team.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
             ]
           ),
           alignment: Alignment.center,
           child: team.flag != null 
              ? Text(team.flag!, style: const TextStyle(fontSize: 32))
              : Text(team.shortName, style: TextStyle(color: team.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(team.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]
    );
  }

  Widget _buildSituationRow(IconData icon, String label, String value, Color iconColor, {Color valueColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Row(
             children: [
               Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: iconColor.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Icon(icon, color: iconColor, size: 20),
               ),
               const SizedBox(width: 12),
               Text(label, style: const TextStyle(color: AppColors.textSecondary)),
             ]
           ),
           Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold)),
        ]
      )
    );
  }
}
