import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/access_point.dart';
import '../models/floor_plan.dart';
import '../models/material_obstacle.dart' as obstacle_model;
import '../models/planner_models.dart' as dashboard;
import '../models/rf_result.dart';
import '../models/user_density.dart';
import '../models/wall_segment.dart';
import '../models/world_point.dart';
import '../services/coordinate_transformer.dart';
import '../services/floorplan_calibration_service.dart';
import '../services/rf/auto_planner_engine.dart';
import '../services/rf/optimizer_engine.dart';
import '../services/rf/rf_engine.dart';
import '../services/rf/rf_validation_service.dart';
import '../services/wall_geometry_service.dart';

enum PlannerInteractionMode {
  inspect,
  placeAp,
  calibrate,
  drawWall,
  deleteWall,
}

class RfPlannerController extends ChangeNotifier {
  RfPlannerController({
    required dashboard.PlannerSnapshot snapshot,
    RfEngine? rfEngine,
    AutoPlannerEngine? autoPlannerEngine,
    OptimizerEngine? optimizerEngine,
    CoordinateTransformer? coordinateTransformer,
    FloorplanCalibrationService? calibrationService,
    WallGeometryService? wallGeometryService,
    RfValidationService? validationService,
  }) : _rfEngine = rfEngine ?? RfEngine(),
       _autoPlannerEngine = autoPlannerEngine ?? AutoPlannerEngine(),
       _optimizerEngine = optimizerEngine ?? OptimizerEngine(),
       _coordinateTransformer =
           coordinateTransformer ?? const CoordinateTransformer(),
       _calibrationService =
           calibrationService ?? const FloorplanCalibrationService(),
       _wallGeometryService =
           wallGeometryService ?? const WallGeometryService(),
       _validationService = validationService ?? RfValidationService() {
    transformationController.addListener(_handleTransformChange);
    _seedFromSnapshot(snapshot);
  }

  final RfEngine _rfEngine;
  final AutoPlannerEngine _autoPlannerEngine;
  final OptimizerEngine _optimizerEngine;
  final CoordinateTransformer _coordinateTransformer;
  final FloorplanCalibrationService _calibrationService;
  final WallGeometryService _wallGeometryService;
  final RfValidationService _validationService;

  final TransformationController transformationController =
      TransformationController();

  late FloorPlan _floorPlan;
  late SimulationSettings _settings;
  HeatmapType _heatmapType = HeatmapType.rssi;
  PlannerInteractionMode _interactionMode = PlannerInteractionMode.inspect;
  obstacle_model.MaterialType _selectedMaterialType =
      obstacle_model.MaterialType.drywall;
  late double _draftTxPowerDbm;
  late int _draftChannel;
  late FrequencyBand _draftBand;
  List<RfAccessPoint> _accessPoints = const [];
  List<obstacle_model.MaterialObstacle> _obstacles = const [];
  List<UserDensityZone> _densityZones = const [];
  List<WallSegment> _walls = const [];
  SimulationResult _simulationResult = SimulationResult.empty;
  PointMetrics? _selectedPointMetrics;
  List<ValidationScenarioResult> _validationResults = const [];
  WorldPoint? _pendingWallStart;
  WorldPoint? _hoverWorldPoint;
  Offset? _calibrationPointA;
  Offset? _calibrationPointB;
  String _calibrationDistanceMeters = '10';
  bool _isSimulating = false;
  bool _isUploadingFloorPlan = false;
  double _simulationProgress = 0;
  String _statusMessage = 'Ready to simulate.';
  Size _viewerSize = Size.zero;
  bool _hasInitializedTransform = false;
  bool _hasUserAdjustedView = false;

  FloorPlan get floorPlan => _floorPlan;
  SimulationSettings get settings => _settings;
  HeatmapType get heatmapType => _heatmapType;
  PlannerInteractionMode get interactionMode => _interactionMode;
  obstacle_model.MaterialType get selectedMaterialType => _selectedMaterialType;
  double get draftTxPowerDbm => _draftTxPowerDbm;
  int get draftChannel => _draftChannel;
  FrequencyBand get draftBand => _draftBand;
  List<RfAccessPoint> get accessPoints => List.unmodifiable(_accessPoints);
  List<obstacle_model.MaterialObstacle> get obstacles =>
      List.unmodifiable(_obstacles);
  List<UserDensityZone> get densityZones => List.unmodifiable(_densityZones);
  List<WallSegment> get walls => List.unmodifiable(_walls);
  SimulationResult get simulationResult => _simulationResult;
  PointMetrics? get selectedPointMetrics => _selectedPointMetrics;
  List<ValidationScenarioResult> get validationResults =>
      List.unmodifiable(_validationResults);
  bool get isSimulating => _isSimulating;
  bool get isUploadingFloorPlan => _isUploadingFloorPlan;
  double get simulationProgress => _simulationProgress;
  String get statusMessage => _statusMessage;
  List<OptimizerRecommendation> get recommendations =>
      _simulationResult.recommendations;
  WorldPoint? get pendingWallStart => _pendingWallStart;
  WorldPoint? get hoverWorldPoint => _hoverWorldPoint;
  Offset? get calibrationPointA => _calibrationPointA;
  Offset? get calibrationPointB => _calibrationPointB;
  String get calibrationDistanceMeters => _calibrationDistanceMeters;
  bool get canApplyCalibration =>
      _calibrationPointA != null &&
      _calibrationPointB != null &&
      double.tryParse(_calibrationDistanceMeters) != null &&
      (double.tryParse(_calibrationDistanceMeters) ?? 0) > 0;

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
    final safeColumns = columns.clamp(18, 72);
    _settings = _settings.copyWith(
      gridColumns: safeColumns,
      gridRows:
          (safeColumns * (_floorPlan.heightMeters / _floorPlan.widthMeters))
              .round()
              .clamp(12, 60),
    );
    notifyListeners();
  }

  void updateInteractionMode(PlannerInteractionMode mode) {
    _interactionMode = mode;
    if (mode != PlannerInteractionMode.drawWall) {
      _pendingWallStart = null;
    }
    notifyListeners();
  }

  void updateSelectedMaterialType(obstacle_model.MaterialType type) {
    _selectedMaterialType = type;
    notifyListeners();
  }

  void updateCalibrationDistance(String value) {
    _calibrationDistanceMeters = value;
    notifyListeners();
  }

  void updateViewerSize(Size size) {
    if (size == _viewerSize) {
      return;
    }
    _viewerSize = size;
    if (!_hasInitializedTransform || !_hasUserAdjustedView) {
      fitFloorPlanToViewport();
    }
  }

  void fitFloorPlanToViewport() {
    if (_viewerSize.width <= 0 || _viewerSize.height <= 0) {
      return;
    }
    transformationController.value = _coordinateTransformer.initialFitTransform(
      viewportSize: _viewerSize,
      floorPlan: _floorPlan,
    );
    _hasInitializedTransform = true;
    _hasUserAdjustedView = false;
    notifyListeners();
  }

  Future<void> uploadFloorPlan() async {
    _isUploadingFloorPlan = true;
    _statusMessage = 'Selecting floor plan...';
    notifyListeners();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
      withData: true,
    );

    if (result == null ||
        result.files.isEmpty ||
        result.files.first.bytes == null) {
      _isUploadingFloorPlan = false;
      _statusMessage = 'Floor plan selection cancelled.';
      notifyListeners();
      return;
    }

    final file = result.files.first;
    final bytes = file.bytes!;
    final extension = (file.extension ?? '').toLowerCase();

    if (extension == 'pdf') {
      _floorPlan = _floorPlan.copyWith(
        imageBytes: bytes,
        sourceName: file.name,
        sourceType: FloorPlanSourceType.pdf,
      );
      _statusMessage =
          'PDF source stored safely. Upload a PNG/JPG floor plan image for full calibration and overlay rendering in this build.';
      _isUploadingFloorPlan = false;
      _resetSimulationArtifacts();
      notifyListeners();
      return;
    }

    final dimensions = await _decodeImageDimensions(bytes);
    final metersPerPixel = _floorPlan.metersPerPixel;
    _floorPlan = _floorPlan.copyWith(
      imageBytes: bytes,
      sourceName: file.name,
      sourceType: FloorPlanSourceType.image,
      imagePixelWidth: dimensions.width,
      imagePixelHeight: dimensions.height,
      widthMeters: dimensions.width * metersPerPixel,
      heightMeters: dimensions.height * metersPerPixel,
    );
    _statusMessage =
        'Loaded ${file.name}. Calibrate two points to align screen pixels to real meters.';
    _isUploadingFloorPlan = false;
    _calibrationPointA = null;
    _calibrationPointB = null;
    _hasInitializedTransform = false;
    _hasUserAdjustedView = false;
    _resetSimulationArtifacts();
    notifyListeners();
  }

  Future<void> handleViewerTap({required Offset screenPosition}) async {
    final imagePoint = _coordinateTransformer.screenToImagePixel(
      screenPoint: screenPosition,
      transform: transformationController.value,
    );
    if (!_isInsideImageBounds(imagePoint)) {
      return;
    }

    switch (_interactionMode) {
      case PlannerInteractionMode.inspect:
        final worldPoint = _coordinateTransformer.imagePixelToWorld(
          imagePoint,
          _floorPlan,
        );
        _selectedPointMetrics = _findMetricsAt(worldPoint);
        _statusMessage =
            'Inspecting ${worldPoint.xMeters.toStringAsFixed(2)}m, ${worldPoint.yMeters.toStringAsFixed(2)}m.';
        notifyListeners();
        return;
      case PlannerInteractionMode.placeAp:
        final worldPoint = _coordinateTransformer.imagePixelToWorld(
          imagePoint,
          _floorPlan,
        );
        _addAccessPoint(worldPoint);
        _statusMessage =
            'Placed AP at ${worldPoint.xMeters.toStringAsFixed(2)}m, ${worldPoint.yMeters.toStringAsFixed(2)}m.';
        notifyListeners();
        return;
      case PlannerInteractionMode.calibrate:
        if (_calibrationPointA == null) {
          _calibrationPointA = imagePoint;
          _statusMessage = 'Calibration point A captured.';
        } else if (_calibrationPointB == null) {
          _calibrationPointB = imagePoint;
          _statusMessage =
              'Calibration point B captured. Enter the real-world distance and apply calibration.';
        } else {
          _calibrationPointA = imagePoint;
          _calibrationPointB = null;
          _statusMessage = 'Calibration restarted from point A.';
        }
        notifyListeners();
        return;
      case PlannerInteractionMode.drawWall:
        final worldPoint = _coordinateTransformer.imagePixelToWorld(
          imagePoint,
          _floorPlan,
        );
        if (_pendingWallStart == null) {
          _pendingWallStart = worldPoint;
          _statusMessage = 'Wall start selected.';
          notifyListeners();
          return;
        }
        final snapped = _wallGeometryService.snapPoint(
          _pendingWallStart!,
          worldPoint,
        );
        final candidate = WallSegment(
          id: 'wall-${_walls.length + 1}',
          start: _pendingWallStart!,
          end: snapped,
          materialType: _selectedMaterialType,
          attenuationDb: _selectedMaterialType.defaultLossDb,
          floor: _floorPlan.currentFloor,
        );
        if (candidate.lengthMeters < 0.3) {
          _pendingWallStart = null;
          _statusMessage = 'Wall ignored because it is too short.';
          notifyListeners();
          return;
        }
        if (_wallGeometryService.isDuplicateOrOverlapping(
          candidate: candidate,
          existing: _walls,
        )) {
          _pendingWallStart = null;
          _statusMessage = 'Duplicate or overlapping wall prevented.';
          notifyListeners();
          return;
        }
        _walls = [..._walls, candidate];
        _pendingWallStart = null;
        _statusMessage =
            'Wall added with ${candidate.attenuationDb.toStringAsFixed(1)} dB attenuation.';
        notifyListeners();
        return;
      case PlannerInteractionMode.deleteWall:
        final worldPoint = _coordinateTransformer.imagePixelToWorld(
          imagePoint,
          _floorPlan,
        );
        final index = _wallGeometryService.findWallIndexNearPoint(
          point: worldPoint,
          walls: _walls,
          toleranceMeters: _floorPlan.metersPerPixel * 16,
        );
        if (index == null) {
          _statusMessage = 'No wall found near tap point.';
          notifyListeners();
          return;
        }
        final updatedWalls = List<WallSegment>.from(_walls)..removeAt(index);
        _walls = updatedWalls;
        _statusMessage = 'Wall deleted.';
        notifyListeners();
        return;
    }
  }

  void clearCalibrationSelection() {
    _calibrationPointA = null;
    _calibrationPointB = null;
    notifyListeners();
  }

  void updateHoverScreenPosition(Offset? screenPosition) {
    if (screenPosition == null) {
      if (_hoverWorldPoint != null) {
        _hoverWorldPoint = null;
        notifyListeners();
      }
      return;
    }

    final worldPoint = _coordinateTransformer.screenToWorld(
      screenPoint: screenPosition,
      transform: transformationController.value,
      floorPlan: _floorPlan,
    );
    _hoverWorldPoint = worldPoint;
    notifyListeners();
  }

  void applyCalibration() {
    if (!canApplyCalibration) {
      _statusMessage =
          'Select two calibration points and enter a valid distance.';
      notifyListeners();
      return;
    }

    final newMetersPerPixel = _calibrationService.metersPerPixel(
      pointA: _calibrationPointA!,
      pointB: _calibrationPointB!,
      realDistanceMeters: double.parse(_calibrationDistanceMeters),
    );
    if (newMetersPerPixel <= 0) {
      _statusMessage =
          'Calibration failed because the selected points are invalid.';
      notifyListeners();
      return;
    }

    final previous = _floorPlan.metersPerPixel;
    final ratio = previous <= 0 ? 1.0 : newMetersPerPixel / previous;

    _accessPoints = [
      for (final accessPoint in _accessPoints)
        accessPoint.copyWith(
          xMeters: accessPoint.xMeters * ratio,
          yMeters: accessPoint.yMeters * ratio,
        ),
    ];
    _walls = [
      for (final wall in _walls)
        wall.copyWith(
          start: wall.start.scale(ratio),
          end: wall.end.scale(ratio),
        ),
    ];
    _obstacles = [
      for (final obstacle in _obstacles)
        obstacle.copyWith(
          xMeters: obstacle.xMeters * ratio,
          yMeters: obstacle.yMeters * ratio,
          widthMeters: obstacle.widthMeters * ratio,
          heightMeters: obstacle.heightMeters * ratio,
        ),
    ];
    _densityZones = [
      for (final zone in _densityZones)
        UserDensityZone(
          id: zone.id,
          name: zone.name,
          xMeters: zone.xMeters * ratio,
          yMeters: zone.yMeters * ratio,
          widthMeters: zone.widthMeters * ratio,
          heightMeters: zone.heightMeters * ratio,
          expectedUsers: zone.expectedUsers,
          bandwidthPerUserMbps: zone.bandwidthPerUserMbps,
          floor: zone.floor,
        ),
    ];
    _floorPlan = _floorPlan.copyWith(
      metersPerPixel: newMetersPerPixel,
      widthMeters: _floorPlan.imagePixelWidth * newMetersPerPixel,
      heightMeters: _floorPlan.imagePixelHeight * newMetersPerPixel,
    );
    _statusMessage =
        'Calibration applied at ${newMetersPerPixel.toStringAsFixed(5)} meters/pixel.';
    _calibrationPointA = null;
    _calibrationPointB = null;
    _simulationResult = SimulationResult.empty;
    notifyListeners();
  }

  Future<void> runSimulation() async {
    _isSimulating = true;
    _simulationProgress = 0;
    _statusMessage = 'Running ${_settings.selectedBand.label} simulation...';
    notifyListeners();

    final result = await _rfEngine.simulate(
      floorPlan: _floorPlan,
      accessPoints: _accessPoints,
      walls: _walls,
      obstacles: _obstacles,
      densityZones: _densityZones,
      settings: _settings,
      onProgress: (progress) {
        _simulationProgress = progress.clamp(0.0, 1.0);
        notifyListeners();
      },
    );

    _validationResults = await _validationService.run(settings: _settings);
    _simulationResult = SimulationResult(
      cells: result.cells,
      summary: result.summary,
      recommendations: result.recommendations,
      validationResults: _validationResults,
    );
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
      walls: _walls,
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
      walls: _walls,
      obstacles: _obstacles,
      densityZones: _densityZones,
      settings: _settings,
      baseline: _simulationResult,
    );
    _simulationResult = SimulationResult(
      cells: _simulationResult.cells,
      summary: _simulationResult.summary,
      recommendations: recommendations,
      validationResults: _validationResults,
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

  Future<void> runValidationSuite() async {
    _validationResults = await _validationService.run(settings: _settings);
    _simulationResult = SimulationResult(
      cells: _simulationResult.cells,
      summary: _simulationResult.summary,
      recommendations: _simulationResult.recommendations,
      validationResults: _validationResults,
    );
    _statusMessage = 'Validation suite completed.';
    notifyListeners();
  }

  void undoLastWall() {
    if (_walls.isEmpty) {
      return;
    }
    _walls = _walls.sublist(0, _walls.length - 1);
    _statusMessage = 'Removed latest wall.';
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

  PointMetrics? metricsForWorldPoint(WorldPoint point) => _findMetricsAt(point);

  void _seedFromSnapshot(dashboard.PlannerSnapshot snapshot) {
    const metersPerPixel = 0.03;
    _floorPlan = const FloorPlan(
      id: 'floor-hq-2',
      name: 'HQ Level 2',
      widthMeters: 48,
      heightMeters: 30,
      imagePixelWidth: 1600,
      imagePixelHeight: 1000,
      metersPerPixel: metersPerPixel,
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

    _walls = const [
      WallSegment(
        id: 'wall-1',
        start: WorldPoint(xMeters: 11, yMeters: 4),
        end: WorldPoint(xMeters: 29, yMeters: 4),
        materialType: obstacle_model.MaterialType.drywall,
        attenuationDb: 3,
      ),
      WallSegment(
        id: 'wall-2',
        start: WorldPoint(xMeters: 22, yMeters: 10),
        end: WorldPoint(xMeters: 22, yMeters: 21),
        materialType: obstacle_model.MaterialType.concrete,
        attenuationDb: 15,
      ),
      WallSegment(
        id: 'wall-3',
        start: WorldPoint(xMeters: 33, yMeters: 6),
        end: WorldPoint(xMeters: 40, yMeters: 6),
        materialType: obstacle_model.MaterialType.glass,
        attenuationDb: 2,
      ),
      WallSegment(
        id: 'wall-4',
        start: WorldPoint(xMeters: 35, yMeters: 17),
        end: WorldPoint(xMeters: 37.5, yMeters: 26),
        materialType: obstacle_model.MaterialType.metalRack,
        attenuationDb: 18,
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

  void _addAccessPoint(WorldPoint worldPoint) {
    _accessPoints = [
      ..._accessPoints,
      RfAccessPoint(
        id: 'ap-${_accessPoints.length + 1}',
        name: 'AP-${(_accessPoints.length + 1).toString().padLeft(2, '0')}',
        xMeters: _floorPlan.clampX(worldPoint.xMeters),
        yMeters: _floorPlan.clampY(worldPoint.yMeters),
        floor: _floorPlan.currentFloor,
        txPowerDbm: _draftTxPowerDbm,
        channel: _draftChannel,
        band: _draftBand,
      ),
    ];
  }

  PointMetrics? _findMetricsAt(WorldPoint worldPoint) {
    if (_simulationResult.cells.isNotEmpty) {
      HeatmapCell? best;
      var bestDistance = double.infinity;
      for (final cell in _simulationResult.cells) {
        final distance = cell.metrics.worldPoint.distanceTo(worldPoint);
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
      xMeters: worldPoint.xMeters,
      yMeters: worldPoint.yMeters,
      floorPlan: _floorPlan,
      accessPoints: _accessPoints
          .where(
            (accessPoint) =>
                accessPoint.enabled &&
                accessPoint.band == _settings.selectedBand,
          )
          .toList(growable: false),
      walls: _walls,
      obstacles: _obstacles,
      densityZones: _densityZones,
      settings: _settings,
    );
  }

  bool _isInsideImageBounds(Offset point) {
    return point.dx >= 0 &&
        point.dy >= 0 &&
        point.dx <= _floorPlan.imagePixelWidth &&
        point.dy <= _floorPlan.imagePixelHeight;
  }

  void _resetSimulationArtifacts() {
    _simulationResult = SimulationResult.empty;
    _validationResults = const [];
    _selectedPointMetrics = null;
  }

  Future<_ImageDimensions> _decodeImageDimensions(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return _ImageDimensions(
      width: frame.image.width,
      height: frame.image.height,
    );
  }

  void _handleTransformChange() {
    if (_hasInitializedTransform) {
      _hasUserAdjustedView = true;
    }
  }

  @override
  void dispose() {
    transformationController.removeListener(_handleTransformChange);
    transformationController.dispose();
    super.dispose();
  }
}

class _ImageDimensions {
  const _ImageDimensions({required this.width, required this.height});

  final int width;
  final int height;
}
