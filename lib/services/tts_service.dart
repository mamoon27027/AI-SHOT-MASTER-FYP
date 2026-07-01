import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

class TtsService extends GetxService {
  final FlutterTts _flutterTts = FlutterTts();
  final Random _random = Random();

  @override
  void onInit() {
    super.onInit();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  final List<String> _speechQueue = [];
  bool _isSpeaking = false;

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      _speechQueue.add(text);
      if (!_isSpeaking) {
        _processQueue();
      }
    }
  }

  Future<void> _processQueue() async {
    if (_speechQueue.isEmpty) {
      _isSpeaking = false;
      return;
    }
    _isSpeaking = true;
    final text = _speechQueue.removeAt(0);
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      // ignore errors
    }
    _processQueue();
  }

  void stop() {
    _speechQueue.clear();
    _isSpeaking = false;
    _flutterTts.stop();
  }

  Future<void> waitUntilDone() async {
    while (_isSpeaking || _speechQueue.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  String _getRandom(List<String> list) => list[_random.nextInt(list.length)];

  // --- Sentence Pools ---

  final List<String> _welcomeLines = [
    "Welcome back, champion.",
    "Ready to continue your batting journey?",
    "Your next challenge is waiting.",
    "Focus mode activated.",
    "Today’s training session is starting now.",
    "Step into position and prepare.",
    "Your progress is improving every session.",
    "Let’s sharpen your batting skills.",
    "Another level is ready for you.",
    "Prepare yourself for the next challenge.",
    "Time to improve your cricket performance.",
    "Let’s begin your next batting mission.",
    "Stay focused and trust your technique.",
    "Your training session is now active.",
    "Get ready to face the challenge."
  ];

  final List<String> _objectiveLines = [
    "You need to complete [TARGET_COUNT] successful [SHOT_NAME] attempts.",
    "Your target is [ACCURACY_PERCENTAGE] accuracy in [SHOT_NAME].",
    "Complete the required [SHOT_NAME] shots within the available attempts.",
    "Stay focused and finish the challenge.",
    "Maintain consistency during the session.",
    "Your mission is to improve [SHOT_NAME] execution.",
    "Focus on completing clean [SHOT_NAME] attempts.",
    "Accuracy and timing will decide this mission.",
    "Complete the required objective before attempts run out.",
    "Consistency is the key to success here."
  ];

  final List<String> _readyLines = [
    "Get ready for the shot.",
    "Move into position.",
    "Prepare yourself.",
    "Ready for the next delivery.",
    "Focus on your timing.",
    "Set your stance.",
    "Eyes on the ball.",
    "Prepare for execution.",
    "Stay balanced and ready.",
    "Focus on clean movement.",
    "The next attempt is about to begin.",
    "Return to starting position.",
    "Get into your batting stance.",
    "Prepare for the next shot.",
    "Ready when you are."
  ];

  final List<String> _analysisLines = [
    "Excellent [SHOT_NAME] execution.",
    "That was a clean [SHOT_NAME].",
    "Good timing on the [SHOT_NAME].",
    "Your [SHOT_NAME] footwork looked solid.",
    "That [SHOT_NAME] was much better.",
    "Nice improvement in [SHOT_NAME] accuracy.",
    "[SHOT_NAME] detected successfully.",
    "Your balance was good on that [SHOT_NAME].",
    "Strong contact on the [SHOT_NAME].",
    "Your shot control looked sharp.",
    "Excellent body positioning during the [SHOT_NAME].",
    "You connected well with the ball.",
    "That was a technically strong [SHOT_NAME].",
    "Your [SHOT_NAME] timing continues to improve.",
    "That was one of your best [SHOT_NAME] attempts."
  ];

  final List<String> _accuracyLines = [
    "Your accuracy was [ACCURACY_PERCENTAGE] percent.",
    "Current accuracy recorded at [ACCURACY_PERCENTAGE] percent.",
    "You achieved [ACCURACY_PERCENTAGE] percent accuracy on that attempt.",
    "Shot precision reached [ACCURACY_PERCENTAGE] percent.",
    "Your execution accuracy is [ACCURACY_PERCENTAGE] percent.",
    "The system measured [ACCURACY_PERCENTAGE] percent accuracy.",
    "Accuracy score updated to [ACCURACY_PERCENTAGE] percent.",
    "Your shot consistency reached [ACCURACY_PERCENTAGE] percent.",
    "Technical accuracy for this attempt was [ACCURACY_PERCENTAGE] percent.",
    "You completed the shot with [ACCURACY_PERCENTAGE] percent precision."
  ];

  final List<String> _strengthLines = [
    "Your strongest area was [STRENGTH_NAME].",
    "[STRENGTH_NAME] looked very solid.",
    "Good control in [STRENGTH_NAME].",
    "Your [STRENGTH_NAME] is improving.",
    "[STRENGTH_NAME] was excellent during that attempt.",
    "You showed strong [STRENGTH_NAME].",
    "The system detected good [STRENGTH_NAME].",
    "[STRENGTH_NAME] helped improve your shot quality.",
    "Your performance in [STRENGTH_NAME] was impressive.",
    "[STRENGTH_NAME] was one of your key strengths."
  ];

  final List<String> _weaknessLines = [
    "Your weakest area was [WEAKNESS_NAME].",
    "[WEAKNESS_NAME] needs improvement.",
    "Focus more on [WEAKNESS_NAME].",
    "Your [WEAKNESS_NAME] affected shot quality.",
    "The system detected weakness in [WEAKNESS_NAME].",
    "You need better control in [WEAKNESS_NAME].",
    "[WEAKNESS_NAME] reduced your shot consistency.",
    "Try improving [WEAKNESS_NAME] on the next attempt.",
    "Your [WEAKNESS_NAME] was slightly unstable.",
    "[WEAKNESS_NAME] should be your next focus area."
  ];

  final List<String> _trendLines = [
    "Your performance trend is [TREND_STATUS].",
    "The system detected a [TREND_STATUS] improvement pattern.",
    "Your batting trend currently looks [TREND_STATUS].",
    "Session progress is [TREND_STATUS].",
    "Your overall consistency trend is [TREND_STATUS].",
    "Current performance momentum is [TREND_STATUS].",
    "Your improvement curve is [TREND_STATUS].",
    "Training progress appears [TREND_STATUS].",
    "Your recent performance trend is [TREND_STATUS].",
    "The system recorded a [TREND_STATUS] progression."
  ];

  final List<String> _retryLines = [
    "Play the [SHOT_NAME] again.",
    "Let’s try that [SHOT_NAME] once more.",
    "Focus and repeat the [SHOT_NAME].",
    "Reset and try the [SHOT_NAME] again.",
    "Prepare for another [SHOT_NAME] attempt.",
    "Let’s improve that [SHOT_NAME].",
    "Take another [SHOT_NAME] attempt.",
    "Focus on cleaner execution.",
    "Repeat the shot with better balance.",
    "Try to improve your timing on the next attempt."
  ];

  final List<String> _successLines = [
    "Excellent work, level completed.",
    "Great job, you passed the challenge.",
    "Your batting performance was impressive.",
    "Mission completed successfully.",
    "Outstanding consistency throughout the session.",
    "You handled the challenge very well.",
    "Your improvement was clearly visible.",
    "Training objective achieved.",
    "Excellent progress in today’s session.",
    "You completed the session with strong performance."
  ];

  final List<String> _failLines = [
    "Good effort, let’s improve next time.",
    "Keep practicing and try again.",
    "Don’t lose focus, you are improving.",
    "Consistency will make you better.",
    "Let’s come back stronger.",
    "Every attempt improves your skills.",
    "Focus on technique and try again.",
    "Mistakes are part of improvement.",
    "You are progressing with every session.",
    "Keep training and your performance will improve."
  ];

  final List<String> _scenarioObjectiveLines = [
    "You need [RUNS_REQUIRED] runs from [BALLS_LEFT] balls.",
    "Pressure situation, stay focused.",
    "The pressure is increasing.",
    "A boundary is needed here.",
    "The match situation is getting intense."
  ];

  final List<String> _scenarioNextBallLines = [
    "The next delivery is a [BALL_TYPE].",
    "Prepare for a [BALL_TYPE] delivery."
  ];

  final List<String> _scenarioResultLines = [
    "That was the correct [SHOT_NAME] selection.",
    "Excellent [SHOT_NAME], boundary scored.",
    "Poor shot choice, wicket lost.",
    "You mistimed the delivery.",
    "Perfect connection on the [SHOT_NAME].",
    "You survived the delivery.",
    "That was a risky [SHOT_NAME].",
    "Excellent decision under pressure."
  ];

  final List<String> _scenarioClosingSuccessLines = [
    "Outstanding chase completed.",
    "You handled the pressure brilliantly.",
    "Excellent batting under pressure.",
    "The chase was well managed.",
    "You stayed calm in a difficult situation.",
    "The scenario was completed successfully."
  ];

  final List<String> _scenarioClosingFailLines = [
    "The target was not achieved.",
    "Better shot selection was needed.",
    "Good match awareness overall.",
    "You fought hard until the end."
  ];

  final List<String> _trainingWelcomeLines = [
    "Today we are practicing the [SHOT_NAME].",
    "Focus on clean bat movement for the [SHOT_NAME].",
    "Keep your head steady during the [SHOT_NAME]."
  ];

  final List<String> _trainingWrongShotLines = [
    "No proper [SHOT_NAME] detected.",
    "Play the correct [SHOT_NAME] again.",
    "Return to starting position.",
    "Prepare for the next [SHOT_NAME] attempt."
  ];

  // --- Dynamic Methods ---

  Future<void> speakWelcome() async {
    await speak(_getRandom(_welcomeLines));
  }

  Future<void> speakObjective(String targetCount, String shotName, String accuracy) async {
    String text = _getRandom(_objectiveLines)
        .replaceAll("[TARGET_COUNT]", targetCount)
        .replaceAll("[SHOT_NAME]", shotName)
        .replaceAll("[ACCURACY_PERCENTAGE]", accuracy);
    await speak(text);
  }

  Future<void> speakReady() async {
    await speak(_getRandom(_readyLines));
  }

  Future<void> speakAnalysis(String shotName, int accuracy, String strength, String weakness, String trend) async {
    String analysis = _getRandom(_analysisLines).replaceAll("[SHOT_NAME]", shotName);
    String acc = _getRandom(_accuracyLines).replaceAll("[ACCURACY_PERCENTAGE]", accuracy.toString());
    
    String str = "";
    if (strength.isNotEmpty && strength != "N/A" && strength != "None") {
      str = _getRandom(_strengthLines).replaceAll("[STRENGTH_NAME]", strength);
    }
    
    String wk = "";
    if (weakness.isNotEmpty && weakness != "N/A" && weakness != "None") {
      wk = _getRandom(_weaknessLines).replaceAll("[WEAKNESS_NAME]", weakness);
    }
    
    String tr = "";
    if (trend.isNotEmpty) {
      tr = _getRandom(_trendLines).replaceAll("[TREND_STATUS]", trend);
    }
    
    // Combine them smoothly. FlutterTts will read it sentence by sentence automatically.
    await speak("$analysis $acc $str $wk $tr");
  }

  Future<void> speakRetry(String shotName) async {
    String text = _getRandom(_retryLines).replaceAll("[SHOT_NAME]", shotName);
    await speak(text);
  }

  Future<void> speakSuccess() async {
    await speak(_getRandom(_successLines));
  }

  Future<void> speakFailure() async {
    await speak(_getRandom(_failLines));
  }

  Future<void> speakScenarioObjective(int runsNeeded, int ballsLeft) async {
    String text = _getRandom(_scenarioObjectiveLines)
        .replaceAll("[RUNS_REQUIRED]", runsNeeded.toString())
        .replaceAll("[BALLS_LEFT]", ballsLeft.toString());
    await speak(text);
  }

  Future<void> speakScenarioNextBall(String ballType) async {
    String text = _getRandom(_scenarioNextBallLines).replaceAll("[BALL_TYPE]", ballType);
    await speak(text);
  }

  Future<void> speakScenarioResultCorrect(String shotName, bool isBoundary) async {
    String text = isBoundary 
        ? "Excellent $shotName, boundary scored." 
        : "That was the correct $shotName selection.";
    await speak(text);
  }

  Future<void> speakScenarioResultWrong(bool isWicket) async {
    String text = isWicket 
        ? "Poor shot choice, wicket lost." 
        : "You mistimed the delivery.";
    await speak(text);
  }

  Future<void> speakScenarioEnd(bool isWin) async {
    await speak(_getRandom(isWin ? _scenarioClosingSuccessLines : _scenarioClosingFailLines));
  }

  Future<void> speakTrainingWelcome(String shotName) async {
    String text = _getRandom(_trainingWelcomeLines).replaceAll("[SHOT_NAME]", shotName);
    await speak(text);
  }

  Future<void> speakTrainingWrongShot(String targetShot) async {
    final list = [
      "Come on, let's focus. We are practicing the $targetShot.",
      "That wasn't quite right. Try the $targetShot again.",
      "Keep your eye on the ball. Play the $targetShot."
    ];
    await speak((list..shuffle()).first);
  }

  Future<void> speakMismatchedShot(String expectedShot) async {
    final list = [
      "I am not able to detect that shot. Please play a $expectedShot.",
      "That was not a $expectedShot. Try again.",
      "Wrong shot played. The objective is a $expectedShot."
    ];
    await speak((list..shuffle()).first);
  }
}
