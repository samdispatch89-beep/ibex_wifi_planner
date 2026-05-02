class FloorPlan {
  const FloorPlan({
    required this.id,
    required this.name,
    required this.widthMeters,
    required this.heightMeters,
    this.floorCount = 1,
    this.currentFloor = 0,
    this.floorAttenuationDb = 18,
    this.temperatureLossDb = 1.5,
  });

  final String id;
  final String name;
  final double widthMeters;
  final double heightMeters;
  final int floorCount;
  final int currentFloor;
  final double floorAttenuationDb;
  final double temperatureLossDb;

  double clampX(double value) => value.clamp(0.0, widthMeters).toDouble();

  double clampY(double value) => value.clamp(0.0, heightMeters).toDouble();

  FloorPlan copyWith({
    String? id,
    String? name,
    double? widthMeters,
    double? heightMeters,
    int? floorCount,
    int? currentFloor,
    double? floorAttenuationDb,
    double? temperatureLossDb,
  }) {
    return FloorPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      widthMeters: widthMeters ?? this.widthMeters,
      heightMeters: heightMeters ?? this.heightMeters,
      floorCount: floorCount ?? this.floorCount,
      currentFloor: currentFloor ?? this.currentFloor,
      floorAttenuationDb: floorAttenuationDb ?? this.floorAttenuationDb,
      temperatureLossDb: temperatureLossDb ?? this.temperatureLossDb,
    );
  }
}
