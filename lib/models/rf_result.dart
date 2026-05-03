import 'access_point.dart';
import 'world_point.dart';

enum EnvironmentPreset { openSpace, office, denseOffice, warehouse }

enum HeatmapType { rssi, snr, sinr, throughput, interference }

enum RecommendationType {
  reduceTxPower,
  increaseTxPower,
  moveAp,
  changeChannel,
  addAp,
  overloadedAp,
}

class SimulationSettings {
  const SimulationSettings({
    required this.environmentPreset,
    required this.selectedBand,
    required this.noiseFloorDbm,
    required this.enableShadowFading,
    required this.shadowFadingStdDev,
    required this.gridColumns,
    required this.gridRows,
    required this.minUsefulRssiDbm,
  });

  final EnvironmentPreset environmentPreset;
  final FrequencyBand selectedBand;
  final double noiseFloorDbm;
  final bool enableShadowFading;
  final double shadowFadingStdDev;
  final int gridColumns;
  final int gridRows;
  final double minUsefulRssiDbm;

  SimulationSettings copyWith({
    EnvironmentPreset? environmentPreset,
    FrequencyBand? selectedBand,
    double? noiseFloorDbm,
    bool? enableShadowFading,
    double? shadowFadingStdDev,
    int? gridColumns,
    int? gridRows,
    double? minUsefulRssiDbm,
  }) {
    return SimulationSettings(
      environmentPreset: environmentPreset ?? this.environmentPreset,
      selectedBand: selectedBand ?? this.selectedBand,
      noiseFloorDbm: noiseFloorDbm ?? this.noiseFloorDbm,
      enableShadowFading: enableShadowFading ?? this.enableShadowFading,
      shadowFadingStdDev: shadowFadingStdDev ?? this.shadowFadingStdDev,
      gridColumns: gridColumns ?? this.gridColumns,
      gridRows: gridRows ?? this.gridRows,
      minUsefulRssiDbm: minUsefulRssiDbm ?? this.minUsefulRssiDbm,
    );
  }
}

class PointMetrics {
  const PointMetrics({
    required this.xMeters,
    required this.yMeters,
    required this.rssiDbm,
    required this.snrDb,
    required this.sinrDb,
    required this.interferenceDb,
    required this.throughputMbps,
    required this.bestServingApId,
    required this.airtimeUtilization,
    required this.isOverloaded,
  });

  final double xMeters;
  final double yMeters;
  final double rssiDbm;
  final double snrDb;
  final double sinrDb;
  final double interferenceDb;
  final double throughputMbps;
  final String? bestServingApId;
  final double airtimeUtilization;
  final bool isOverloaded;

  PointMetrics copyWith({
    double? rssiDbm,
    double? snrDb,
    double? sinrDb,
    double? interferenceDb,
    double? throughputMbps,
    String? bestServingApId,
    double? airtimeUtilization,
    bool? isOverloaded,
  }) {
    return PointMetrics(
      xMeters: xMeters,
      yMeters: yMeters,
      rssiDbm: rssiDbm ?? this.rssiDbm,
      snrDb: snrDb ?? this.snrDb,
      sinrDb: sinrDb ?? this.sinrDb,
      interferenceDb: interferenceDb ?? this.interferenceDb,
      throughputMbps: throughputMbps ?? this.throughputMbps,
      bestServingApId: bestServingApId ?? this.bestServingApId,
      airtimeUtilization: airtimeUtilization ?? this.airtimeUtilization,
      isOverloaded: isOverloaded ?? this.isOverloaded,
    );
  }

  static PointMetrics at(double x, double y) {
    return PointMetrics(
      xMeters: x,
      yMeters: y,
      rssiDbm: -120,
      snrDb: 0,
      sinrDb: 0,
      interferenceDb: -120,
      throughputMbps: 0,
      bestServingApId: null,
      airtimeUtilization: 0,
      isOverloaded: false,
    );
  }

  WorldPoint get worldPoint => WorldPoint(xMeters: xMeters, yMeters: yMeters);
}

class HeatmapCell {
  const HeatmapCell({
    required this.column,
    required this.row,
    required this.metrics,
  });

  final int column;
  final int row;
  final PointMetrics metrics;
}

class OverloadedAccessPoint {
  const OverloadedAccessPoint({
    required this.accessPointId,
    required this.airtimeUtilization,
    required this.throughputMbps,
    required this.estimatedClients,
  });

  final String accessPointId;
  final double airtimeUtilization;
  final double throughputMbps;
  final int estimatedClients;
}

class OptimizerRecommendation {
  const OptimizerRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.impactSummary,
    this.targetAccessPointId,
    this.suggestedAccessPoint,
    this.suggestedChannel,
    this.suggestedTxPowerDbm,
  });

  final String id;
  final RecommendationType type;
  final String title;
  final String description;
  final String impactSummary;
  final String? targetAccessPointId;
  final RfAccessPoint? suggestedAccessPoint;
  final int? suggestedChannel;
  final double? suggestedTxPowerDbm;
}

class SimulationSummary {
  const SimulationSummary({
    required this.coverageAtMinus65,
    required this.averageSnr,
    required this.averageSinr,
    required this.averageThroughputMbps,
    required this.overloadedAccessPoints,
  });

  final double coverageAtMinus65;
  final double averageSnr;
  final double averageSinr;
  final double averageThroughputMbps;
  final List<OverloadedAccessPoint> overloadedAccessPoints;

  SimulationSummary copyWith({
    double? coverageAtMinus65,
    double? averageSnr,
    double? averageSinr,
    double? averageThroughputMbps,
    List<OverloadedAccessPoint>? overloadedAccessPoints,
  }) {
    return SimulationSummary(
      coverageAtMinus65: coverageAtMinus65 ?? this.coverageAtMinus65,
      averageSnr: averageSnr ?? this.averageSnr,
      averageSinr: averageSinr ?? this.averageSinr,
      averageThroughputMbps:
          averageThroughputMbps ?? this.averageThroughputMbps,
      overloadedAccessPoints:
          overloadedAccessPoints ?? this.overloadedAccessPoints,
    );
  }
}

class SimulationResult {
  const SimulationResult({
    required this.cells,
    required this.summary,
    required this.recommendations,
    this.validationResults = const [],
  });

  final List<HeatmapCell> cells;
  final SimulationSummary summary;
  final List<OptimizerRecommendation> recommendations;
  final List<ValidationScenarioResult> validationResults;

  static const empty = SimulationResult(
    cells: [],
    summary: SimulationSummary(
      coverageAtMinus65: 0,
      averageSnr: 0,
      averageSinr: 0,
      averageThroughputMbps: 0,
      overloadedAccessPoints: [],
    ),
    recommendations: [],
    validationResults: [],
  );
}

class ValidationScenarioResult {
  const ValidationScenarioResult({
    required this.title,
    required this.passed,
    required this.details,
  });

  final String title;
  final bool passed;
  final String details;
}
