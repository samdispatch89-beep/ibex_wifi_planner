import 'package:flutter/material.dart';

import '../../models/floor_plan.dart';
import '../../models/rf_result.dart';
import '../../models/wall_segment.dart';
import '../../models/world_point.dart';
import '../../services/heatmap_color_service.dart';
import '../../widgets/heatmap/rf_heatmap_painter.dart';
import 'wall_drawing_layer.dart';

class FloorPlanViewer extends StatelessWidget {
  const FloorPlanViewer({
    super.key,
    required this.floorPlan,
    required this.transformationController,
    required this.cells,
    required this.heatmapType,
    required this.selectedPoint,
    required this.walls,
    required this.pendingWallStart,
    required this.pointerPreviewWorld,
    required this.calibrationPointA,
    required this.calibrationPointB,
    required this.onViewerSized,
    required this.onTap,
    required this.onHover,
    required this.accessPointLayer,
  });

  final FloorPlan floorPlan;
  final TransformationController transformationController;
  final List<HeatmapCell> cells;
  final HeatmapType heatmapType;
  final PointMetrics? selectedPoint;
  final List<WallSegment> walls;
  final WorldPoint? pendingWallStart;
  final WorldPoint? pointerPreviewWorld;
  final Offset? calibrationPointA;
  final Offset? calibrationPointB;
  final ValueChanged<Size> onViewerSized;
  final ValueChanged<Offset> onTap;
  final ValueChanged<Offset?> onHover;
  final Widget accessPointLayer;

  @override
  Widget build(BuildContext context) {
    final sceneSize = Size(
      floorPlan.imagePixelWidth.toDouble(),
      floorPlan.imagePixelHeight.toDouble(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onViewerSized(size);
        });

        return MouseRegion(
          onHover: (event) => onHover(event.localPosition),
          onExit: (_) => onHover(null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => onTap(details.localPosition),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: const Color(0xFFF5F1EA),
                child: InteractiveViewer(
                  transformationController: transformationController,
                  minScale: 0.2,
                  maxScale: 8,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(240),
                  clipBehavior: Clip.none,
                  child: SizedBox(
                    width: sceneSize.width,
                    height: sceneSize.height,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (floorPlan.hasRenderableBackground)
                          Image.memory(
                            floorPlan.imageBytes!,
                            fit: BoxFit.fill,
                            gaplessPlayback: true,
                          )
                        else
                          _EmptyFloorPlanBackdrop(floorPlan: floorPlan),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: RfHeatmapPainter(
                              floorPlan: floorPlan,
                              cells: cells,
                              heatmapType: heatmapType,
                              selectedPoint: selectedPoint,
                              colorService: const HeatmapColorService(),
                            ),
                          ),
                        ),
                        Positioned.fill(child: accessPointLayer),
                        Positioned.fill(
                          child: WallDrawingLayer(
                            floorPlan: floorPlan,
                            walls: walls,
                            pendingWallStart: pendingWallStart,
                            pointerPreviewWorld: pointerPreviewWorld,
                            calibrationPointA: calibrationPointA,
                            calibrationPointB: calibrationPointB,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyFloorPlanBackdrop extends StatelessWidget {
  const _EmptyFloorPlanBackdrop({required this.floorPlan});

  final FloorPlan floorPlan;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8F5EF), Color(0xFFF1EADF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: _BackdropPainter(),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              floorPlan.sourceType == FloorPlanSourceType.pdf
                  ? 'PDF source uploaded.\nUse a PNG/JPG floor plan image for calibration and overlay rendering.'
                  : 'Upload a PNG/JPG floor plan and calibrate two points to start planning.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5C594F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFDBD1C6)
      ..strokeWidth = 1;
    const step = 80.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
