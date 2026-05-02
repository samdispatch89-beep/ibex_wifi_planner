import 'dart:async';
import 'dart:math' as math;

import '../../models/access_point.dart';
import '../../models/floor_plan.dart';
import '../../models/material_obstacle.dart';
import '../../models/rf_result.dart';
import '../../models/user_density.dart';
import 'capacity_engine.dart';
import 'interference_engine.dart';
import 'path_loss_model.dart';

typedef SimulationProgress = void Function(double progress);

class RfEngine {
  RfEngine({
    PathLossModel? pathLossModel,
    InterferenceEngine? interferenceEngine,
    CapacityEngine? capacityEngine,
  }) : _pathLossModel = pathLossModel ?? const PathLossModel(),
       _interferenceEngine = interferenceEngine ?? const InterferenceEngine(),
       _capacityEngine = capacityEngine ?? const CapacityEngine();

  final PathLossModel _pathLossModel;
  final InterferenceEngine _interferenceEngine;
  final CapacityEngine _capacityEngine;

  Future<SimulationResult> simulate({
    required FloorPlan floorPlan,
    required List<RfAccessPoint> accessPoints,
    required List<MaterialObstacle> obstacles,
    required List<UserDensityZone> densityZones,
    required SimulationSettings settings,
    SimulationProgress? onProgress,
  }) async {
    if (floorPlan.widthMeters <= 0 ||
        floorPlan.heightMeters <= 0 ||
        accessPoints
            .where((ap) => ap.enabled && ap.band == settings.selectedBand)
            .isEmpty) {
      return SimulationResult.empty;
    }

    final filteredAps = accessPoints
        .where((ap) => ap.enabled && ap.band == settings.selectedBand)
        .toList(growable: false);
    final cells = <HeatmapCell>[];
    final attenuationCache = <String, double>{};
    final totalCells = settings.gridColumns * settings.gridRows;

    for (var row = 0; row < settings.gridRows; row++) {
      for (var column = 0; column < settings.gridColumns; column++) {
        final x =
            floorPlan.widthMeters * ((column + 0.5) / settings.gridColumns);
        final y = floorPlan.heightMeters * ((row + 0.5) / settings.gridRows);
        final metrics = computePointMetrics(
          xMeters: x,
          yMeters: y,
          floorPlan: floorPlan,
          accessPoints: filteredAps,
          obstacles: obstacles,
          densityZones: densityZones,
          settings: settings,
          attenuationCache: attenuationCache,
        );
        cells.add(HeatmapCell(column: column, row: row, metrics: metrics));
      }

      onProgress?.call(((row + 1) * settings.gridColumns) / totalCells);
      if (row % 6 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    final overloaded = _summarizeOverloaded(cells);
    final coverage = cells.isEmpty
        ? 0.0
        : cells.where((cell) => cell.metrics.rssiDbm >= -65).length /
              cells.length;
    final avgSnr = cells.isEmpty
        ? 0.0
        : cells.map((cell) => cell.metrics.snrDb).reduce((a, b) => a + b) /
              cells.length;
    final avgSinr = cells.isEmpty
        ? 0.0
        : cells.map((cell) => cell.metrics.sinrDb).reduce((a, b) => a + b) /
              cells.length;
    final avgThroughput = cells.isEmpty
        ? 0.0
        : cells
                  .map((cell) => cell.metrics.throughputMbps)
                  .reduce((a, b) => a + b) /
              cells.length;

    return SimulationResult(
      cells: cells,
      summary: SimulationSummary(
        coverageAtMinus65: coverage * 100,
        averageSnr: avgSnr,
        averageSinr: avgSinr,
        averageThroughputMbps: avgThroughput,
        overloadedAccessPoints: overloaded,
      ),
      recommendations: const [],
    );
  }

  PointMetrics computePointMetrics({
    required double xMeters,
    required double yMeters,
    required FloorPlan floorPlan,
    required List<RfAccessPoint> accessPoints,
    required List<MaterialObstacle> obstacles,
    required List<UserDensityZone> densityZones,
    required SimulationSettings settings,
    Map<String, double>? attenuationCache,
  }) {
    if (accessPoints.isEmpty) {
      return PointMetrics.at(xMeters, yMeters);
    }

    final signals = <RfAccessPoint, double>{};
    final profile = _pathLossModel.profileFor(settings.environmentPreset);

    for (final accessPoint in accessPoints) {
      final dx = xMeters - accessPoint.xMeters;
      final dy = yMeters - accessPoint.yMeters;
      final distance = math.max(math.sqrt((dx * dx) + (dy * dy)), 0.5);
      if (distance > profile.rangeMeters * 1.35) {
        continue;
      }

      final shadow = settings.enableShadowFading
          ? _shadowFading(
              accessPointId: accessPoint.id,
              xMeters: xMeters,
              yMeters: yMeters,
              stdDev: settings.shadowFadingStdDev,
            )
          : 0.0;
      final obstacleLoss = _obstacleLoss(
        accessPoint: accessPoint,
        xMeters: xMeters,
        yMeters: yMeters,
        obstacles: obstacles,
        cache: attenuationCache,
      );
      final floorLoss =
          (accessPoint.floor - floorPlan.currentFloor).abs() *
          floorPlan.floorAttenuationDb;
      final pathLoss = _pathLossModel.calculatePathLoss(
        distanceMeters: distance,
        band: accessPoint.band,
        environmentPreset: settings.environmentPreset,
        shadowFadingDb: shadow,
      );
      final directionalGain = _directionalGainDb(accessPoint, dx, dy);
      final receivedDbm =
          accessPoint.txPowerDbm +
          accessPoint.antennaGainDbi +
          directionalGain -
          pathLoss -
          obstacleLoss -
          floorLoss -
          floorPlan.temperatureLossDb;

      if (receivedDbm >= settings.minUsefulRssiDbm - 18) {
        signals[accessPoint] = receivedDbm;
      }
    }

    if (signals.isEmpty) {
      return PointMetrics.at(xMeters, yMeters);
    }

    final bestEntry = signals.entries.reduce(
      (best, current) => current.value > best.value ? current : best,
    );
    final rssi = bestEntry.value;
    final snr = (rssi - settings.noiseFloorDbm).clamp(0.0, 60.0).toDouble();
    final interferenceDbm = _interferenceEngine.calculateInterferenceDbm(
      bestAccessPoint: bestEntry.key,
      receivedSignalsDbm: signals,
    );
    final sinr = _interferenceEngine.calculateSinrDb(
      signalDbm: rssi,
      interferenceDbm: interferenceDbm,
      noiseFloorDbm: settings.noiseFloorDbm,
    );
    final load = _capacityEngine.estimateLoad(
      accessPoint: bestEntry.key,
      snrDb: snr,
      densityZones: densityZones,
      xMeters: xMeters,
      yMeters: yMeters,
    );

    return PointMetrics(
      xMeters: xMeters,
      yMeters: yMeters,
      rssiDbm: _finite(rssi, fallback: -120),
      snrDb: _finite(snr, fallback: 0),
      sinrDb: _finite(sinr, fallback: 0),
      interferenceDb: _finite(interferenceDbm, fallback: -120),
      throughputMbps: _finite(load.throughputMbps, fallback: 0),
      bestServingApId: bestEntry.key.id,
      airtimeUtilization: _finite(load.airtimeUtilization, fallback: 0),
      isOverloaded: load.isOverloaded,
    );
  }

  List<OverloadedAccessPoint> _summarizeOverloaded(List<HeatmapCell> cells) {
    final apUtilization = <String, List<PointMetrics>>{};
    for (final cell in cells) {
      final apId = cell.metrics.bestServingApId;
      if (apId == null) {
        continue;
      }
      apUtilization.putIfAbsent(apId, () => []).add(cell.metrics);
    }

    return apUtilization.entries
        .map((entry) {
          final avgUtilization =
              entry.value
                  .map((item) => item.airtimeUtilization)
                  .reduce((a, b) => a + b) /
              entry.value.length;
          final avgThroughput =
              entry.value
                  .map((item) => item.throughputMbps)
                  .reduce((a, b) => a + b) /
              entry.value.length;
          final estimatedClients = (entry.value.length * avgUtilization * 2.6)
              .round()
              .clamp(0, 500);
          return OverloadedAccessPoint(
            accessPointId: entry.key,
            airtimeUtilization: avgUtilization,
            throughputMbps: avgThroughput,
            estimatedClients: estimatedClients,
          );
        })
        .where((item) => item.airtimeUtilization > 0.85)
        .toList(growable: false);
  }

  double _obstacleLoss({
    required RfAccessPoint accessPoint,
    required double xMeters,
    required double yMeters,
    required List<MaterialObstacle> obstacles,
    Map<String, double>? cache,
  }) {
    final key =
        '${accessPoint.id}:${xMeters.toStringAsFixed(2)}:${yMeters.toStringAsFixed(2)}';
    if (cache != null && cache.containsKey(key)) {
      return cache[key]!;
    }

    var totalLoss = 0.0;
    for (final obstacle in obstacles) {
      if (obstacle.floor != accessPoint.floor) {
        continue;
      }
      if (obstacle.intersectsLine(
        x1: accessPoint.xMeters,
        y1: accessPoint.yMeters,
        x2: xMeters,
        y2: yMeters,
      )) {
        totalLoss += obstacle.attenuationDb;
      }
    }
    cache?[key] = totalLoss;
    return totalLoss;
  }

  double _shadowFading({
    required String accessPointId,
    required double xMeters,
    required double yMeters,
    required double stdDev,
  }) {
    final seed =
        accessPointId.hashCode ^ xMeters.round() ^ (yMeters.round() << 4);
    final hash = math.sin(seed.toDouble() * 12.9898) * 43758.5453;
    final normalized = hash - hash.floorToDouble();
    return ((normalized * 2) - 1) * stdDev;
  }

  double _directionalGainDb(RfAccessPoint accessPoint, double dx, double dy) {
    if (accessPoint.antennaPattern != AntennaPattern.directional) {
      return 0;
    }
    final targetDegrees = math.atan2(dy, dx) * 180 / math.pi;
    final difference = (targetDegrees - accessPoint.azimuthDegrees).abs() % 360;
    final normalized = difference > 180 ? 360 - difference : difference;
    if (normalized <= 45) {
      return 2;
    }
    if (normalized <= 90) {
      return -2;
    }
    return -6;
  }

  double _finite(double value, {required double fallback}) {
    if (value.isNaN || value.isInfinite) {
      return fallback;
    }
    return value;
  }
}
