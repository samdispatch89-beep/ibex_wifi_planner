import 'dart:math' as math;

import '../../models/access_point.dart';
import '../../models/rf_result.dart';

class EnvironmentProfile {
  const EnvironmentProfile({
    required this.pathLossExponent,
    required this.shadowStdDev,
    required this.environmentalLossDb,
    required this.rangeMeters,
  });

  final double pathLossExponent;
  final double shadowStdDev;
  final double environmentalLossDb;
  final double rangeMeters;
}

class PathLossModel {
  const PathLossModel();

  EnvironmentProfile profileFor(EnvironmentPreset preset) {
    switch (preset) {
      case EnvironmentPreset.openSpace:
        return const EnvironmentProfile(
          pathLossExponent: 2.0,
          shadowStdDev: 1.2,
          environmentalLossDb: 0.8,
          rangeMeters: 32,
        );
      case EnvironmentPreset.office:
        return const EnvironmentProfile(
          pathLossExponent: 2.4,
          shadowStdDev: 2.1,
          environmentalLossDb: 1.5,
          rangeMeters: 26,
        );
      case EnvironmentPreset.denseOffice:
        return const EnvironmentProfile(
          pathLossExponent: 3.1,
          shadowStdDev: 3.0,
          environmentalLossDb: 2.4,
          rangeMeters: 20,
        );
      case EnvironmentPreset.warehouse:
        return const EnvironmentProfile(
          pathLossExponent: 2.8,
          shadowStdDev: 2.6,
          environmentalLossDb: 1.8,
          rangeMeters: 30,
        );
    }
  }

  double calculatePathLoss({
    required double distanceMeters,
    required FrequencyBand band,
    required EnvironmentPreset environmentPreset,
    double shadowFadingDb = 0,
  }) {
    final safeDistance = distanceMeters <= 0.5 ? 0.5 : distanceMeters;
    final profile = profileFor(environmentPreset);
    final fsplAtReference = _freeSpacePathLoss(1, band.frequencyMhz);
    final distanceComponent =
        10 * profile.pathLossExponent * math.log(safeDistance) / math.ln10;
    final bandPenalty = switch (band) {
      FrequencyBand.band24 => 0.0,
      FrequencyBand.band5 => 3.0,
      FrequencyBand.band6 => 4.8,
    };

    return fsplAtReference +
        distanceComponent +
        profile.environmentalLossDb +
        bandPenalty +
        shadowFadingDb;
  }

  double _freeSpacePathLoss(double distanceMeters, double frequencyMhz) {
    return 20 * math.log(distanceMeters) / math.ln10 +
        20 * math.log(frequencyMhz) / math.ln10 -
        27.55;
  }
}
