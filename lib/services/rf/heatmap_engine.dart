import '../../models/rf_result.dart';

class HeatmapRange {
  const HeatmapRange({
    required this.min,
    required this.max,
    required this.label,
  });

  final double min;
  final double max;
  final String label;
}

class HeatmapEngine {
  const HeatmapEngine();

  HeatmapRange rangeFor(HeatmapType type) {
    switch (type) {
      case HeatmapType.rssi:
        return const HeatmapRange(min: -90, max: -40, label: 'RSSI (dBm)');
      case HeatmapType.snr:
        return const HeatmapRange(min: 0, max: 40, label: 'SNR (dB)');
      case HeatmapType.sinr:
        return const HeatmapRange(min: 0, max: 40, label: 'SINR (dB)');
      case HeatmapType.throughput:
        return const HeatmapRange(min: 0, max: 700, label: 'Throughput (Mbps)');
      case HeatmapType.interference:
        return const HeatmapRange(
          min: -100,
          max: -45,
          label: 'Interference (dBm)',
        );
    }
  }

  double valueForCell(HeatmapCell cell, HeatmapType type) {
    switch (type) {
      case HeatmapType.rssi:
        return cell.metrics.rssiDbm;
      case HeatmapType.snr:
        return cell.metrics.snrDb;
      case HeatmapType.sinr:
        return cell.metrics.sinrDb;
      case HeatmapType.throughput:
        return cell.metrics.throughputMbps;
      case HeatmapType.interference:
        return cell.metrics.interferenceDb;
    }
  }

  double normalize(HeatmapType type, double value) {
    final range = rangeFor(type);
    final span = range.max - range.min;
    if (span <= 0) {
      return 0;
    }
    return ((value - range.min) / span).clamp(0.0, 1.0);
  }
}
