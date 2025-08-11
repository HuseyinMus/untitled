import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/core/srs/srs.dart';

void main() {
  group('SrsEngine', () {
    test('initial state', () {
      final s = SrsEngine.initial();
      expect(s.easinessFactor, 2.5);
      expect(s.intervalDays, 1);
      expect(s.stage, 0);
    });

    test('again resets stage and interval to minimum', () {
      final s = const SrsState(easinessFactor: 2.5, intervalDays: 5, stage: 3);
      final u = SrsEngine.update(s, ReviewGrade.again);
      expect(u.stage, 0);
      expect(u.intervalDays >= 1, true);
    });

    test('good increases stage and interval', () {
      final s = const SrsState(easinessFactor: 2.0, intervalDays: 2, stage: 1);
      final u = SrsEngine.update(s, ReviewGrade.good);
      expect(u.stage, greaterThan(s.stage));
      expect(u.intervalDays, greaterThanOrEqualTo( (s.intervalDays * s.easinessFactor).round() ));
    });

    test('ef is clamped within bounds', () {
      var s = const SrsState(easinessFactor: 2.5, intervalDays: 1, stage: 0);
      s = SrsEngine.update(s, ReviewGrade.again); // should reduce ef but not below min
      expect(s.easinessFactor >= 1.3, true);
    });
  });
}


