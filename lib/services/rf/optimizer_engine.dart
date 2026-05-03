import 'dart:math' as math;

import '../../models/access_point.dart';
import '../../models/floor_plan.dart';
import '../../models/material_obstacle.dart';
import '../../models/rf_result.dart';
import '../../models/user_density.dart';
import '../../models/wall_segment.dart';
import 'rf_engine.dart';

class OptimizerEngine {
  OptimizerEngine({RfEngine? rfEngine}) : _rfEngine = rfEngine ?? RfEngine();

  final RfEngine _rfEngine;

  Future<List<OptimizerRecommendation>> generateRecommendations({
    required FloorPlan floorPlan,
    required List<RfAccessPoint> accessPoints,
    required List<WallSegment> walls,
    required List<MaterialObstacle> obstacles,
    required List<UserDensityZone> densityZones,
    required SimulationSettings settings,
    required SimulationResult baseline,
  }) async {
    final recommendations = <OptimizerRecommendation>[];

    for (final overloaded in baseline.summary.overloadedAccessPoints) {
      recommendations.add(
        OptimizerRecommendation(
          id: 'overloaded-${overloaded.accessPointId}',
          type: RecommendationType.overloadedAp,
          title: 'Reduce load on ${overloaded.accessPointId}',
          description:
              'High airtime utilization detected. Add capacity or rebalance nearby radios.',
          impactSummary:
              'Current airtime ${(overloaded.airtimeUtilization * 100).toStringAsFixed(0)}%, average throughput ${overloaded.throughputMbps.toStringAsFixed(0)} Mbps.',
          targetAccessPointId: overloaded.accessPointId,
        ),
      );
    }

    for (final accessPoint in accessPoints.where(
      (ap) => ap.band == settings.selectedBand,
    )) {
      final sameChannelNeighbors = accessPoints
          .where((other) {
            if (other.id == accessPoint.id || other.band != accessPoint.band) {
              return false;
            }
            return other.channel == accessPoint.channel &&
                _distance(accessPoint, other) < 16;
          })
          .toList(growable: false);

      if (sameChannelNeighbors.isNotEmpty) {
        final suggestedChannel = accessPoint.band.recommendedChannels
            .firstWhere(
              (channel) => channel != accessPoint.channel,
              orElse: () => accessPoint.channel,
            );
        final delta = await _simulateRecommendation(
          floorPlan: floorPlan,
          accessPoints: accessPoints
              .map(
                (candidate) => candidate.id == accessPoint.id
                    ? candidate.copyWith(channel: suggestedChannel)
                    : candidate,
              )
              .toList(growable: false),
          walls: walls,
          obstacles: obstacles,
          densityZones: densityZones,
          settings: settings,
          baseline: baseline,
        );
        recommendations.add(
          OptimizerRecommendation(
            id: 'channel-${accessPoint.id}',
            type: RecommendationType.changeChannel,
            title: 'Move ${accessPoint.name} to channel $suggestedChannel',
            description:
                'Close same-channel radios are driving co-channel contention.',
            impactSummary: delta,
            targetAccessPointId: accessPoint.id,
            suggestedChannel: suggestedChannel,
          ),
        );
      }

      if (accessPoint.txPowerDbm > 16) {
        final delta = await _simulateRecommendation(
          floorPlan: floorPlan,
          accessPoints: accessPoints
              .map(
                (candidate) => candidate.id == accessPoint.id
                    ? candidate.copyWith(txPowerDbm: accessPoint.txPowerDbm - 2)
                    : candidate,
              )
              .toList(growable: false),
          walls: walls,
          obstacles: obstacles,
          densityZones: densityZones,
          settings: settings,
          baseline: baseline,
        );
        recommendations.add(
          OptimizerRecommendation(
            id: 'tx-down-${accessPoint.id}',
            type: RecommendationType.reduceTxPower,
            title: 'Reduce ${accessPoint.name} TX power',
            description:
                'High-power radios increase overlap and can reduce roaming quality.',
            impactSummary: delta,
            targetAccessPointId: accessPoint.id,
            suggestedTxPowerDbm: accessPoint.txPowerDbm - 2,
          ),
        );
      }
    }

    final weakestCell = baseline.cells.fold<HeatmapCell?>(null, (best, cell) {
      if (best == null || cell.metrics.rssiDbm < best.metrics.rssiDbm) {
        return cell;
      }
      return best;
    });
    if (weakestCell != null && weakestCell.metrics.rssiDbm < -67) {
      final x =
          floorPlan.widthMeters *
          ((weakestCell.column + 0.5) / settings.gridColumns);
      final y =
          floorPlan.heightMeters *
          ((weakestCell.row + 0.5) / settings.gridRows);
      final proposed = RfAccessPoint(
        id: 'candidate-${accessPoints.length + 1}',
        name: 'Candidate AP',
        xMeters: x,
        yMeters: y,
        floor: floorPlan.currentFloor,
        txPowerDbm: settings.selectedBand == FrequencyBand.band24 ? 14 : 17,
        channel: settings.selectedBand.recommendedChannels.first,
        band: settings.selectedBand,
      );
      final delta = await _simulateRecommendation(
        floorPlan: floorPlan,
        accessPoints: [...accessPoints, proposed],
        walls: walls,
        obstacles: obstacles,
        densityZones: densityZones,
        settings: settings,
        baseline: baseline,
      );
      recommendations.add(
        OptimizerRecommendation(
          id: 'add-${proposed.id}',
          type: RecommendationType.addAp,
          title: 'Add AP near weak coverage pocket',
          description:
              'Coverage target is missed in a low-signal pocket of the plan.',
          impactSummary: delta,
          suggestedAccessPoint: proposed,
        ),
      );
    }

    return recommendations.take(6).toList(growable: false);
  }

  List<RfAccessPoint> applyRecommendation({
    required List<RfAccessPoint> accessPoints,
    required OptimizerRecommendation recommendation,
  }) {
    switch (recommendation.type) {
      case RecommendationType.addAp:
        if (recommendation.suggestedAccessPoint != null) {
          return [...accessPoints, recommendation.suggestedAccessPoint!];
        }
        return accessPoints;
      case RecommendationType.changeChannel:
        return accessPoints
            .map(
              (accessPoint) =>
                  accessPoint.id == recommendation.targetAccessPointId
                  ? accessPoint.copyWith(
                      channel: recommendation.suggestedChannel,
                    )
                  : accessPoint,
            )
            .toList(growable: false);
      case RecommendationType.reduceTxPower:
      case RecommendationType.increaseTxPower:
        return accessPoints
            .map(
              (accessPoint) =>
                  accessPoint.id == recommendation.targetAccessPointId
                  ? accessPoint.copyWith(
                      txPowerDbm:
                          recommendation.suggestedTxPowerDbm ??
                          accessPoint.txPowerDbm,
                    )
                  : accessPoint,
            )
            .toList(growable: false);
      case RecommendationType.moveAp:
        return accessPoints
            .map(
              (accessPoint) =>
                  accessPoint.id == recommendation.targetAccessPointId &&
                      recommendation.suggestedAccessPoint != null
                  ? recommendation.suggestedAccessPoint!
                  : accessPoint,
            )
            .toList(growable: false);
      case RecommendationType.overloadedAp:
        return accessPoints;
    }
  }

  Future<String> _simulateRecommendation({
    required FloorPlan floorPlan,
    required List<RfAccessPoint> accessPoints,
    required List<WallSegment> walls,
    required List<MaterialObstacle> obstacles,
    required List<UserDensityZone> densityZones,
    required SimulationSettings settings,
    required SimulationResult baseline,
  }) async {
    final simulated = await _rfEngine.simulate(
      floorPlan: floorPlan,
      accessPoints: accessPoints,
      walls: walls,
      obstacles: obstacles,
      densityZones: densityZones,
      settings: settings,
    );
    final coverageDelta =
        simulated.summary.coverageAtMinus65 -
        baseline.summary.coverageAtMinus65;
    final throughputDelta =
        simulated.summary.averageThroughputMbps -
        baseline.summary.averageThroughputMbps;
    final sinrDelta =
        simulated.summary.averageSinr - baseline.summary.averageSinr;
    return '${coverageDelta >= 0 ? '+' : ''}${coverageDelta.toStringAsFixed(1)} coverage, '
        '${throughputDelta >= 0 ? '+' : ''}${throughputDelta.toStringAsFixed(0)} Mbps throughput, '
        '${sinrDelta >= 0 ? '+' : ''}${sinrDelta.toStringAsFixed(1)} dB SINR';
  }

  double _distance(RfAccessPoint a, RfAccessPoint b) {
    final dx = a.xMeters - b.xMeters;
    final dy = a.yMeters - b.yMeters;
    return math.sqrt((dx * dx) + (dy * dy));
  }
}
