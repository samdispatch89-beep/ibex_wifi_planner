import 'dart:typed_data';

enum FloorPlanSourceType { none, image, pdf }

class FloorPlan {
  const FloorPlan({
    required this.id,
    required this.name,
    required this.widthMeters,
    required this.heightMeters,
    required this.imagePixelWidth,
    required this.imagePixelHeight,
    required this.metersPerPixel,
    this.floorCount = 1,
    this.currentFloor = 0,
    this.floorAttenuationDb = 18,
    this.temperatureLossDb = 1.5,
    this.imageBytes,
    this.sourceName,
    this.sourceType = FloorPlanSourceType.none,
  });

  final String id;
  final String name;
  final double widthMeters;
  final double heightMeters;
  final int imagePixelWidth;
  final int imagePixelHeight;
  final double metersPerPixel;
  final int floorCount;
  final int currentFloor;
  final double floorAttenuationDb;
  final double temperatureLossDb;
  final Uint8List? imageBytes;
  final String? sourceName;
  final FloorPlanSourceType sourceType;

  bool get hasRenderableBackground =>
      imageBytes != null && sourceType == FloorPlanSourceType.image;

  bool get isCalibrated => metersPerPixel > 0;

  double get aspectRatio => imagePixelWidth <= 0 || imagePixelHeight <= 0
      ? 1
      : imagePixelWidth / imagePixelHeight;

  double get derivedWidthMeters => imagePixelWidth * metersPerPixel;
  double get derivedHeightMeters => imagePixelHeight * metersPerPixel;

  double clampX(double value) => value.clamp(0.0, widthMeters).toDouble();

  double clampY(double value) => value.clamp(0.0, heightMeters).toDouble();

  FloorPlan copyWith({
    String? id,
    String? name,
    double? widthMeters,
    double? heightMeters,
    int? imagePixelWidth,
    int? imagePixelHeight,
    double? metersPerPixel,
    int? floorCount,
    int? currentFloor,
    double? floorAttenuationDb,
    double? temperatureLossDb,
    Uint8List? imageBytes,
    bool clearImageBytes = false,
    String? sourceName,
    FloorPlanSourceType? sourceType,
  }) {
    return FloorPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      widthMeters: widthMeters ?? this.widthMeters,
      heightMeters: heightMeters ?? this.heightMeters,
      imagePixelWidth: imagePixelWidth ?? this.imagePixelWidth,
      imagePixelHeight: imagePixelHeight ?? this.imagePixelHeight,
      metersPerPixel: metersPerPixel ?? this.metersPerPixel,
      floorCount: floorCount ?? this.floorCount,
      currentFloor: currentFloor ?? this.currentFloor,
      floorAttenuationDb: floorAttenuationDb ?? this.floorAttenuationDb,
      temperatureLossDb: temperatureLossDb ?? this.temperatureLossDb,
      imageBytes: clearImageBytes ? null : (imageBytes ?? this.imageBytes),
      sourceName: sourceName ?? this.sourceName,
      sourceType: sourceType ?? this.sourceType,
    );
  }
}
