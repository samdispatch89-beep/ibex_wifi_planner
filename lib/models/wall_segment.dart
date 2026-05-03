import 'material_obstacle.dart';
import 'world_point.dart';

class WallSegment {
  const WallSegment({
    required this.id,
    required this.start,
    required this.end,
    required this.materialType,
    required this.attenuationDb,
    this.floor = 0,
  });

  final String id;
  final WorldPoint start;
  final WorldPoint end;
  final MaterialType materialType;
  final double attenuationDb;
  final int floor;

  double get minX => start.xMeters < end.xMeters ? start.xMeters : end.xMeters;
  double get maxX => start.xMeters > end.xMeters ? start.xMeters : end.xMeters;
  double get minY => start.yMeters < end.yMeters ? start.yMeters : end.yMeters;
  double get maxY => start.yMeters > end.yMeters ? start.yMeters : end.yMeters;
  double get lengthMeters => start.distanceTo(end);

  WallSegment copyWith({
    String? id,
    WorldPoint? start,
    WorldPoint? end,
    MaterialType? materialType,
    double? attenuationDb,
    int? floor,
  }) {
    return WallSegment(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      materialType: materialType ?? this.materialType,
      attenuationDb: attenuationDb ?? this.attenuationDb,
      floor: floor ?? this.floor,
    );
  }
}
