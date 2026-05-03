import 'package:flutter/material.dart';

import '../models/rf_result.dart';

class HeatmapColorService {
  const HeatmapColorService();

  Color colorFor({required HeatmapType type, required double value}) {
    switch (type) {
      case HeatmapType.rssi:
        return _interpolateStops(value, const [
          _ColorStop(value: -95, color: Color(0xFF8F949B)),
          _ColorStop(value: -85, color: Color(0xFF8F949B)),
          _ColorStop(value: -75, color: Color(0xFFF35D4B)),
          _ColorStop(value: -67, color: Color(0xFF26A269)),
          _ColorStop(value: -60, color: Color(0xFFA8E66B)),
          _ColorStop(value: -50, color: Color(0xFFF7E14F)),
          _ColorStop(value: -30, color: Color(0xFFF7E14F)),
        ]);
      case HeatmapType.snr:
      case HeatmapType.sinr:
        return _interpolateStops(value, const [
          _ColorStop(value: 0, color: Color(0xFF8F949B)),
          _ColorStop(value: 10, color: Color(0xFFF35D4B)),
          _ColorStop(value: 20, color: Color(0xFFF7A94A)),
          _ColorStop(value: 30, color: Color(0xFF67C16F)),
          _ColorStop(value: 40, color: Color(0xFFF7E14F)),
        ]);
      case HeatmapType.interference:
        return _interpolateStops(value, const [
          _ColorStop(value: -100, color: Color(0xFF8F949B)),
          _ColorStop(value: -85, color: Color(0xFF67C16F)),
          _ColorStop(value: -75, color: Color(0xFFF7A94A)),
          _ColorStop(value: -60, color: Color(0xFFF35D4B)),
          _ColorStop(value: -45, color: Color(0xFF7A1F14)),
        ]);
      case HeatmapType.throughput:
        return _interpolateStops(value, const [
          _ColorStop(value: 0, color: Color(0xFF8F949B)),
          _ColorStop(value: 80, color: Color(0xFFF35D4B)),
          _ColorStop(value: 220, color: Color(0xFFF7A94A)),
          _ColorStop(value: 420, color: Color(0xFF67C16F)),
          _ColorStop(value: 700, color: Color(0xFFF7E14F)),
        ]);
    }
  }

  Color _interpolateStops(double value, List<_ColorStop> stops) {
    if (value <= stops.first.value) {
      return stops.first.color;
    }
    for (var index = 0; index < stops.length - 1; index++) {
      final current = stops[index];
      final next = stops[index + 1];
      if (value <= next.value) {
        final range = next.value - current.value;
        final t = range == 0 ? 0.0 : ((value - current.value) / range);
        return Color.lerp(current.color, next.color, t.clamp(0.0, 1.0))!;
      }
    }
    return stops.last.color;
  }
}

class _ColorStop {
  const _ColorStop({required this.value, required this.color});

  final double value;
  final Color color;
}
