import 'package:flutter/material.dart';

import '../models/floor_plan.dart';
import '../models/world_point.dart';

class CoordinateTransformer {
  const CoordinateTransformer();

  WorldPoint screenToWorld({
    required Offset screenPoint,
    required Matrix4 transform,
    required FloorPlan floorPlan,
  }) {
    final imagePoint = screenToImagePixel(
      screenPoint: screenPoint,
      transform: transform,
    );
    return imagePixelToWorld(imagePoint, floorPlan);
  }

  Offset worldToScreen({
    required WorldPoint worldPoint,
    required Matrix4 transform,
    required FloorPlan floorPlan,
  }) {
    final imagePoint = worldToImagePixel(worldPoint, floorPlan);
    return imagePixelToScreen(imagePoint: imagePoint, transform: transform);
  }

  WorldPoint imagePixelToWorld(Offset imagePoint, FloorPlan floorPlan) {
    return WorldPoint(
      xMeters: imagePoint.dx * floorPlan.metersPerPixel,
      yMeters: imagePoint.dy * floorPlan.metersPerPixel,
    );
  }

  Offset worldToImagePixel(WorldPoint worldPoint, FloorPlan floorPlan) {
    final safeMetersPerPixel = floorPlan.metersPerPixel <= 0
        ? 0.03
        : floorPlan.metersPerPixel;
    return Offset(
      worldPoint.xMeters / safeMetersPerPixel,
      worldPoint.yMeters / safeMetersPerPixel,
    );
  }

  Offset screenToImagePixel({
    required Offset screenPoint,
    required Matrix4 transform,
  }) {
    final inverted = Matrix4.inverted(transform);
    return MatrixUtils.transformPoint(inverted, screenPoint);
  }

  Offset imagePixelToScreen({
    required Offset imagePoint,
    required Matrix4 transform,
  }) {
    return MatrixUtils.transformPoint(transform, imagePoint);
  }

  Matrix4 initialFitTransform({
    required Size viewportSize,
    required FloorPlan floorPlan,
    double padding = 24,
  }) {
    final safeWidth = floorPlan.imagePixelWidth <= 0
        ? 1600.0
        : floorPlan.imagePixelWidth.toDouble();
    final safeHeight = floorPlan.imagePixelHeight <= 0
        ? 1000.0
        : floorPlan.imagePixelHeight.toDouble();
    final paddedWidth = (viewportSize.width - padding * 2).clamp(
      120.0,
      double.infinity,
    );
    final paddedHeight = (viewportSize.height - padding * 2).clamp(
      120.0,
      double.infinity,
    );
    final scale = (paddedWidth / safeWidth < paddedHeight / safeHeight)
        ? paddedWidth / safeWidth
        : paddedHeight / safeHeight;
    final fittedWidth = safeWidth * scale;
    final fittedHeight = safeHeight * scale;
    final dx = (viewportSize.width - fittedWidth) / 2;
    final dy = (viewportSize.height - fittedHeight) / 2;

    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }
}
