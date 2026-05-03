import 'dart:math' as math;
import 'dart:ui';

class WorldPoint {
  const WorldPoint({required this.xMeters, required this.yMeters});

  final double xMeters;
  final double yMeters;

  double distanceTo(WorldPoint other) {
    final dx = xMeters - other.xMeters;
    final dy = yMeters - other.yMeters;
    return math.sqrt((dx * dx) + (dy * dy));
  }

  Offset toOffset() => Offset(xMeters, yMeters);

  WorldPoint copyWith({double? xMeters, double? yMeters}) {
    return WorldPoint(
      xMeters: xMeters ?? this.xMeters,
      yMeters: yMeters ?? this.yMeters,
    );
  }

  WorldPoint scale(double factor) {
    return WorldPoint(xMeters: xMeters * factor, yMeters: yMeters * factor);
  }
}
