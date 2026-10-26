import 'package:flutter_test/flutter_test.dart';
import 'package:ppe_vision/services/compliance/violation_streak.dart';

void main() {
  test('fires once after the confirm streak, then waits for a clear frame', () {
    final streak = ViolationStreak();
    expect(
      streak.tick(missingHardhat: true, missingVest: false, confirm: 2),
      isEmpty,
    );
    expect(
      streak.tick(missingHardhat: true, missingVest: false, confirm: 2),
      ['missing_hardhat'],
    );
    expect(
      streak.tick(missingHardhat: true, missingVest: false, confirm: 2),
      isEmpty,
    );
    streak.tick(missingHardhat: false, missingVest: false, confirm: 2);
    expect(
      streak.tick(missingHardhat: true, missingVest: true, confirm: 1),
      ['missing_hardhat', 'missing_vest'],
    );
  });
}
