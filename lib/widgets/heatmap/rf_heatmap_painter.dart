import 'package:flutter/material.dart';

import '../../models/floor_plan.dart';
import '../../models/rf_result.dart';
import '../../services/coordinate_transformer.dart';
import '../../services/heatmap_color_service.dart';

class RfHeatmapPainter extends CustomPainter {
  RfHeatmapPainter({
    required this.floorPlan,
    required this.cells,
    required this.heatmapType,
    required this.selectedPoint,
    required this.colorService,
  });

  final FloorPlan floorPlan;
  final List<HeatmapCell> cells;
  final HeatmapType heatmapType;
  final PointMetrics? selectedPoint;
  final HeatmapColorService colorService;
  final CoordinateTransformer _transformer = const CoordinateTransformer();

  @override
  void paint(Canvas canvas, Size size) {
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
      final value = switch (heatmapType) {
        HeatmapType.rssi => cell.metrics.rssiDbm,
        HeatmapType.snr => cell.metrics.snrDb,
        HeatmapType.sinr => cell.metrics.sinrDb,
        HeatmapType.throughput => cell.metrics.throughputMbps,
        HeatmapType.interference => cell.metrics.interferenceDb,
      };
      final color = colorService
          .colorFor(type: heatmapType, value: value)
          .withValues(alpha: 0.48);
      canvas.drawRect(
        Rect.fromLTWH(
          cell.column * cellWidth,
          cell.row * cellHeight,
          cellWidth + 0.8,
          cellHeight + 0.8,
        ),
        Paint()..color = color,
      );
    }

    if (selectedPoint != null) {
      final center = _transformer.worldToImagePixel(
        selectedPoint!.worldPoint,
        floorPlan,
      );
      canvas.drawCircle(
        center,
        10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFE7FFF0),
      );
      canvas.drawCircle(center, 3, Paint()..color = const Color(0xFF0B6E4F));
    }
  }

  @override
  bool shouldRepaint(covariant RfHeatmapPainter oldDelegate) {
    return oldDelegate.cells != cells ||
        oldDelegate.heatmapType != heatmapType ||
        oldDelegate.selectedPoint != selectedPoint ||
        oldDelegate.floorPlan != floorPlan;
  }
}
