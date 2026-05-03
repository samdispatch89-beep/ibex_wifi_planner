import 'dart:math' as math;

import '../../models/rf_result.dart';

class EnvironmentProfile {
  const EnvironmentProfile({
    required this.ituDistanceFactor,
    required this.shadowStdDev,
    required this.rangeMeters,
    required this.label,
  });

  final double ituDistanceFactor;
  final double shadowStdDev;
  final double rangeMeters;
  final String label;
}

class PathLossModel {
  const PathLossModel();

  EnvironmentProfile profileFor(EnvironmentPreset preset) {
    switch (preset) {
      case EnvironmentPreset.openSpace:
        return const EnvironmentProfile(
          ituDistanceFactor: 24,
          shadowStdDev: 1.2,
          rangeMeters: 34,
          label: 'Open space',
        );
      case EnvironmentPreset.office:
        return const EnvironmentProfile(
          ituDistanceFactor: 29,
          shadowStdDev: 2.1,
          rangeMeters: 26,
          label: 'Office',
        );
      case EnvironmentPreset.denseOffice:
        return const EnvironmentProfile(
          ituDistanceFactor: 35,
          shadowStdDev: 3.0,
          rangeMeters: 20,
          label: 'Dense office',
        );
      case EnvironmentPreset.warehouse:
        return const EnvironmentProfile(
          ituDistanceFactor: 24,
          shadowStdDev: 2.6,
          rangeMeters: 30,
          label: 'Warehouse',
        );
    }
  }

  double calculatePathLoss({
    required double frequencyMhz,
    required double distanceMeters,
    required EnvironmentPreset environmentPreset,
    required double floorLossDb,
    required double wallLossDb,
    double environmentalLossDb = 0,
    double shadowFadingDb = 0,
  }) {
    final safeDistance = distanceMeters <= 0.5 ? 0.5 : distanceMeters;
    final profile = profileFor(environmentPreset);
    final distanceComponent =
        profile.ituDistanceFactor * math.log(safeDistance) / math.ln10;

    return (20 * math.log(frequencyMhz) / math.ln10) +
        distanceComponent +
        floorLossDb +
        wallLossDb +
        environmentalLossDb -
        28 +
        shadowFadingDb;
  }
}
