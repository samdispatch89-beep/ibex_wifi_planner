import 'package:flutter/material.dart';

import '../../models/floor_plan.dart';
import '../../models/wall_segment.dart';
import '../../models/world_point.dart';
import '../../services/coordinate_transformer.dart';

class WallDrawingLayer extends StatelessWidget {
  const WallDrawingLayer({
    super.key,
    required this.floorPlan,
    required this.walls,
    required this.pendingWallStart,
    required this.calibrationPointA,
    required this.calibrationPointB,
    this.pointerPreviewWorld,
  });

  final FloorPlan floorPlan;
  final List<WallSegment> walls;
  final WorldPoint? pendingWallStart;
  final Offset? calibrationPointA;
  final Offset? calibrationPointB;
  final WorldPoint? pointerPreviewWorld;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _WallDrawingPainter(
          floorPlan: floorPlan,
          walls: walls,
          pendingWallStart: pendingWallStart,
          calibrationPointA: calibrationPointA,
          calibrationPointB: calibrationPointB,
          pointerPreviewWorld: pointerPreviewWorld,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WallDrawingPainter extends CustomPainter {
  _WallDrawingPainter({
    required this.floorPlan,
    required this.walls,
    required this.pendingWallStart,
    required this.calibrationPointA,
    required this.calibrationPointB,
    required this.pointerPreviewWorld,
  });

  final FloorPlan floorPlan;
  final List<WallSegment> walls;
  final WorldPoint? pendingWallStart;
  final Offset? calibrationPointA;
  final Offset? calibrationPointB;
  final WorldPoint? pointerPreviewWorld;
  final CoordinateTransformer _transformer = const CoordinateTransformer();

  @override
  void paint(Canvas canvas, Size size) {
    final wallPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..color = const Color(0xFF183B2E);
    final dashedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF2563EB);

    for (final wall in walls) {
      final start = _transformer.worldToImagePixel(wall.start, floorPlan);
      final end = _transformer.worldToImagePixel(wall.end, floorPlan);
      canvas.drawLine(start, end, wallPaint);
      canvas.drawCircle(start, 4, Paint()..color = const Color(0xFF183B2E));
      canvas.drawCircle(end, 4, Paint()..color = const Color(0xFF183B2E));
    }

    if (pendingWallStart != null) {
      final start = _transformer.worldToImagePixel(
        pendingWallStart!,
        floorPlan,
      );
      canvas.drawCircle(start, 6, Paint()..color = const Color(0xFF2563EB));
      if (pointerPreviewWorld != null) {
        final end = _transformer.worldToImagePixel(
          pointerPreviewWorld!,
          floorPlan,
        );
        _drawDashedLine(canvas, start, end, dashedPaint);
      }
    }

    if (calibrationPointA != null) {
      _drawCalibrationPoint(canvas, calibrationPointA!, 'A');
    }
    if (calibrationPointB != null) {
      _drawCalibrationPoint(canvas, calibrationPointB!, 'B');
      if (calibrationPointA != null) {
        _drawDashedLine(
          canvas,
          calibrationPointA!,
          calibrationPointB!,
          dashedPaint,
        );
      }
    }
  }

  void _drawCalibrationPoint(Canvas canvas, Offset point, String label) {
    canvas.drawCircle(point, 8, Paint()..color = const Color(0xFFF7E14F));
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF10352A),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        point.dx - (textPainter.width / 2),
        point.dy - (textPainter.height / 2),
      ),
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 7.0;
    const gap = 5.0;
    final total = (end - start).distance;
    if (total <= 0) {
      return;
    }
    final direction = (end - start) / total;
    var distance = 0.0;
    while (distance < total) {
      final currentStart = start + (direction * distance);
      final currentEnd =
          start + (direction * (distance + dash).clamp(0.0, total));
      canvas.drawLine(currentStart, currentEnd, paint);
      distance += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _WallDrawingPainter oldDelegate) {
    return oldDelegate.walls != walls ||
        oldDelegate.pendingWallStart != pendingWallStart ||
        oldDelegate.pointerPreviewWorld != pointerPreviewWorld ||
        oldDelegate.calibrationPointA != calibrationPointA ||
        oldDelegate.calibrationPointB != calibrationPointB;
  }
}
