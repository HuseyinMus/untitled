import 'package:untitled/core/srs/srs.dart';

class UserWordState {
  final String wordId;
  final SrsState srsState;
  final DateTime nextReviewAt;
  final int correctCount;
  final int wrongCount;

  const UserWordState({
    required this.wordId,
    required this.srsState,
    required this.nextReviewAt,
    required this.correctCount,
    required this.wrongCount,
  });

  UserWordState copyWith({
    SrsState? srsState,
    DateTime? nextReviewAt,
    int? correctCount,
    int? wrongCount,
  }) {
    return UserWordState(
      wordId: wordId,
      srsState: srsState ?? this.srsState,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
    );
  }
}


