enum MaterialType { drywall, glass, brick, concrete, metalRack, humanCluster }

extension MaterialTypeX on MaterialType {
  String get label {
    switch (this) {
      case MaterialType.drywall:
        return 'Drywall';
      case MaterialType.glass:
        return 'Glass';
      case MaterialType.brick:
        return 'Brick';
      case MaterialType.concrete:
        return 'Concrete';
      case MaterialType.metalRack:
        return 'Metal rack';
      case MaterialType.humanCluster:
        return 'Human cluster';
    }
  }

  double get defaultLossDb {
    switch (this) {
      case MaterialType.drywall:
        return 3;
      case MaterialType.glass:
        return 2;
      case MaterialType.brick:
        return 6;
      case MaterialType.concrete:
        return 15;
      case MaterialType.metalRack:
        return 18;
      case MaterialType.humanCluster:
        return 4;
    }
  }
}

class MaterialObstacle {
  const MaterialObstacle({
    required this.id,
    required this.name,
    required this.materialType,
    required this.xMeters,
    required this.yMeters,
    required this.widthMeters,
    required this.heightMeters,
    required this.attenuationDb,
    this.floor = 0,
  });

  final String id;
  final String name;
  final MaterialType materialType;
  final double xMeters;
  final double yMeters;
  final double widthMeters;
  final double heightMeters;
  final double attenuationDb;
  final int floor;

  double get right => xMeters + widthMeters;
  double get bottom => yMeters + heightMeters;
  double get centerX => xMeters + (widthMeters / 2);
  double get centerY => yMeters + (heightMeters / 2);

  bool contains(double x, double y) {
    return x >= xMeters && x <= right && y >= yMeters && y <= bottom;
  }

  bool intersectsLine({
    required double x1,
    required double y1,
    required double x2,
    required double y2,
  }) {
    if (contains(x1, y1) || contains(x2, y2)) {
      return true;
    }

    return _segmentsIntersect(
          x1,
          y1,
          x2,
          y2,
          xMeters,
          yMeters,
          right,
          yMeters,
        ) ||
        _segmentsIntersect(x1, y1, x2, y2, right, yMeters, right, bottom) ||
        _segmentsIntersect(x1, y1, x2, y2, right, bottom, xMeters, bottom) ||
        _segmentsIntersect(x1, y1, x2, y2, xMeters, bottom, xMeters, yMeters);
  }

  MaterialObstacle copyWith({
    String? id,
    String? name,
    MaterialType? materialType,
    double? xMeters,
    double? yMeters,
    double? widthMeters,
    double? heightMeters,
    double? attenuationDb,
    int? floor,
  }) {
    return MaterialObstacle(
      id: id ?? this.id,
      name: name ?? this.name,
      materialType: materialType ?? this.materialType,
      xMeters: xMeters ?? this.xMeters,
      yMeters: yMeters ?? this.yMeters,
      widthMeters: widthMeters ?? this.widthMeters,
      heightMeters: heightMeters ?? this.heightMeters,
      attenuationDb: attenuationDb ?? this.attenuationDb,
      floor: floor ?? this.floor,
    );
  }
}

bool _segmentsIntersect(
  double ax,
  double ay,
  double bx,
  double by,
  double cx,
  double cy,
  double dx,
  double dy,
) {
  final denominator = ((bx - ax) * (dy - cy)) - ((by - ay) * (dx - cx));
  if (denominator == 0) {
    return false;
  }

  final r = (((ay - cy) * (dx - cx)) - ((ax - cx) * (dy - cy))) / denominator;
  final s = (((ay - cy) * (bx - ax)) - ((ax - cx) * (by - ay))) / denominator;
  return r >= 0 && r <= 1 && s >= 0 && s <= 1;
}
