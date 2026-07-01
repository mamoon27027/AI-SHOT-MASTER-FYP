import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:ea_master_demo/auth/authService.dart';

class TrainService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = Get.find<AuthService>();

  // Map of shotName -> stats (mastery, sessions)
  RxMap<String, Map<String, dynamic>> shotStats = <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    ever(_auth.user, (user) {
      if (user != null) {
        _listenToUserTrainings(user.uid);
      } else {
        shotStats.clear();
      }
    });

    if (_auth.currentUser != null) {
      _listenToUserTrainings(_auth.currentUser!.uid);
    }
  }

  void _listenToUserTrainings(String uid) {
    _db.collection('users').doc(uid).collection('trainings').snapshots().listen((snapshot) {
      final Map<String, Map<String, dynamic>> stats = {};

      for (var doc in snapshot.docs) {
        stats[doc.id] = doc.data(); // doc.id is the shotName
      }

      shotStats.assignAll(stats);
    });
  }

  Future<void> saveTrainingSession(String shotName, double newAccuracy) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db.collection('users').doc(user.uid).collection('trainings').doc(shotName);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      double currentMastery = 0.0;
      int currentSessions = 0;

      if (snapshot.exists) {
        final data = snapshot.data()!;
        currentMastery = (data['mastery'] ?? 0.0).toDouble();
        currentSessions = (data['sessions'] ?? 0) as int;
      }

      // Moving average calculation
      double updatedMastery = ((currentMastery * currentSessions) + newAccuracy) / (currentSessions + 1);
      int updatedSessions = currentSessions + 1;

      transaction.set(docRef, {
        'mastery': updatedMastery,
        'sessions': updatedSessions,
        'lastPlayed': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
