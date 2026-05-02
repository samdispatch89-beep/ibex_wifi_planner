import 'package:flutter/material.dart';

import '../../models/rf_result.dart';
import '../../services/rf/heatmap_engine.dart';

class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({
    super.key,
    required this.type,
    required this.heatmapEngine,
  });

  final HeatmapType type;
  final HeatmapEngine heatmapEngine;

  @override
  Widget build(BuildContext context) {
    final range = heatmapEngine.rangeFor(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          range.label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [Color(0xFF154236), Color(0xFF4FBF7A), Color(0xFFB7F0C1)],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(range.min.toStringAsFixed(0)),
            const Spacer(),
            Text(range.max.toStringAsFixed(0)),
          ],
        ),
      ],
    );
  }
}
