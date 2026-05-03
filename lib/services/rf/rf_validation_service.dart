import '../../models/access_point.dart';
import '../../models/floor_plan.dart';
import '../../models/material_obstacle.dart';
import '../../models/rf_result.dart';
import '../../models/wall_segment.dart';
import '../../models/world_point.dart';
import 'rf_engine.dart';

class RfValidationService {
  RfValidationService({RfEngine? rfEngine})
    : _rfEngine = rfEngine ?? RfEngine();

  final RfEngine _rfEngine;

  Future<List<ValidationScenarioResult>> run({
    required SimulationSettings settings,
  }) async {
    final baselinePlan = const FloorPlan(
      id: 'validation-plan',
      name: 'Validation plan',
      widthMeters: 30,
      heightMeters: 30,
      imagePixelWidth: 1200,
      imagePixelHeight: 1200,
      metersPerPixel: 0.025,
    );
    final openAp = const RfAccessPoint(
      id: 'ap-open',
      name: 'AP-open',
      xMeters: 15,
      yMeters: 15,
      floor: 0,
      txPowerDbm: 18,
      channel: 36,
      band: FrequencyBand.band5,
    );

    final openPointA = _rfEngine.computePointMetrics(
      xMeters: 20,
      yMeters: 15,
      floorPlan: baselinePlan,
      accessPoints: [openAp],
      walls: const [],
      obstacles: const [],
      densityZones: const [],
      settings: settings.copyWith(selectedBand: FrequencyBand.band5),
    );
    final openPointB = _rfEngine.computePointMetrics(
      xMeters: 15,
      yMeters: 20,
      floorPlan: baselinePlan,
      accessPoints: [openAp],
      walls: const [],
      obstacles: const [],
      densityZones: const [],
      settings: settings.copyWith(selectedBand: FrequencyBand.band5),
    );

    final wall = WallSegment(
      id: 'wall',
      start: const WorldPoint(xMeters: 17, yMeters: 8),
      end: const WorldPoint(xMeters: 17, yMeters: 22),
      materialType: MaterialType.concrete,
      attenuationDb: 15,
    );
    final wallFree = _rfEngine.computePointMetrics(
      xMeters: 16,
      yMeters: 15,
      floorPlan: baselinePlan,
      accessPoints: [openAp],
      walls: const [],
      obstacles: const [],
      densityZones: const [],
      settings: settings.copyWith(selectedBand: FrequencyBand.band5),
    );
    final wallBlocked = _rfEngine.computePointMetrics(
      xMeters: 22,
      yMeters: 15,
      floorPlan: baselinePlan,
      accessPoints: [openAp],
      walls: [wall],
      obstacles: const [],
      densityZones: const [],
      settings: settings.copyWith(selectedBand: FrequencyBand.band5),
    );

    final overlapAps = const [
      RfAccessPoint(
        id: 'left',
        name: 'Left',
        xMeters: 9,
        yMeters: 15,
        floor: 0,
        txPowerDbm: 17,
        channel: 36,
        band: FrequencyBand.band5,
      ),
      RfAccessPoint(
        id: 'right',
        name: 'Right',
        xMeters: 21,
        yMeters: 15,
        floor: 0,
        txPowerDbm: 17,
        channel: 36,
        band: FrequencyBand.band5,
      ),
    ];
    final leftZone = _rfEngine.computePointMetrics(
      xMeters: 11,
      yMeters: 15,
      floorPlan: baselinePlan,
      accessPoints: overlapAps,
      walls: const [],
      obstacles: const [],
      densityZones: const [],
      settings: settings.copyWith(selectedBand: FrequencyBand.band5),
    );
    final rightZone = _rfEngine.computePointMetrics(
      xMeters: 19,
      yMeters: 15,
      floorPlan: baselinePlan,
      accessPoints: overlapAps,
      walls: const [],
      obstacles: const [],
      densityZones: const [],
      settings: settings.copyWith(selectedBand: FrequencyBand.band5),
    );

    final lowNoise = _rfEngine.computePointMetrics(
      xMeters: 20,
      yMeters: 15,
      floorPlan: baselinePlan,
      accessPoints: [openAp],
      walls: const [],
      obstacles: const [],
      densityZones: const [],
      settings: settings.copyWith(
        selectedBand: FrequencyBand.band5,
        noiseFloorDbm: -96,
      ),
    );
    final highNoise = _rfEngine.computePointMetrics(
      xMeters: 20,
      yMeters: 15,
      floorPlan: baselinePlan,
      accessPoints: [openAp],
      walls: const [],
      obstacles: const [],
      densityZones: const [],
      settings: settings.copyWith(
        selectedBand: FrequencyBand.band5,
        noiseFloorDbm: -84,
      ),
    );

    return [
      ValidationScenarioResult(
        title: 'Single AP open space',
        passed: (openPointA.rssiDbm - openPointB.rssiDbm).abs() < 1.5,
        details:
            'Symmetry delta ${(openPointA.rssiDbm - openPointB.rssiDbm).abs().toStringAsFixed(2)} dB.',
      ),
      ValidationScenarioResult(
        title: 'Wall attenuation shadow',
        passed: wallBlocked.rssiDbm < wallFree.rssiDbm - 3,
        details:
            'Open ${wallFree.rssiDbm.toStringAsFixed(1)} dBm vs blocked ${wallBlocked.rssiDbm.toStringAsFixed(1)} dBm.',
      ),
      ValidationScenarioResult(
        title: 'Two AP dominance regions',
        passed: leftZone.bestServingApId != rightZone.bestServingApId,
        details:
            'Left=${leftZone.bestServingApId}, right=${rightZone.bestServingApId}.',
      ),
      ValidationScenarioResult(
        title: 'Increased noise lowers SINR',
        passed: highNoise.sinrDb < lowNoise.sinrDb,
        details:
            'Low noise ${lowNoise.sinrDb.toStringAsFixed(1)} dB vs high noise ${highNoise.sinrDb.toStringAsFixed(1)} dB.',
      ),
    ];
  }
}
