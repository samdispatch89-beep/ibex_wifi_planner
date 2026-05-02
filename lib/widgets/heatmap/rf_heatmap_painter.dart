import 'package:flutter/material.dart';

import '../../models/access_point.dart';
import '../../models/floor_plan.dart';
import '../../models/material_obstacle.dart' as obstacle_model;
import '../../models/rf_result.dart';
import '../../models/user_density.dart';
import '../../services/rf/heatmap_engine.dart';

class RfHeatmapPainter extends CustomPainter {
  RfHeatmapPainter({
    required this.floorPlan,
    required this.cells,
    required this.accessPoints,
    required this.obstacles,
    required this.densityZones,
    required this.heatmapType,
    required this.selectedPoint,
    required this.heatmapEngine,
  });

  final FloorPlan floorPlan;
  final List<HeatmapCell> cells;
  final List<RfAccessPoint> accessPoints;
  final List<obstacle_model.MaterialObstacle> obstacles;
  final List<UserDensityZone> densityZones;
  final HeatmapType heatmapType;
  final PointMetrics? selectedPoint;
  final HeatmapEngine heatmapEngine;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF6FAF5);
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      paint,
    );

    _paintGrid(canvas, size);
    _paintHeatmap(canvas, size);
    _paintDensityZones(canvas, size);
    _paintObstacles(canvas, size);
    _paintAccessPoints(canvas, size);
    _paintSelection(canvas, size);
  }

  void _paintGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x1A0B6E4F)
      ..strokeWidth = 1;
    for (var column = 1; column < 12; column++) {
      final x = size.width * (column / 12);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var row = 1; row < 8; row++) {
      final y = size.height * (row / 8);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _paintHeatmap(Canvas canvas, Size size) {
    if (cells.isEmpty) {
      return;
    }

    final columns =
        cells.map((cell) => cell.column).fold<int>(0, (a, b) => a > b ? a : b) +
        1;
    final rows =
        cells.map((cell) => cell.row).fold<int>(0, (a, b) => a > b ? a : b) + 1;
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    for (final cell in cells) {
      final normalized = heatmapEngine.normalize(
        heatmapType,
        heatmapEngine.valueForCell(cell, heatmapType),
      );
      final color = Color.lerp(
        const Color(0xFF154236),
        const Color(0xFFB7F0C1),
        normalized,
      )!.withValues(alpha: 0.18 + (normalized * 0.72));
      canvas.drawRect(
        Rect.fromLTWH(
          cell.column * cellWidth,
          cell.row * cellHeight,
          cellWidth + 0.6,
          cellHeight + 0.6,
        ),
        Paint()..color = color,
      );
    }
  }

  void _paintDensityZones(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF0B6E4F).withValues(alpha: 0.35);
    for (final zone in densityZones) {
      final rect = Rect.fromLTWH(
        (zone.xMeters / floorPlan.widthMeters) * size.width,
        (zone.yMeters / floorPlan.heightMeters) * size.height,
        (zone.widthMeters / floorPlan.widthMeters) * size.width,
        (zone.heightMeters / floorPlan.heightMeters) * size.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        paint,
      );
    }
  }

  void _paintObstacles(Canvas canvas, Size size) {
    for (final obstacle in obstacles) {
      final rect = Rect.fromLTWH(
        (obstacle.xMeters / floorPlan.widthMeters) * size.width,
        (obstacle.yMeters / floorPlan.heightMeters) * size.height,
        (obstacle.widthMeters / floorPlan.widthMeters) * size.width,
        (obstacle.heightMeters / floorPlan.heightMeters) * size.height,
      );
      final color = switch (obstacle.materialType) {
        obstacle_model.MaterialType.drywall => const Color(0xFFAAD4A9),
        obstacle_model.MaterialType.glass => const Color(0xFF8CC9FF),
        obstacle_model.MaterialType.brick => const Color(0xFFC88864),
        obstacle_model.MaterialType.concrete => const Color(0xFFB4BEC7),
        obstacle_model.MaterialType.metalRack => const Color(0xFF85756A),
        obstacle_model.MaterialType.humanCluster => const Color(0xFFE6B877),
      };
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = color.withValues(alpha: 0.92),
      );
    }
  }

  void _paintAccessPoints(Canvas canvas, Size size) {
    for (final accessPoint in accessPoints) {
      final center = Offset(
        (accessPoint.xMeters / floorPlan.widthMeters) * size.width,
        (accessPoint.yMeters / floorPlan.heightMeters) * size.height,
      );
      canvas.drawCircle(center, 10, Paint()..color = const Color(0xFF10352A));
      canvas.drawCircle(
        center,
        24,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF10352A).withValues(alpha: 0.28),
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: accessPoint.channel.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - (textPainter.width / 2),
          center.dy - (textPainter.height / 2),
        ),
      );
    }
  }

  void _paintSelection(Canvas canvas, Size size) {
    if (selectedPoint == null) {
      return;
    }
    final center = Offset(
      (selectedPoint!.xMeters / floorPlan.widthMeters) * size.width,
      (selectedPoint!.yMeters / floorPlan.heightMeters) * size.height,
    );
    canvas.drawCircle(
      center,
      8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFE7FFF0),
    );
    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFF0B6E4F));
  }

  @override
  bool shouldRepaint(covariant RfHeatmapPainter oldDelegate) {
    return oldDelegate.cells != cells ||
        oldDelegate.accessPoints != accessPoints ||
        oldDelegate.obstacles != obstacles ||
        oldDelegate.selectedPoint != selectedPoint ||
        oldDelegate.heatmapType != heatmapType;
  }
}
