import 'package:flutter_test/flutter_test.dart';
import 'package:ibex_wifi_planner/models/access_point.dart';
import 'package:ibex_wifi_planner/models/floor_plan.dart';
import 'package:ibex_wifi_planner/models/material_obstacle.dart';
import 'package:ibex_wifi_planner/models/rf_result.dart';
import 'package:ibex_wifi_planner/models/wall_segment.dart';
import 'package:ibex_wifi_planner/models/world_point.dart';
import 'package:ibex_wifi_planner/services/floorplan_calibration_service.dart';
import 'package:ibex_wifi_planner/services/rf/rf_engine.dart';

void main() {
  const floorPlan = FloorPlan(
    id: 'test-floor',
    name: 'Test floor',
    widthMeters: 30,
    heightMeters: 20,
    imagePixelWidth: 1200,
    imagePixelHeight: 800,
    metersPerPixel: 0.025,
  );
  const settings = SimulationSettings(
    environmentPreset: EnvironmentPreset.office,
    selectedBand: FrequencyBand.band5,
    noiseFloorDbm: -92,
    enableShadowFading: false,
    shadowFadingStdDev: 0,
    gridColumns: 30,
    gridRows: 20,
    minUsefulRssiDbm: -85,
  );

  group('calibration service', () {
    test('metersPerPixel matches entered real-world distance', () {
      const service = FloorplanCalibrationService();
      final value = service.metersPerPixel(
        pointA: const Offset(100, 100),
        pointB: const Offset(300, 100),
        realDistanceMeters: 10,
      );
      final measured = service.calibratedDistanceMeters(
        pointA: const Offset(100, 100),
        pointB: const Offset(300, 100),
        metersPerPixel: value,
      );

      expect(measured, closeTo(10, 0.0001));
    });
  });

  group('rf propagation', () {
    final engine = RfEngine();
    const accessPoint = RfAccessPoint(
      id: 'ap-1',
      name: 'AP-1',
      xMeters: 10,
      yMeters: 10,
      floor: 0,
      txPowerDbm: 18,
      channel: 36,
      band: FrequencyBand.band5,
    );

    test('single AP open space has smooth circular decay', () {
      final pointA = engine.computePointMetrics(
        xMeters: 15,
        yMeters: 10,
        floorPlan: floorPlan,
        accessPoints: const [accessPoint],
        walls: const [],
        obstacles: const [],
        densityZones: const [],
        settings: settings,
      );
      final pointB = engine.computePointMetrics(
        xMeters: 10,
        yMeters: 15,
        floorPlan: floorPlan,
        accessPoints: const [accessPoint],
        walls: const [],
        obstacles: const [],
        densityZones: const [],
        settings: settings,
      );

      expect((pointA.rssiDbm - pointB.rssiDbm).abs(), lessThan(1.5));
      expect(pointA.rssiDbm, lessThan(accessPoint.txPowerDbm));
    });

    test('wall creates shadow zone', () {
      const wall = WallSegment(
        id: 'w-1',
        start: WorldPoint(xMeters: 12, yMeters: 5),
        end: WorldPoint(xMeters: 12, yMeters: 15),
        materialType: MaterialType.concrete,
        attenuationDb: 15,
      );
      final open = engine.computePointMetrics(
        xMeters: 11,
        yMeters: 10,
        floorPlan: floorPlan,
        accessPoints: const [accessPoint],
        walls: const [],
        obstacles: const [],
        densityZones: const [],
        settings: settings,
      );
      final blocked = engine.computePointMetrics(
        xMeters: 18,
        yMeters: 10,
        floorPlan: floorPlan,
        accessPoints: const [accessPoint],
        walls: const [wall],
        obstacles: const [],
        densityZones: const [],
        settings: settings,
      );

      expect(blocked.rssiDbm, lessThan(open.rssiDbm - 3));
    });

    test('same-channel overlap reduces SINR more than split channels', () {
      const ap2Same = RfAccessPoint(
        id: 'ap-2',
        name: 'AP-2',
        xMeters: 20,
        yMeters: 10,
        floor: 0,
        txPowerDbm: 18,
        channel: 36,
        band: FrequencyBand.band5,
      );
      const ap2Split = RfAccessPoint(
        id: 'ap-2b',
        name: 'AP-2B',
        xMeters: 20,
        yMeters: 10,
        floor: 0,
        txPowerDbm: 18,
        channel: 149,
        band: FrequencyBand.band5,
      );
      final same = engine.computePointMetrics(
        xMeters: 15,
        yMeters: 10,
        floorPlan: floorPlan,
        accessPoints: const [accessPoint, ap2Same],
        walls: const [],
        obstacles: const [],
        densityZones: const [],
        settings: settings,
      );
      final split = engine.computePointMetrics(
        xMeters: 15,
        yMeters: 10,
        floorPlan: floorPlan,
        accessPoints: const [accessPoint, ap2Split],
        walls: const [],
        obstacles: const [],
        densityZones: const [],
        settings: settings,
      );

      expect(same.sinrDb, lessThan(split.sinrDb));
    });

    test('higher noise floor reduces SINR', () {
      final lowNoise = engine.computePointMetrics(
        xMeters: 16,
        yMeters: 10,
        floorPlan: floorPlan,
        accessPoints: const [accessPoint],
        walls: const [],
        obstacles: const [],
        densityZones: const [],
        settings: settings.copyWith(noiseFloorDbm: -96),
      );
      final highNoise = engine.computePointMetrics(
        xMeters: 16,
        yMeters: 10,
        floorPlan: floorPlan,
        accessPoints: const [accessPoint],
        walls: const [],
        obstacles: const [],
        densityZones: const [],
        settings: settings.copyWith(noiseFloorDbm: -84),
      );

      expect(highNoise.sinrDb, lessThan(lowNoise.sinrDb));
    });
  });
}
