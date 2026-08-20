import '../constants/app_constants.dart';

class FpsTracker {
  FpsTracker({
    this.previousWeight = AppPerf.fpsEmaPrevious,
    this.currentWeight = AppPerf.fpsEmaCurrent,
  });

  final double previousWeight;
  final double currentWeight;

  DateTime? _lastCompletedAt;
  double value = 0;

  void record(DateTime at) {
    final previous = _lastCompletedAt;
    if (previous != null) {
      final dt = at.difference(previous).inMilliseconds;
      if (dt > 0) {
        final instant = 1000 / dt;
        value = value == 0
            ? instant
            : (value * previousWeight + instant * currentWeight);
      }
    }
    _lastCompletedAt = at;
  }

  void reset() {
    _lastCompletedAt = null;
    value = 0;
  }
}
