import 'package:flutter/foundation.dart';

import '../models/access_point.dart';
import '../models/floor_plan.dart';
import '../models/material_obstacle.dart';
import '../models/planner_models.dart' as dashboard;
import '../models/rf_result.dart';
import '../models/user_density.dart';
import '../services/rf/auto_planner_engine.dart';
import '../services/rf/optimizer_engine.dart';
import '../services/rf/rf_engine.dart';

enum PlannerInteractionMode { inspect, placeAp, placeObstacle }

class RfPlannerController extends ChangeNotifier {
  RfPlannerController({
    required dashboard.PlannerSnapshot snapshot,
    RfEngine? rfEngine,
    AutoPlannerEngine? autoPlannerEngine,
    OptimizerEngine? optimizerEngine,
  }) : _rfEngine = rfEngine ?? RfEngine(),
       _autoPlannerEngine = autoPlannerEngine ?? AutoPlannerEngine(),
       _optimizerEngine = optimizerEngine ?? OptimizerEngine() {
    _seedFromSnapshot(snapshot);
  }

  final RfEngine _rfEngine;
  final AutoPlannerEngine _autoPlannerEngine;
  final OptimizerEngine _optimizerEngine;

  late FloorPlan _floorPlan;
  late SimulationSettings _settings;
  HeatmapType _heatmapType = HeatmapType.rssi;
  PlannerInteractionMode _interactionMode = PlannerInteractionMode.inspect;
  MaterialType _selectedMaterialType = MaterialType.drywall;
  late double _draftTxPowerDbm;
  late int _draftChannel;
  late FrequencyBand _draftBand;
  List<RfAccessPoint> _accessPoints = const [];
  List<MaterialObstacle> _obstacles = const [];
  List<UserDensityZone> _densityZones = const [];
  SimulationResult _simulationResult = SimulationResult.empty;
  PointMetrics? _selectedPointMetrics;
  bool _isSimulating = false;
  double _simulationProgress = 0;
  String _statusMessage = 'Ready to simulate.';

  FloorPlan get floorPlan => _floorPlan;
  SimulationSettings get settings => _settings;
  HeatmapType get heatmapType => _heatmapType;
  PlannerInteractionMode get interactionMode => _interactionMode;
  MaterialType get selectedMaterialType => _selectedMaterialType;
  double get draftTxPowerDbm => _draftTxPowerDbm;
  int get draftChannel => _draftChannel;
  FrequencyBand get draftBand => _draftBand;
  List<RfAccessPoint> get accessPoints => List.unmodifiable(_accessPoints);
  List<MaterialObstacle> get obstacles => List.unmodifiable(_obstacles);
  List<UserDensityZone> get densityZones => List.unmodifiable(_densityZones);
  SimulationResult get simulationResult => _simulationResult;
  PointMetrics? get selectedPointMetrics => _selectedPointMetrics;
  bool get isSimulating => _isSimulating;
  double get simulationProgress => _simulationProgress;
  String get statusMessage => _statusMessage;
  List<OptimizerRecommendation> get recommendations =>
      _simulationResult.recommendations;

  void updateBand(FrequencyBand band) {
    _settings = _settings.copyWith(selectedBand: band);
    _draftBand = band;
    _draftChannel = band.recommendedChannels.first;
    _statusMessage = 'Band switched to ${band.label}.';
    notifyListeners();
  }

  void updateEnvironment(EnvironmentPreset environmentPreset) {
    _settings = _settings.copyWith(environmentPreset: environmentPreset);
    _statusMessage = 'Environment preset updated.';
    notifyListeners();
  }

  void updateNoiseFloor(double value) {
    _settings = _settings.copyWith(noiseFloorDbm: value);
    _statusMessage = 'Noise floor set to ${value.toStringAsFixed(0)} dBm.';
    notifyListeners();
  }

  void updateHeatmapType(HeatmapType type) {
    _heatmapType = type;
    notifyListeners();
  }

  void updateDraftTxPower(double value) {
    _draftTxPowerDbm = value.clamp(8.0, 23.0);
    notifyListeners();
  }

  void updateDraftChannel(int channel) {
    _draftChannel = channel;
    notifyListeners();
  }

  void updateGridDensity(int columns) {
    final safeColumns = columns.clamp(18, 60);
    _settings = _settings.copyWith(
      gridColumns: safeColumns,
      gridRows:
          (safeColumns * (_floorPlan.heightMeters / _floorPlan.widthMeters))
              .round()
              .clamp(12, 48),
    );
    notifyListeners();
  }

  void updateInteractionMode(PlannerInteractionMode mode) {
    _interactionMode = mode;
    notifyListeners();
  }

  void updateSelectedMaterialType(MaterialType type) {
    _selectedMaterialType = type;
    notifyListeners();
  }

  Future<void> handleCanvasTap({
    required double normalizedX,
    required double normalizedY,
  }) async {
    final xMeters = _floorPlan.widthMeters * normalizedX;
    final yMeters = _floorPlan.heightMeters * normalizedY;
    switch (_interactionMode) {
      case PlannerInteractionMode.inspect:
        _selectedPointMetrics = _findMetricsAt(xMeters, yMeters);
        _statusMessage =
            'Point inspected at ${xMeters.toStringAsFixed(1)}m, ${yMeters.toStringAsFixed(1)}m.';
        notifyListeners();
        return;
      case PlannerInteractionMode.placeAp:
        _addAccessPoint(xMeters: xMeters, yMeters: yMeters);
        _statusMessage =
            'Placed AP at ${xMeters.toStringAsFixed(1)}m, ${yMeters.toStringAsFixed(1)}m.';
        notifyListeners();
        return;
      case PlannerInteractionMode.placeObstacle:
        _addObstacle(xMeters: xMeters, yMeters: yMeters);
        _statusMessage =
            'Placed ${_selectedMaterialType.label.toLowerCase()} obstacle.';
        notifyListeners();
        return;
    }
  }

  Future<void> runSimulation() async {
    _isSimulating = true;
    _simulationProgress = 0;
    _statusMessage = 'Running ${_settings.selectedBand.label} simulation...';
    notifyListeners();

    final result = await _rfEngine.simulate(
      floorPlan: _floorPlan,
      accessPoints: _accessPoints,
      obstacles: _obstacles,
      densityZones: _densityZones,
      settings: _settings,
      onProgress: (progress) {
        _simulationProgress = progress.clamp(0.0, 1.0);
        notifyListeners();
      },
    );

    _simulationResult = result;
    _selectedPointMetrics = result.cells.isEmpty
        ? null
        : result.cells[result.cells.length ~/ 2].metrics;
    _isSimulating = false;
    _simulationProgress = 1;
    _statusMessage =
        'Simulation complete: ${result.summary.coverageAtMinus65.toStringAsFixed(1)}% coverage at -65 dBm.';
    notifyListeners();
  }

  Future<void> autoPlan() async {
    _isSimulating = true;
    _simulationProgress = 0.15;
    _statusMessage = 'Generating automatic AP plan...';
    notifyListeners();

    _accessPoints = await _autoPlannerEngine.suggestAccessPoints(
      floorPlan: _floorPlan,
      currentAccessPoints: _accessPoints,
      obstacles: _obstacles,
      densityZones: _densityZones,
      settings: _settings,
    );

    _draftChannel = _settings.selectedBand.recommendedChannels.first;
    _simulationProgress = 0.7;
    notifyListeners();
    await runSimulation();
  }

  Future<void> optimize() async {
    if (_simulationResult.cells.isEmpty) {
      await runSimulation();
    }

    _isSimulating = true;
    _simulationProgress = 0.2;
    _statusMessage = 'Calculating optimizer recommendations...';
    notifyListeners();

    final recommendations = await _optimizerEngine.generateRecommendations(
      floorPlan: _floorPlan,
      accessPoints: _accessPoints,
      obstacles: _obstacles,
      densityZones: _densityZones,
      settings: _settings,
      baseline: _simulationResult,
    );
    _simulationResult = SimulationResult(
      cells: _simulationResult.cells,
      summary: _simulationResult.summary,
      recommendations: recommendations,
    );
    _isSimulating = false;
    _simulationProgress = 1;
    _statusMessage = 'Generated ${recommendations.length} recommendations.';
    notifyListeners();
  }

  Future<void> applyRecommendation(
    OptimizerRecommendation recommendation,
  ) async {
    _accessPoints = _optimizerEngine.applyRecommendation(
      accessPoints: _accessPoints,
      recommendation: recommendation,
    );
    _statusMessage = 'Applied recommendation: ${recommendation.title}.';
    notifyListeners();
    await runSimulation();
    await optimize();
  }

  void removeLastObstacle() {
    if (_obstacles.isEmpty) {
      return;
    }
    _obstacles = _obstacles.sublist(0, _obstacles.length - 1);
    _statusMessage = 'Removed latest obstacle.';
    notifyListeners();
  }

  void removeLastAccessPoint() {
    if (_accessPoints.isEmpty) {
      return;
    }
    _accessPoints = _accessPoints.sublist(0, _accessPoints.length - 1);
    _statusMessage = 'Removed latest access point.';
    notifyListeners();
  }

  void _seedFromSnapshot(dashboard.PlannerSnapshot snapshot) {
    _floorPlan = const FloorPlan(
      id: 'floor-hq-2',
      name: 'HQ Level 2',
      widthMeters: 48,
      heightMeters: 30,
      floorAttenuationDb: 18,
      temperatureLossDb: 1.5,
    );
    _settings = const SimulationSettings(
      environmentPreset: EnvironmentPreset.office,
      selectedBand: FrequencyBand.band5,
      noiseFloorDbm: -92,
      enableShadowFading: true,
      shadowFadingStdDev: 2.2,
      gridColumns: 32,
      gridRows: 20,
      minUsefulRssiDbm: -82,
    );
    _draftBand = _settings.selectedBand;
    _draftTxPowerDbm = 16;
    _draftChannel = _draftBand.recommendedChannels.first;

    _accessPoints = [
      for (var index = 0; index < snapshot.accessPoints.length; index++)
        RfAccessPoint(
          id: 'seed-$index',
          name: snapshot.accessPoints[index].name,
          xMeters: snapshot.accessPoints[index].x * _floorPlan.widthMeters,
          yMeters: snapshot.accessPoints[index].y * _floorPlan.heightMeters,
          floor: _floorPlan.currentFloor,
          txPowerDbm: snapshot.accessPoints[index].powerDbm.toDouble(),
          channel: snapshot.accessPoints[index].channel,
          band: _parseBand(snapshot.accessPoints[index].band),
        ),
    ];

    _obstacles = const [
      MaterialObstacle(
        id: 'wall-1',
        name: 'North meeting wall',
        materialType: MaterialType.drywall,
        xMeters: 11,
        yMeters: 4,
        widthMeters: 18,
        heightMeters: 0.8,
        attenuationDb: 3,
      ),
      MaterialObstacle(
        id: 'wall-2',
        name: 'Concrete core',
        materialType: MaterialType.concrete,
        xMeters: 22,
        yMeters: 10,
        widthMeters: 3,
        heightMeters: 11,
        attenuationDb: 15,
      ),
      MaterialObstacle(
        id: 'wall-3',
        name: 'Glass huddle room',
        materialType: MaterialType.glass,
        xMeters: 33,
        yMeters: 6,
        widthMeters: 7,
        heightMeters: 0.8,
        attenuationDb: 2,
      ),
      MaterialObstacle(
        id: 'wall-4',
        name: 'Warehouse rack',
        materialType: MaterialType.metalRack,
        xMeters: 35,
        yMeters: 17,
        widthMeters: 2.5,
        heightMeters: 9,
        attenuationDb: 18,
      ),
    ];

    _densityZones = const [
      UserDensityZone(
        id: 'zone-1',
        name: 'Open collaboration',
        xMeters: 4,
        yMeters: 5,
        widthMeters: 14,
        heightMeters: 10,
        expectedUsers: 52,
        bandwidthPerUserMbps: 8,
      ),
      UserDensityZone(
        id: 'zone-2',
        name: 'Executive wing',
        xMeters: 25,
        yMeters: 4,
        widthMeters: 11,
        heightMeters: 9,
        expectedUsers: 24,
        bandwidthPerUserMbps: 6,
      ),
      UserDensityZone(
        id: 'zone-3',
        name: 'Warehouse edge',
        xMeters: 31,
        yMeters: 16,
        widthMeters: 13,
        heightMeters: 10,
        expectedUsers: 68,
        bandwidthPerUserMbps: 9,
      ),
    ];
  }

  FrequencyBand _parseBand(String label) {
    if (label.contains('2.4')) {
      return FrequencyBand.band24;
    }
    if (label.contains('6')) {
      return FrequencyBand.band6;
    }
    return FrequencyBand.band5;
  }

  void _addAccessPoint({required double xMeters, required double yMeters}) {
    _accessPoints = [
      ..._accessPoints,
      RfAccessPoint(
        id: 'ap-${_accessPoints.length + 1}',
        name: 'AP-${(_accessPoints.length + 1).toString().padLeft(2, '0')}',
        xMeters: _floorPlan.clampX(xMeters),
        yMeters: _floorPlan.clampY(yMeters),
        floor: _floorPlan.currentFloor,
        txPowerDbm: _draftTxPowerDbm,
        channel: _draftChannel,
        band: _draftBand,
      ),
    ];
  }

  void _addObstacle({required double xMeters, required double yMeters}) {
    final attenuation = _selectedMaterialType.defaultLossDb;
    final width = _selectedMaterialType == MaterialType.humanCluster
        ? 2.4
        : 4.2;
    final height = _selectedMaterialType == MaterialType.humanCluster
        ? 2.4
        : 0.9;
    _obstacles = [
      ..._obstacles,
      MaterialObstacle(
        id: 'obs-${_obstacles.length + 1}',
        name: _selectedMaterialType.label,
        materialType: _selectedMaterialType,
        xMeters: (_floorPlan.clampX(xMeters) - (width / 2)).clamp(
          0.0,
          _floorPlan.widthMeters - width,
        ),
        yMeters: (_floorPlan.clampY(yMeters) - (height / 2)).clamp(
          0.0,
          _floorPlan.heightMeters - height,
        ),
        widthMeters: width,
        heightMeters: height,
        attenuationDb: attenuation,
        floor: _floorPlan.currentFloor,
      ),
    ];
  }

  PointMetrics? _findMetricsAt(double xMeters, double yMeters) {
    if (_simulationResult.cells.isNotEmpty) {
      HeatmapCell? best;
      var bestDistance = double.infinity;
      for (final cell in _simulationResult.cells) {
        final dx = cell.metrics.xMeters - xMeters;
        final dy = cell.metrics.yMeters - yMeters;
        final distance = (dx * dx) + (dy * dy);
        if (distance < bestDistance) {
          best = cell;
          bestDistance = distance;
        }
      }
      if (best != null) {
        return best.metrics;
      }
    }

    return _rfEngine.computePointMetrics(
      xMeters: xMeters,
      yMeters: yMeters,
      floorPlan: _floorPlan,
      accessPoints: _accessPoints
          .where(
            (accessPoint) =>
                accessPoint.enabled &&
                accessPoint.band == _settings.selectedBand,
          )
          .toList(growable: false),
      obstacles: _obstacles,
      densityZones: _densityZones,
      settings: _settings,
    );
  }
}
