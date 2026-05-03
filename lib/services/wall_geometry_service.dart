import 'dart:math' as math;

import '../models/wall_segment.dart';
import '../models/world_point.dart';

class WallGeometryService {
  const WallGeometryService();

  WorldPoint snapPoint(WorldPoint anchor, WorldPoint target) {
    final dx = target.xMeters - anchor.xMeters;
    final dy = target.yMeters - anchor.yMeters;
    final angle = math.atan2(dy, dx).abs() * 180 / math.pi;
    if (angle <= 8 || angle >= 172) {
      return WorldPoint(xMeters: target.xMeters, yMeters: anchor.yMeters);
    }
    if ((angle - 90).abs() <= 8) {
      return WorldPoint(xMeters: anchor.xMeters, yMeters: target.yMeters);
    }
    return target;
  }

  bool intersectsSignalPath({
    required WallSegment wall,
    required WorldPoint a,
    required WorldPoint b,
  }) {
    return _segmentsIntersect(wall.start, wall.end, a, b);
  }

  double summedLossForPath({
    required List<WallSegment> walls,
    required WorldPoint a,
    required WorldPoint b,
    required int floor,
  }) {
    var total = 0.0;
    for (final wall in walls) {
      if (wall.floor != floor) {
        continue;
      }
      if (intersectsSignalPath(wall: wall, a: a, b: b)) {
        total += wall.attenuationDb;
      }
    }
    return total;
  }

  bool isDuplicateOrOverlapping({
    required WallSegment candidate,
    required List<WallSegment> existing,
  }) {
    for (final wall in existing) {
      if (_sameEndpoints(candidate, wall)) {
        return true;
      }
      if (_isCollinearOverlap(candidate, wall)) {
        return true;
      }
    }
    return false;
  }

  int? findWallIndexNearPoint({
    required WorldPoint point,
    required List<WallSegment> walls,
    required double toleranceMeters,
  }) {
    var bestIndex = -1;
    var bestDistance = double.infinity;
    for (var index = 0; index < walls.length; index++) {
      final distance = _distancePointToSegment(point, walls[index]);
      if (distance <= toleranceMeters && distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }
    }
    return bestIndex == -1 ? null : bestIndex;
  }

  bool _sameEndpoints(WallSegment a, WallSegment b) {
    final tolerance = 0.08;
    return (a.start.distanceTo(b.start) <= tolerance &&
            a.end.distanceTo(b.end) <= tolerance) ||
        (a.start.distanceTo(b.end) <= tolerance &&
            a.end.distanceTo(b.start) <= tolerance);
  }

  bool _isCollinearOverlap(WallSegment a, WallSegment b) {
    const tolerance = 0.06;
    if (!_collinear(a.start, a.end, b.start, tolerance) ||
        !_collinear(a.start, a.end, b.end, tolerance)) {
      return false;
    }

    final overlapX = math.min(a.maxX, b.maxX) - math.max(a.minX, b.minX);
    final overlapY = math.min(a.maxY, b.maxY) - math.max(a.minY, b.minY);
    return overlapX > tolerance || overlapY > tolerance;
  }

  bool _collinear(WorldPoint a, WorldPoint b, WorldPoint c, double tolerance) {
    final area =
        ((b.xMeters - a.xMeters) * (c.yMeters - a.yMeters)) -
        ((b.yMeters - a.yMeters) * (c.xMeters - a.xMeters));
    return area.abs() <= tolerance;
  }

  bool _segmentsIntersect(
    WorldPoint a,
    WorldPoint b,
    WorldPoint c,
    WorldPoint d,
  ) {
    final denominator =
        ((b.xMeters - a.xMeters) * (d.yMeters - c.yMeters)) -
        ((b.yMeters - a.yMeters) * (d.xMeters - c.xMeters));
    if (denominator.abs() < 0.000001) {
      return false;
    }

    final r =
        (((a.yMeters - c.yMeters) * (d.xMeters - c.xMeters)) -
            ((a.xMeters - c.xMeters) * (d.yMeters - c.yMeters))) /
        denominator;
    final s =
        (((a.yMeters - c.yMeters) * (b.xMeters - a.xMeters)) -
            ((a.xMeters - c.xMeters) * (b.yMeters - a.yMeters))) /
        denominator;
    return r >= 0 && r <= 1 && s >= 0 && s <= 1;
  }

  double _distancePointToSegment(WorldPoint point, WallSegment segment) {
    final dx = segment.end.xMeters - segment.start.xMeters;
    final dy = segment.end.yMeters - segment.start.yMeters;
    final denominator = (dx * dx) + (dy * dy);
    if (denominator <= 0) {
      return point.distanceTo(segment.start);
    }
    final projection =
        (((point.xMeters - segment.start.xMeters) * dx) +
            ((point.yMeters - segment.start.yMeters) * dy)) /
        denominator;
    final clamped = projection.clamp(0.0, 1.0);
    final projectedPoint = WorldPoint(
      xMeters: segment.start.xMeters + (dx * clamped),
      yMeters: segment.start.yMeters + (dy * clamped),
    );
    return point.distanceTo(projectedPoint);
  }
}
