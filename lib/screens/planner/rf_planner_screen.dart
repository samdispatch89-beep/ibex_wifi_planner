import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/rf_planner_controller.dart';
import '../../models/access_point.dart';
import '../../models/floor_plan.dart';
import '../../models/material_obstacle.dart' as obstacle_model;
import '../../models/rf_result.dart';
import '../../models/world_point.dart';
import '../../services/coordinate_transformer.dart';
import '../../services/rf/heatmap_engine.dart';
import '../../views/animated_ui.dart';
import '../../views/responsive_breakpoints.dart';
import '../../widgets/floorplan/floorplan_viewer.dart';
import '../../widgets/heatmap/heatmap_legend.dart';

class RfPlannerScreen extends StatelessWidget {
  const RfPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RfPlannerController>(
      builder: (context, controller, child) {
        final spacing = ResponsiveBreakpoints.sectionSpacing(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PlannerToolbar(controller: controller),
            SizedBox(height: spacing),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 1180;
                final viewer = _FloorPlanWorkspace(controller: controller);
                final sidePanel = _DebugSidePanel(controller: controller);

                if (stacked) {
                  return Column(
                    children: [
                      SizedBox(
                        height: ResponsiveBreakpoints.isMobile(context)
                            ? 420
                            : 520,
                        child: viewer,
                      ),
                      SizedBox(height: spacing),
                      sidePanel,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: SizedBox(height: 720, child: viewer),
                    ),
                    SizedBox(width: spacing),
                    SizedBox(width: 360, child: sidePanel),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _PlannerToolbar extends StatelessWidget {
  const _PlannerToolbar({required this.controller});

  final RfPlannerController controller;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveBreakpoints.panelPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: controller.isUploadingFloorPlan
                        ? null
                        : controller.uploadFloorPlan,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(
                      controller.isUploadingFloorPlan
                          ? 'Loading...'
                          : 'Upload floor plan',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.fitFloorPlanToViewport,
                    icon: const Icon(Icons.fit_screen_rounded),
                    label: const Text('Fit to viewport'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.undoLastWall,
                    icon: const Icon(Icons.undo_rounded),
                    label: const Text('Undo wall'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.removeLastAccessPoint,
                    icon: const Icon(Icons.router_outlined),
                    label: const Text('Undo AP'),
                  ),
                  FilledButton.icon(
                    onPressed: controller.isSimulating
                        ? null
                        : controller.runSimulation,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Run Simulation'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: controller.isSimulating
                        ? null
                        : controller.autoPlan,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Auto Plan'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: controller.isSimulating
                        ? null
                        : controller.optimize,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Optimize'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: controller.isSimulating
                        ? null
                        : controller.runValidationSuite,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Run validation'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _LabeledDropdown<FrequencyBand>(
                    label: 'Band',
                    value: controller.settings.selectedBand,
                    items: FrequencyBand.values,
                    itemLabel: (item) => item.label,
                    onChanged: controller.updateBand,
                  ),
                  _LabeledDropdown<EnvironmentPreset>(
                    label: 'Environment',
                    value: controller.settings.environmentPreset,
                    items: EnvironmentPreset.values,
                    itemLabel: (item) => item.name,
                    onChanged: controller.updateEnvironment,
                  ),
                  _LabeledDropdown<HeatmapType>(
                    label: 'Heatmap',
                    value: controller.heatmapType,
                    items: HeatmapType.values,
                    itemLabel: (item) => item.name.toUpperCase(),
                    onChanged: controller.updateHeatmapType,
                  ),
                  _LabeledDropdown<PlannerInteractionMode>(
                    label: 'Mode',
                    value: controller.interactionMode,
                    items: PlannerInteractionMode.values,
                    itemLabel: (item) => switch (item) {
                      PlannerInteractionMode.inspect => 'Inspect',
                      PlannerInteractionMode.placeAp => 'Place AP',
                      PlannerInteractionMode.calibrate => 'Calibrate',
                      PlannerInteractionMode.drawWall => 'Draw wall',
                      PlannerInteractionMode.deleteWall => 'Delete wall',
                    },
                    onChanged: controller.updateInteractionMode,
                  ),
                  _LabeledDropdown<obstacle_model.MaterialType>(
                    label: 'Wall material',
                    value: controller.selectedMaterialType,
                    items: obstacle_model.MaterialType.values,
                    itemLabel: (item) => item.label,
                    onChanged: controller.updateSelectedMaterialType,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 18,
                runSpacing: 12,
                children: [
                  _SliderField(
                    label: 'Noise floor',
                    valueLabel:
                        '${controller.settings.noiseFloorDbm.toStringAsFixed(0)} dBm',
                    value: controller.settings.noiseFloorDbm,
                    min: -100,
                    max: -80,
                    onChanged: controller.updateNoiseFloor,
                  ),
                  _SliderField(
                    label: 'AP TX power',
                    valueLabel:
                        '${controller.draftTxPowerDbm.toStringAsFixed(0)} dBm',
                    value: controller.draftTxPowerDbm,
                    min: 8,
                    max: 23,
                    onChanged: controller.updateDraftTxPower,
                  ),
                  _SliderField(
                    label: 'Grid density',
                    valueLabel: '${controller.settings.gridColumns} columns',
                    value: controller.settings.gridColumns.toDouble(),
                    min: 18,
                    max: 72,
                    onChanged: (value) =>
                        controller.updateGridDensity(value.round()),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final channel
                      in controller.settings.selectedBand.recommendedChannels)
                    ChoiceChip(
                      label: Text('Ch $channel'),
                      selected: controller.draftChannel == channel,
                      onSelected: (_) => controller.updateDraftChannel(channel),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _CalibrationPanel(controller: controller),
              const SizedBox(height: 14),
              Text(
                controller.statusMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 9,
                  value: controller.isSimulating
                      ? controller.simulationProgress
                      : (controller.simulationResult.cells.isEmpty ? 0 : 1),
                  backgroundColor: const Color(0xFFE4ECE4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalibrationPanel extends StatelessWidget {
  const _CalibrationPanel({required this.controller});

  final RfPlannerController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE5D8)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Calibration',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(
            width: 180,
            child: TextFormField(
              initialValue: controller.calibrationDistanceMeters,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Distance (meters)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                isDense: true,
              ),
              onChanged: controller.updateCalibrationDistance,
            ),
          ),
          FilledButton.tonal(
            onPressed: controller.canApplyCalibration
                ? controller.applyCalibration
                : null,
            child: const Text('Apply calibration'),
          ),
          OutlinedButton(
            onPressed: controller.clearCalibrationSelection,
            child: const Text('Clear points'),
          ),
          Text(
            'Point A: ${controller.calibrationPointA == null ? 'unset' : 'set'}  •  Point B: ${controller.calibrationPointB == null ? 'unset' : 'set'}',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _FloorPlanWorkspace extends StatelessWidget {
  const _FloorPlanWorkspace({required this.controller});

  final RfPlannerController controller;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;

    return FadeSlideIn(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveBreakpoints.panelPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calibrated floor plan viewer',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Screen coordinates remain pixels. APs, walls, and RF sampling stay in world meters only.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FloorPlanViewer(
                  floorPlan: controller.floorPlan,
                  transformationController: controller.transformationController,
                  cells: controller.simulationResult.cells,
                  heatmapType: controller.heatmapType,
                  selectedPoint: controller.selectedPointMetrics,
                  walls: controller.walls,
                  pendingWallStart: controller.pendingWallStart,
                  pointerPreviewWorld: controller.hoverWorldPoint,
                  calibrationPointA: controller.calibrationPointA,
                  calibrationPointB: controller.calibrationPointB,
                  onViewerSized: controller.updateViewerSize,
                  onTap: (offset) {
                    controller.handleViewerTap(screenPosition: offset);
                  },
                  onHover: controller.updateHoverScreenPosition,
                  accessPointLayer: _AccessPointSceneOverlay(
                    controller: controller,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              HeatmapLegend(
                type: controller.heatmapType,
                heatmapEngine: const _LegendAdapter(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessPointSceneOverlay extends StatelessWidget {
  const _AccessPointSceneOverlay({required this.controller});

  final RfPlannerController controller;

  @override
  Widget build(BuildContext context) {
    final transformer = const CoordinateTransformer();
    return IgnorePointer(
      child: CustomPaint(
        painter: _AccessPointScenePainter(
          floorPlan: controller.floorPlan,
          accessPoints: controller.accessPoints,
          transformer: transformer,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AccessPointScenePainter extends CustomPainter {
  _AccessPointScenePainter({
    required this.floorPlan,
    required this.accessPoints,
    required this.transformer,
  });

  final FloorPlan floorPlan;
  final List<RfAccessPoint> accessPoints;
  final CoordinateTransformer transformer;

  @override
  void paint(Canvas canvas, Size size) {
    for (final accessPoint in accessPoints) {
      final center = transformer.worldToImagePixel(
        WorldPoint(xMeters: accessPoint.xMeters, yMeters: accessPoint.yMeters),
        floorPlan,
      );
      canvas.drawCircle(center, 10, Paint()..color = const Color(0xFF10352A));
      canvas.drawCircle(
        center,
        28,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF10352A).withValues(alpha: 0.25),
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: accessPoint.channel.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 8,
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

  @override
  bool shouldRepaint(covariant _AccessPointScenePainter oldDelegate) {
    return oldDelegate.accessPoints != accessPoints ||
        oldDelegate.floorPlan != floorPlan;
  }
}

class _DebugSidePanel extends StatelessWidget {
  const _DebugSidePanel({required this.controller});

  final RfPlannerController controller;

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedPointMetrics;
    final summary = controller.simulationResult.summary;

    return Column(
      children: [
        _MetricPanel(
          title: 'Selected point',
          child: selected == null
              ? const Text(
                  'Tap the viewer to inspect world coordinates and RF metrics.',
                )
              : Column(
                  children: [
                    _MetricRow(
                      label: 'World X',
                      value: '${selected.xMeters.toStringAsFixed(2)} m',
                    ),
                    _MetricRow(
                      label: 'World Y',
                      value: '${selected.yMeters.toStringAsFixed(2)} m',
                    ),
                    _MetricRow(
                      label: 'Best AP',
                      value: selected.bestServingApId ?? 'None',
                    ),
                    _MetricRow(
                      label: 'RSSI',
                      value: '${selected.rssiDbm.toStringAsFixed(1)} dBm',
                    ),
                    _MetricRow(
                      label: 'SNR',
                      value: '${selected.snrDb.toStringAsFixed(1)} dB',
                    ),
                    _MetricRow(
                      label: 'SINR',
                      value: '${selected.sinrDb.toStringAsFixed(1)} dB',
                    ),
                    _MetricRow(
                      label: 'Interference',
                      value:
                          '${selected.interferenceDb.toStringAsFixed(1)} dBm',
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _MetricPanel(
          title: 'Plan summary',
          child: Column(
            children: [
              _MetricRow(
                label: 'Floor size',
                value:
                    '${controller.floorPlan.widthMeters.toStringAsFixed(1)}m × ${controller.floorPlan.heightMeters.toStringAsFixed(1)}m',
              ),
              _MetricRow(
                label: 'Meters/pixel',
                value: controller.floorPlan.metersPerPixel.toStringAsFixed(5),
              ),
              _MetricRow(
                label: 'Coverage @ -65',
                value: '${summary.coverageAtMinus65.toStringAsFixed(1)}%',
              ),
              _MetricRow(
                label: 'Average throughput',
                value:
                    '${summary.averageThroughputMbps.toStringAsFixed(0)} Mbps',
              ),
              _MetricRow(label: 'Walls', value: '${controller.walls.length}'),
              _MetricRow(
                label: 'Access points',
                value: '${controller.accessPoints.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _MetricPanel(
          title: 'Optimizer recommendations',
          child: controller.recommendations.isEmpty
              ? const Text(
                  'Run Optimize after a simulation to generate actions.',
                )
              : Column(
                  children: [
                    for (final recommendation in controller.recommendations)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FBF6),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFDCE7DC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recommendation.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                recommendation.description,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                recommendation.impactSummary,
                                style: const TextStyle(
                                  color: Color(0xFF0B6E4F),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              FilledButton.tonal(
                                onPressed: controller.isSimulating
                                    ? null
                                    : () => controller.applyRecommendation(
                                        recommendation,
                                      ),
                                child: const Text('Apply Recommendation'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _MetricPanel(
          title: 'Validation scenarios',
          child: controller.validationResults.isEmpty
              ? const Text(
                  'Run the validation suite to verify propagation behavior.',
                )
              : Column(
                  children: [
                    for (final result in controller.validationResults)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              result.passed
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              color: result.passed
                                  ? const Color(0xFF2D9E67)
                                  : const Color(0xFFD94841),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    result.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    result.details,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveBreakpoints.panelPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                valueLabel,
                style: const TextStyle(
                  color: Color(0xFF0B6E4F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ResponsiveBreakpoints.isMobile(context) ? 152 : 180,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          isDense: true,
        ),
        items: [
          for (final item in items)
            DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (selected) {
          if (selected != null) {
            onChanged(selected);
          }
        },
      ),
    );
  }
}

class _LegendAdapter extends HeatmapEngine {
  const _LegendAdapter();
}
