import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/rf_planner_controller.dart';
import '../../models/access_point.dart';
import '../../models/material_obstacle.dart' as obstacle_model;
import '../../models/rf_result.dart';
import '../../services/rf/heatmap_engine.dart';
import '../../views/animated_ui.dart';
import '../../views/responsive_breakpoints.dart';
import '../../widgets/heatmap/heatmap_legend.dart';
import '../../widgets/heatmap/rf_heatmap_painter.dart';

class RfPlannerScreen extends StatelessWidget {
  const RfPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RfPlannerController>(
      builder: (context, controller, child) {
        final spacing = ResponsiveBreakpoints.sectionSpacing(context);
        return LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 1180;
            final plannerHeight = stacked
                ? (ResponsiveBreakpoints.isMobile(context) ? 360.0 : 460.0)
                : (constraints.maxHeight > 0
                      ? constraints.maxHeight.clamp(520.0, 760.0).toDouble()
                      : 620.0);
            final planner = SizedBox(
              height: plannerHeight,
              child: _PlannerCanvas(controller: controller),
            );
            final sidePanel = _SidePanel(controller: controller);

            return Column(
              children: [
                _ControlPanel(controller: controller),
                SizedBox(height: spacing),
                if (stacked) ...[
                  planner,
                  SizedBox(height: spacing),
                  sidePanel,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: planner),
                      SizedBox(width: spacing),
                      SizedBox(width: 360, child: sidePanel),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({required this.controller});

  final RfPlannerController controller;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

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
                crossAxisAlignment: WrapCrossAlignment.center,
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
                    itemLabel: (item) => item.name,
                    onChanged: controller.updateHeatmapType,
                  ),
                  _LabeledDropdown<PlannerInteractionMode>(
                    label: 'Tool',
                    value: controller.interactionMode,
                    items: PlannerInteractionMode.values,
                    itemLabel: (item) => switch (item) {
                      PlannerInteractionMode.inspect => 'Inspect',
                      PlannerInteractionMode.placeAp => 'Place AP',
                      PlannerInteractionMode.placeObstacle => 'Place obstacle',
                    },
                    onChanged: controller.updateInteractionMode,
                  ),
                  _LabeledDropdown<obstacle_model.MaterialType>(
                    label: 'Material',
                    value: controller.selectedMaterialType,
                    items: obstacle_model.MaterialType.values,
                    itemLabel: (item) => item.label,
                    onChanged: controller.updateSelectedMaterialType,
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                    valueLabel: '${controller.settings.gridColumns} cols',
                    value: controller.settings.gridColumns.toDouble(),
                    min: 18,
                    max: 60,
                    onChanged: (value) =>
                        controller.updateGridDensity(value.round()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
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
                  OutlinedButton.icon(
                    onPressed: controller.removeLastAccessPoint,
                    icon: const Icon(Icons.router_outlined),
                    label: const Text('Undo AP'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.removeLastObstacle,
                    icon: const Icon(Icons.layers_clear_outlined),
                    label: const Text('Undo Obstacle'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedOpacity(
                opacity: controller.isSimulating ? 1 : 0.85,
                duration: const Duration(milliseconds: 220),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        minHeight: isMobile ? 8 : 10,
                        value: controller.isSimulating
                            ? controller.simulationProgress
                            : (controller.simulationResult.cells.isEmpty
                                  ? 0
                                  : 1),
                        backgroundColor: const Color(0xFFE5EFE5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlannerCanvas extends StatelessWidget {
  const _PlannerCanvas({required this.controller});

  final RfPlannerController controller;

  @override
  Widget build(BuildContext context) {
    final heatmapEngine = const HeatmapEngine();

    return FadeSlideIn(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveBreakpoints.panelPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RF simulation canvas',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap to inspect, place APs, or add material obstacles. Heatmaps render on the current simulation grid.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapUp: (details) {
                        final box = context.findRenderObject() as RenderBox?;
                        if (box == null ||
                            box.size.width <= 0 ||
                            box.size.height <= 0) {
                          return;
                        }
                        final local = details.localPosition;
                        controller.handleCanvasTap(
                          normalizedX: (local.dx / box.size.width).clamp(
                            0.0,
                            1.0,
                          ),
                          normalizedY: (local.dy / box.size.height).clamp(
                            0.0,
                            1.0,
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CustomPaint(
                          painter: RfHeatmapPainter(
                            floorPlan: controller.floorPlan,
                            cells: controller.simulationResult.cells,
                            accessPoints: controller.accessPoints,
                            obstacles: controller.obstacles,
                            densityZones: controller.densityZones,
                            heatmapType: controller.heatmapType,
                            selectedPoint: controller.selectedPointMetrics,
                            heatmapEngine: heatmapEngine,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              HeatmapLegend(
                type: controller.heatmapType,
                heatmapEngine: heatmapEngine,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.controller});

  final RfPlannerController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.simulationResult.summary;
    final selected = controller.selectedPointMetrics;

    return Column(
      children: [
        _MetricPanel(
          title: 'Simulation summary',
          child: Column(
            children: [
              _MetricRow(
                label: 'Coverage @ -65',
                value: '${summary.coverageAtMinus65.toStringAsFixed(1)}%',
              ),
              _MetricRow(
                label: 'Avg SNR',
                value: '${summary.averageSnr.toStringAsFixed(1)} dB',
              ),
              _MetricRow(
                label: 'Avg SINR',
                value: '${summary.averageSinr.toStringAsFixed(1)} dB',
              ),
              _MetricRow(
                label: 'Avg throughput',
                value:
                    '${summary.averageThroughputMbps.toStringAsFixed(0)} Mbps',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _MetricPanel(
          title: 'Selected point',
          child: selected == null
              ? const Text(
                  'Tap the floor plan to inspect point-level RF metrics.',
                )
              : Column(
                  children: [
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
                      label: 'Throughput',
                      value:
                          '${selected.throughputMbps.toStringAsFixed(0)} Mbps',
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
                        child: HoverLift(
                          borderRadius: 18,
                          enableHover: !ResponsiveBreakpoints.isMobile(context),
                          hoverOffset: -2,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6FBF5),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFDCE6DC),
                              ),
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
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FilledButton.tonal(
                                    onPressed: controller.isSimulating
                                        ? null
                                        : () => controller.applyRecommendation(
                                            recommendation,
                                          ),
                                    child: const Text('Apply Recommendation'),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
          const SizedBox(width: 12),
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
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B6E4F),
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
    final compact = ResponsiveBreakpoints.isMobile(context);

    return SizedBox(
      width: compact ? 132 : 180,
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
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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
