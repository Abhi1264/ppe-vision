import 'package:flutter_test/flutter_test.dart';

import 'package:ppe_vision/core/utils/fps_tracker.dart';

void main() {
  test('records an exponential moving average', () {
    final tracker = FpsTracker();
    final start = DateTime(2026, 1, 1, 12);
    tracker.record(start);
    tracker.record(start.add(const Duration(milliseconds: 100)));
    expect(tracker.value, closeTo(10, 0.01));
    tracker.record(start.add(const Duration(milliseconds: 200)));
    expect(tracker.value, closeTo(10, 0.01));
    tracker.reset();
    expect(tracker.value, 0);
  });
}
