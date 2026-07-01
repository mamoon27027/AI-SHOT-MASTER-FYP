import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:ea_master_demo/auth/authService.dart';

class CareerService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = Get.find<AuthService>();

  // Observable list of completed level numbers
  RxList<int> completedLevels = <int>[].obs;
  
  // High score / best accuracy per level
  RxMap<int, Map<String, dynamic>> levelStats = <int, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Re-fetch when user changes
    ever(_auth.user, (user) {
      if (user != null) {
        _listenToUserLevels(user.uid);
      } else {
        completedLevels.clear();
        levelStats.clear();
      }
    });
    
    if (_auth.currentUser != null) {
      _listenToUserLevels(_auth.currentUser!.uid);
    }
  }

  void _listenToUserLevels(String uid) {
    _db.collection('users').doc(uid).collection('levels').snapshots().listen((snapshot) {
      final Set<int> completed = {};
      final Map<int, Map<String, dynamic>> stats = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final levelNum = int.tryParse(doc.id) ?? 0;
        if (levelNum > 0) {
          completed.add(levelNum);
          stats[levelNum] = data;
        }
      }

      completedLevels.assignAll(completed.toList());
      levelStats.assignAll(stats);
    });
  }

  int get maxUnlockedLevel {
    if (completedLevels.isEmpty) return 1;
    int maxCompleted = completedLevels.reduce((a, b) => a > b ? a : b);
    return maxCompleted < 40 ? maxCompleted + 1 : 40;
  }

  int get totalXp {
    int xp = 0;
    for (var stat in levelStats.values) {
      if (stat.containsKey('xpEarned')) {
        xp += (stat['xpEarned'] as num).toInt();
      }
    }
    return xp;
  }

  Future<void> saveLevelProgress(int levelNumber, Map<String, dynamic> results) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db.collection('users').doc(user.uid).collection('levels').doc(levelNumber.toString());
    
    await docRef.set({
      'levelNumber': levelNumber,
      'lastPlayed': FieldValue.serverTimestamp(),
      'results': results,
      'completed': true,
    }, SetOptions(merge: true));
  }
}
