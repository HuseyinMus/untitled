enum ReviewGrade { again, hard, good, easy }

class SrsState {
  final double easinessFactor;
  final int intervalDays;
  final int stage;

  const SrsState({
    required this.easinessFactor,
    required this.intervalDays,
    required this.stage,
  });

  SrsState copyWith({double? easinessFactor, int? intervalDays, int? stage}) {
    return SrsState(
      easinessFactor: easinessFactor ?? this.easinessFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      stage: stage ?? this.stage,
    );
  }
}

class SrsEngine {
  static const double _minEf = 1.3;
  static const double _maxEf = 2.5;

  static SrsState initial() => const SrsState(
        easinessFactor: 2.5,
        intervalDays: 1,
        stage: 0,
      );

  static SrsState update(SrsState state, ReviewGrade grade) {
    int q = switch (grade) {
      ReviewGrade.again => 0,
      ReviewGrade.hard => 3,
      ReviewGrade.good => 4,
      ReviewGrade.easy => 5,
    };

    double newEf = state.easinessFactor +
        (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    newEf = newEf.clamp(_minEf, _maxEf);

    int newInterval = state.intervalDays;
    int newStage = state.stage;

    if (grade == ReviewGrade.again) {
      newStage = 0;
      newInterval = 1;
    } else if (grade == ReviewGrade.hard) {
      newInterval = (newInterval * 1.2).round();
      if (newInterval < 1) newInterval = 1;
    } else if (grade == ReviewGrade.good) {
      newInterval = (newInterval * newEf).round();
      newStage += 1;
    } else {
      newInterval = (newInterval * (newEf + 0.2)).round();
      newStage += 1;
    }

    if (newInterval < 1) newInterval = 1;

    return state.copyWith(
      easinessFactor: newEf,
      intervalDays: newInterval,
      stage: newStage,
    );
  }
}


