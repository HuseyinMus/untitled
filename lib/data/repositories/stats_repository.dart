import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatsRepository {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;

  static String _todayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  static Future<void> recordQuizAnswer({required bool isCorrect, int xpOnCorrect = 10}) async {
    if (_auth.currentUser == null) return;
    try {
      final now = DateTime.now();
      final today = _todayKey(now);
      final dailyRef = _db.collection('users').doc(_uid).collection('stats').doc('daily').collection('days').doc(today);
      final summaryRef = _db.collection('users').doc(_uid).collection('stats').doc('summary');
      final batch = _db.batch();
      batch.set(dailyRef, {
        'date': today,
        'correct': FieldValue.increment(isCorrect ? 1 : 0),
        'wrong': FieldValue.increment(isCorrect ? 0 : 1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(summaryRef, {
        'xp': FieldValue.increment(isCorrect ? xpOnCorrect : 0),
        'lastActiveDate': today,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
      await _updateStreak(summaryRef, today);
      await _syncLeaderboard();
    } catch (_) {
      // Firestore kısıtları nedeniyle yazım başarısız olabilir; sessizce yoksay
    }
  }

  static Future<void> recordStudyReview({required bool isCorrect}) async {
    if (_auth.currentUser == null) return;
    try {
      final now = DateTime.now();
      final today = _todayKey(now);
      final dailyRef = _db.collection('users').doc(_uid).collection('stats').doc('daily').collection('days').doc(today);
      final summaryRef = _db.collection('users').doc(_uid).collection('stats').doc('summary');
      final batch = _db.batch();
      batch.set(dailyRef, {
        'date': today,
        'studied': FieldValue.increment(1),
        'correct': FieldValue.increment(isCorrect ? 1 : 0),
        'wrong': FieldValue.increment(isCorrect ? 0 : 1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(summaryRef, {
        'lastActiveDate': today,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
      await _updateStreak(summaryRef, today);
    } catch (_) {
      // Firestore kısıtları nedeniyle yazım başarısız olabilir; sessizce yoksay
    }
  }

  static Future<void> _updateStreak(DocumentReference<Map<String, dynamic>> summaryRef, String today) async {
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(summaryRef);
        final data = snap.data() ?? {};
        final String? lastDate = data['lastActiveDate'] as String?;
        final int currentStreak = (data['streak'] as num?)?.toInt() ?? 0;
        int nextStreak = currentStreak;
        if (lastDate == null) {
          nextStreak = 1;
        } else {
          // Basit kontrol: ardışık gün mü? (üretim için daha sağlam date hesaplanabilir)
          if (lastDate != today) {
            nextStreak = (today == _adjacentDayKey(lastDate)) ? currentStreak + 1 : 1;
          }
        }
        tx.set(summaryRef, {'streak': nextStreak, 'lastActiveDate': today}, SetOptions(merge: true));
      });
    } catch (_) {
      // Yetki/kurallar nedeniyle başarısız olabilir
    }
  }

  static String _adjacentDayKey(String yyyymmdd) {
    final y = int.parse(yyyymmdd.substring(0, 4));
    final m = int.parse(yyyymmdd.substring(4, 6));
    final d = int.parse(yyyymmdd.substring(6, 8));
    final dt = DateTime(y, m, d).add(const Duration(days: 1));
    return _todayKey(dt);
  }

  static Future<Map<String, dynamic>> getSummary() async {
    try {
      if (_auth.currentUser == null) return {};
      final doc = await _db.collection('users').doc(_uid).collection('stats').doc('summary').get();
      return doc.data() ?? {};
    } catch (_) {
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getDailyLast(int count) async {
    try {
      if (_auth.currentUser == null) return [];
      final col = await _db
          .collection('users')
          .doc(_uid)
          .collection('stats')
          .doc('daily')
          .collection('days')
          .orderBy('date', descending: true)
          .limit(count)
          .get();
      return col.docs.map((d) => d.data()).toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  static Future<void> _syncLeaderboard() async {
    try {
      if (_auth.currentUser == null) return;
      final user = _auth.currentUser!;
      final summary = await getSummary();
      final xp = (summary['xp'] as num?)?.toInt() ?? 0;
      await _db.collection('leaderboard').doc(_uid).set({
        'displayName': user.displayName ?? user.email ?? 'User',
        'photoUrl': user.photoURL,
        'xp': xp,
        'countryCode': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Yetki/kurallar nedeniyle başarısız olabilir
    }
  }

  static Future<List<Map<String, dynamic>>> getLeaderboardTop({int limit = 50}) async {
    try {
      final col = await _db.collection('leaderboard').orderBy('xp', descending: true).limit(limit).get();
      return col.docs.map((d) => d.data()).toList(growable: false);
    } catch (_) {
      return [];
    }
  }
}


