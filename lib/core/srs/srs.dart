enum ReviewGrade { again, hard, good, easy }

class SrsState {
  final double easinessFactor;
  final int intervalDays;
  final int stage;
  final int lapseCount;

  const SrsState({
    required this.easinessFactor,
    required this.intervalDays,
    required this.stage,
    this.lapseCount = 0,
  });

  SrsState copyWith({double? easinessFactor, int? intervalDays, int? stage, int? lapseCount}) {
    return SrsState(
      easinessFactor: easinessFactor ?? this.easinessFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      stage: stage ?? this.stage,
      lapseCount: lapseCount ?? this.lapseCount,
    );
  }
}

class SrsEngine {
  static const double _minEf = 1.3;
  static const double _maxEf = 2.5;
  static const int _maxIntervalDays = 365; // güvenli üst sınır

  static SrsState initial() => const SrsState(
        easinessFactor: 2.5,
        intervalDays: 1,
        stage: 0,
        lapseCount: 0,
      );

  static SrsState update(SrsState state, ReviewGrade grade) {
    // SM-2 tabanlı EF güncellemesi
    final int q = switch (grade) {
      ReviewGrade.again => 0,
      ReviewGrade.hard => 3,
      ReviewGrade.good => 4,
      ReviewGrade.easy => 5,
    };

    double newEf = state.easinessFactor - 0.8 + 0.28 * q - 0.02 * q * q;
    newEf = newEf.clamp(_minEf, _maxEf);

    int newStage = state.stage;
    int newInterval = state.intervalDays;
    int newLapses = state.lapseCount;

    if (grade == ReviewGrade.again) {
      // Lapse: aşamayı sıfırla, EF zaten düştü, minimum aralık uygula
      newStage = 0;
      newLapses += 1;
      newInterval = 1;
    } else if (grade == ReviewGrade.hard) {
      // Zor: aşamayı ilerletmeden küçük artış
      newInterval = (newInterval * 1.2).round();
      if (newInterval < 1) newInterval = 1;
    } else if (grade == ReviewGrade.good) {
      // İyi: EF ile ölçekle ve aşamayı artır
      newInterval = (newInterval * newEf).round();
      newStage += 1;
    } else {
      // Kolay: biraz daha agresif büyüme
      newInterval = (newInterval * (newEf + 0.2)).round();
      newStage += 1;
    }

    if (newInterval < 1) newInterval = 1;
    if (newInterval > _maxIntervalDays) newInterval = _maxIntervalDays;

    return state.copyWith(
      easinessFactor: newEf,
      intervalDays: newInterval,
      stage: newStage,
      lapseCount: newLapses,
    );
  }
}


