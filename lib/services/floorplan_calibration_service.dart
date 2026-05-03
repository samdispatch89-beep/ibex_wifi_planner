import 'dart:ui';

class FloorplanCalibrationService {
  const FloorplanCalibrationService();

  double metersPerPixel({
    required Offset pointA,
    required Offset pointB,
    required double realDistanceMeters,
  }) {
    final pixelDistance = (pointA - pointB).distance;
    if (pixelDistance <= 0 || realDistanceMeters <= 0) {
      return 0;
    }
    return realDistanceMeters / pixelDistance;
  }

  double calibratedDistanceMeters({
    required Offset pointA,
    required Offset pointB,
    required double metersPerPixel,
  }) {
    return (pointA - pointB).distance * metersPerPixel;
  }
}
