import 'dart:math' as math;

import '../../models/access_point.dart';
import '../../models/floor_plan.dart';
import '../../models/material_obstacle.dart';
import '../../models/rf_result.dart';
import '../../models/user_density.dart';
import 'path_loss_model.dart';
import 'rf_engine.dart';

class AutoPlannerEngine {
  AutoPlannerEngine({RfEngine? rfEngine, PathLossModel? pathLossModel})
    : _rfEngine = rfEngine ?? RfEngine(),
      _pathLossModel = pathLossModel ?? const PathLossModel();

  final RfEngine _rfEngine;
  final PathLossModel _pathLossModel;

  Future<List<RfAccessPoint>> suggestAccessPoints({
    required FloorPlan floorPlan,
    required List<RfAccessPoint> currentAccessPoints,
    required List<MaterialObstacle> obstacles,
    required List<UserDensityZone> densityZones,
    required SimulationSettings settings,
    int maxNewAccessPoints = 3,
  }) async {
    final working = List<RfAccessPoint>.from(currentAccessPoints);
    final profile = _pathLossModel.profileFor(settings.environmentPreset);
    final columns = math.max(4, (floorPlan.widthMeters / 6).round());
    final rows = math.max(4, (floorPlan.heightMeters / 6).round());

    for (var iteration = 0; iteration < maxNewAccessPoints; iteration++) {
      final simulation = await _rfEngine.simulate(
        floorPlan: floorPlan,
        accessPoints: working,
        obstacles: obstacles,
        densityZones: densityZones,
        settings: settings,
      );

      final worstCell = simulation.cells
          .where((cell) => cell.metrics.rssiDbm < -65)
          .fold<HeatmapCell?>(null, (best, cell) {
            if (best == null || cell.metrics.rssiDbm < best.metrics.rssiDbm) {
              return cell;
            }
            return best;
          });

      if (worstCell == null) {
        break;
      }

      final x =
          floorPlan.widthMeters *
          ((worstCell.column + 0.5) / settings.gridColumns);
      final y =
          floorPlan.heightMeters * ((worstCell.row + 0.5) / settings.gridRows);
      final candidateX = x.clamp(
        profile.rangeMeters * 0.3,
        floorPlan.widthMeters - 1,
      );
      final candidateY = y.clamp(
        profile.rangeMeters * 0.3,
        floorPlan.heightMeters - 1,
      );
      final optimizedChannel = _selectChannel(
        accessPoints: working,
        band: settings.selectedBand,
        xMeters: candidateX.toDouble(),
        yMeters: candidateY.toDouble(),
      );

      working.add(
        RfAccessPoint(
          id: 'auto-${working.length + 1}',
          name: 'AUTO-${working.length + 1}',
          xMeters: candidateX.toDouble(),
          yMeters: candidateY.toDouble(),
          floor: floorPlan.currentFloor,
          txPowerDbm: settings.selectedBand == FrequencyBand.band24 ? 14 : 17,
          channel: optimizedChannel,
          band: settings.selectedBand,
        ),
      );

      if (iteration % 1 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    return _annealChannels(
      accessPoints: working,
      floorPlan: floorPlan,
      columns: columns,
      rows: rows,
    );
  }

  int _selectChannel({
    required List<RfAccessPoint> accessPoints,
    required FrequencyBand band,
    required double xMeters,
    required double yMeters,
  }) {
    final channels = band.recommendedChannels;
    var bestChannel = channels.first;
    var bestScore = double.infinity;

    for (final channel in channels) {
      var score = 0.0;
      for (final accessPoint in accessPoints.where((ap) => ap.band == band)) {
        final dx = xMeters - accessPoint.xMeters;
        final dy = yMeters - accessPoint.yMeters;
        final distancePenalty =
            1 / math.max(1, math.sqrt((dx * dx) + (dy * dy)));
        final overlap = (channel - accessPoint.channel).abs();
        final channelPenalty = overlap == 0 ? 1.0 : (overlap <= 4 ? 0.35 : 0.0);
        score += distancePenalty * channelPenalty;
      }

      if (score < bestScore) {
        bestScore = score;
        bestChannel = channel;
      }
    }

    return bestChannel;
  }

  List<RfAccessPoint> _annealChannels({
    required List<RfAccessPoint> accessPoints,
    required FloorPlan floorPlan,
    required int columns,
    required int rows,
  }) {
    final updated = <RfAccessPoint>[];
    for (final accessPoint in accessPoints) {
      final channel = _selectChannel(
        accessPoints: updated + accessPoints,
        band: accessPoint.band,
        xMeters: accessPoint.xMeters,
        yMeters: accessPoint.yMeters,
      );
      final txPower = accessPoint.band == FrequencyBand.band24
          ? accessPoint.txPowerDbm.clamp(12, 16).toDouble()
          : accessPoint.txPowerDbm.clamp(14, 18).toDouble();
      updated.add(accessPoint.copyWith(channel: channel, txPowerDbm: txPower));
    }
    return updated;
  }
}
