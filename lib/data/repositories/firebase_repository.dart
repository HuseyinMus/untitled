import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/core/srs/srs.dart';
import 'package:untitled/data/models/user_word_state.dart';
import 'package:untitled/data/models/word.dart';
import 'package:untitled/data/repositories/repository.dart';

class FirebaseRepository implements Repository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FirebaseRepository(this._db, this._auth);

  String get _uid => _auth.currentUser!.uid;

  @override
  List<WordItem> get catalog => _catalogCache;
  List<WordItem> _catalogCache = const <WordItem>[];

  Future<bool> ensureSignedInAnonymously() async {
    if (_auth.currentUser != null) return true;
    try {
      await _auth.signInAnonymously();
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  Future<void> loadCatalogOnce() async {
    if (_catalogCache.isNotEmpty) return;
    try {
      // Tüm katalogu sayfalayarak çek (500'lük partiler)
      const int pageSize = 500;
      final List<WordItem> all = <WordItem>[];
      Query<Map<String, dynamic>> baseQuery =
          _db.collection('catalog_words').orderBy(FieldPath.documentId).limit(pageSize);
      DocumentSnapshot<Map<String, dynamic>>? lastDoc;
      while (true) {
        final Query<Map<String, dynamic>> q =
            lastDoc == null ? baseQuery : baseQuery.startAfterDocument(lastDoc);
        final snap = await q.get();
        if (snap.docs.isEmpty) break;
        for (final d in snap.docs) {
          final m = d.data();
          all.add(WordItem(
            id: d.id,
            english: m['en'] ?? '',
            turkish: m['tr'] ?? '',
            partOfSpeech: m['pos'] ?? '',
            example: m['example'] ?? '',
            imageUrl: m['imageUrl'],
            audioUrl: m['audioUrl'],
            mnemonic: m['mnemonic'],
            categories: (m['categories'] is List)
                ? List<String>.from(m['categories'] as List)
                : const <String>[],
            level: (m['level'] as String?)?.trim(),
          ));
        }
        lastDoc = snap.docs.last;
        if (snap.docs.length < pageSize) break; // son sayfa
      }
      _catalogCache = all;
    } on FirebaseException {
      _catalogCache = const <WordItem>[];
    }
  }

  @override
  UserWordState getOrCreateState(String wordId) {
    // Senkron olmayan interface için minimal cache: çağırılmadan önce fetch edilecek
    throw UnimplementedError('Use getUserWordStateAsync');
  }

  Future<UserWordState> getUserWordStateAsync(String wordId) async {
    final doc = await _db.collection('users').doc(_uid).collection('words').doc(wordId).get();
    if (!doc.exists) {
      final s = UserWordState(
        wordId: wordId,
        srsState: SrsEngine.initial(),
        nextReviewAt: DateTime.now(),
        correctCount: 0,
        wrongCount: 0,
      );
      return s;
    }
    final m = doc.data()!;
    return UserWordState(
      wordId: wordId,
      srsState: SrsState(
        easinessFactor: (m['ef'] ?? 2.5).toDouble(),
        intervalDays: (m['intervalDays'] ?? 1) as int,
        stage: (m['stage'] ?? 0) as int,
      ),
      nextReviewAt: (m['nextReviewAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      correctCount: (m['correctCount'] ?? 0) as int,
      wrongCount: (m['wrongCount'] ?? 0) as int,
    );
  }

  @override
  List<WordItem> dueWords({int limit = 20}) {
    // Senkron olmayan interface için placeholder; UI tarafı async sürüme geçmeli
    return catalog.take(limit).toList();
  }

  Future<List<WordItem>> dueWordsAsync({int limit = 20}) async {
    final now = Timestamp.fromDate(DateTime.now());
    final q = await _db
        .collection('users')
        .doc(_uid)
        .collection('words')
        .where('nextReviewAt', isLessThanOrEqualTo: now)
        .limit(limit)
        .get();
    if (q.docs.isEmpty) return <WordItem>[];
    final ids = q.docs.map((d) => d.id).toSet();
    return catalog.where((w) => ids.contains(w.id)).toList();
  }

  @override
  void applyReview(String wordId, ReviewGrade grade) {
    // Async sürümü kullan
    throw UnimplementedError('Use applyReviewAsync');
  }

  Future<void> applyReviewAsync(String wordId, ReviewGrade grade) async {
    final current = await getUserWordStateAsync(wordId);
    final updated = SrsEngine.update(current.srsState, grade);
    final next = DateTime.now().add(Duration(days: updated.intervalDays));
    await _db
        .collection('users')
        .doc(_uid)
        .collection('words')
        .doc(wordId)
        .set({
      'ef': updated.easinessFactor,
      'intervalDays': updated.intervalDays,
      'stage': updated.stage,
      'nextReviewAt': Timestamp.fromDate(next),
      'correctCount': current.correctCount + (grade == ReviewGrade.again ? 0 : 1),
      'wrongCount': current.wrongCount + (grade == ReviewGrade.again ? 1 : 0),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Kategoriler/Seviyeler
  @override
  List<String> availableCategories() {
    final set = <String>{};
    for (final w in _catalogCache) {
      set.addAll(w.categories);
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  List<String> availableLevels() {
    final set = <String>{};
    for (final w in _catalogCache) {
      if (w.level != null && w.level!.isNotEmpty) set.add(w.level!);
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  List<WordItem> byCategory(String category) {
    return _catalogCache.where((w) => w.categories.contains(category)).toList(growable: false);
  }

  @override
  List<WordItem> byLevel(String level) {
    return _catalogCache.where((w) => w.level == level).toList(growable: false);
  }
}


