import 'dart:math';

import 'package:untitled/core/srs/srs.dart';
import 'package:untitled/data/models/user_word_state.dart';
import 'package:untitled/data/models/word.dart';
import 'package:untitled/data/repositories/repository.dart';

class InMemoryRepository implements Repository {
  final List<WordItem> _catalog = <WordItem>[
    const WordItem(
      id: 'w1',
      english: 'abandon',
      turkish: 'terk etmek',
      partOfSpeech: 'verb',
      example: 'They had to abandon the car in the snow.',
      mnemonic: 'a ban don → yasağa bırakmak gibi düşün',
      categories: ['TOEFL', 'IELTS'],
      level: 'B2',
    ),
    const WordItem(
      id: 'w2',
      english: 'benevolent',
      turkish: 'iyiliksever',
      partOfSpeech: 'adjective',
      example: 'A benevolent donor supported the school.',
      mnemonic: 'bene-volent → benefit, volunteer',
      categories: ['SAT'],
      level: 'C1',
    ),
    const WordItem(
      id: 'w3',
      english: 'contemplate',
      turkish: 'düşünmek, tasarlamak',
      partOfSpeech: 'verb',
      example: 'She contemplated a career change.',
      categories: ['IELTS'],
      level: 'B2-C1',
    ),
  ];

  final Map<String, UserWordState> _userStates = <String, UserWordState>{};

  @override
  List<WordItem> get catalog => List.unmodifiable(_catalog);

  @override
  UserWordState getOrCreateState(String wordId) {
    return _userStates.putIfAbsent(
      wordId,
      () => UserWordState(
        wordId: wordId,
        srsState: SrsEngine.initial(),
        nextReviewAt: DateTime.now(),
        correctCount: 0,
        wrongCount: 0,
      ),
    );
  }

  @override
  List<WordItem> dueWords({int limit = 20}) {
    final now = DateTime.now();
    final List<WordItem> due = [];
    for (final w in _catalog) {
      final st = getOrCreateState(w.id);
      if (!st.nextReviewAt.isAfter(now)) {
        due.add(w);
      }
    }
    return due.take(limit).toList();
  }

  @override
  void applyReview(String wordId, ReviewGrade grade) {
    final current = getOrCreateState(wordId);
    final updatedSrs = SrsEngine.update(current.srsState, grade);
    final int deltaDays = max(1, updatedSrs.intervalDays);
    final next = DateTime.now().add(Duration(days: deltaDays));
    _userStates[wordId] = current.copyWith(
      srsState: updatedSrs,
      nextReviewAt: next,
      correctCount: current.correctCount + (grade == ReviewGrade.again ? 0 : 1),
      wrongCount: current.wrongCount + (grade == ReviewGrade.again ? 1 : 0),
    );
  }

  // Kategoriler/Seviyeler
  @override
  List<String> availableCategories() {
    final set = <String>{};
    for (final w in _catalog) {
      set.addAll(w.categories);
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  List<String> availableLevels() {
    final set = <String>{};
    for (final w in _catalog) {
      if (w.level != null && w.level!.isNotEmpty) set.add(w.level!);
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  List<WordItem> byCategory(String category) {
    return _catalog.where((w) => w.categories.contains(category)).toList(growable: false);
  }

  @override
  List<WordItem> byLevel(String level) {
    return _catalog.where((w) => w.level == level).toList(growable: false);
  }
}


