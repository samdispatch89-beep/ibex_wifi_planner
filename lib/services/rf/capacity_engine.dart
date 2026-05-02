import '../../models/access_point.dart';
import '../../models/user_density.dart';

class ThroughputEstimate {
  const ThroughputEstimate({
    required this.throughputMbps,
    required this.airtimeUtilization,
    required this.estimatedClients,
    required this.isOverloaded,
  });

  final double throughputMbps;
  final double airtimeUtilization;
  final int estimatedClients;
  final bool isOverloaded;
}

class CapacityEngine {
  const CapacityEngine();

  double estimateThroughputMbps({
    required FrequencyBand band,
    required double snrDb,
  }) {
    final bandMultiplier = switch (band) {
      FrequencyBand.band24 => 0.6,
      FrequencyBand.band5 => 1.0,
      FrequencyBand.band6 => 1.15,
    };
    final baseRate = switch (snrDb) {
      <= 5 => 8.0,
      <= 10 => 18.0,
      <= 15 => 45.0,
      <= 20 => 90.0,
      <= 25 => 180.0,
      <= 30 => 320.0,
      <= 35 => 540.0,
      _ => 720.0,
    };
    return baseRate * bandMultiplier;
  }

  ThroughputEstimate estimateLoad({
    required RfAccessPoint accessPoint,
    required double snrDb,
    required List<UserDensityZone> densityZones,
    required double xMeters,
    required double yMeters,
  }) {
    final zone = densityZones
        .where((candidate) {
          return candidate.floor == accessPoint.floor &&
              candidate.contains(xMeters, yMeters);
        })
        .fold<UserDensityZone?>(null, (best, candidate) {
          if (best == null || candidate.expectedUsers > best.expectedUsers) {
            return candidate;
          }
          return best;
        });

    final peakThroughput = estimateThroughputMbps(
      band: accessPoint.band,
      snrDb: snrDb,
    );
    if (zone == null) {
      return ThroughputEstimate(
        throughputMbps: peakThroughput,
        airtimeUtilization: 0.18,
        estimatedClients: 6,
        isOverloaded: false,
      );
    }

    final expectedClients = (zone.expectedUsers / 2).round().clamp(1, 500);
    final demandMbps = zone.demandMbps / 2;
    final airtimeUtilization =
        (demandMbps / (peakThroughput <= 1 ? 1 : peakThroughput))
            .clamp(0.05, 1.4)
            .toDouble();

    return ThroughputEstimate(
      throughputMbps:
          peakThroughput * (1 - (airtimeUtilization.clamp(0, 0.92))),
      airtimeUtilization: airtimeUtilization,
      estimatedClients: expectedClients,
      isOverloaded:
          airtimeUtilization > 0.85 || expectedClients > accessPoint.maxClients,
    );
  }
}
