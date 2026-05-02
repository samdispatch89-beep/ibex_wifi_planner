import 'dart:math' as math;

import '../../models/access_point.dart';

class InterferenceEngine {
  const InterferenceEngine();

  double calculateInterferenceDbm({
    required RfAccessPoint bestAccessPoint,
    required Map<RfAccessPoint, double> receivedSignalsDbm,
  }) {
    var interferenceMilliwatts = 0.0;

    receivedSignalsDbm.forEach((accessPoint, signalDbm) {
      if (accessPoint.id == bestAccessPoint.id) {
        return;
      }

      final weight = _channelOverlapWeight(bestAccessPoint, accessPoint);
      if (weight <= 0) {
        return;
      }

      interferenceMilliwatts += _dbmToMilliwatts(signalDbm) * weight;
    });

    if (interferenceMilliwatts <= 0) {
      return -120;
    }

    return _milliwattsToDbm(interferenceMilliwatts);
  }

  double calculateSinrDb({
    required double signalDbm,
    required double interferenceDbm,
    required double noiseFloorDbm,
  }) {
    final signalMw = _dbmToMilliwatts(signalDbm);
    final interferenceMw = _dbmToMilliwatts(interferenceDbm);
    final noiseMw = _dbmToMilliwatts(noiseFloorDbm);
    final denominator = interferenceMw + noiseMw;
    if (denominator <= 0 || signalMw <= 0) {
      return 0;
    }

    return 10 * math.log(signalMw / denominator) / math.ln10;
  }

  double _channelOverlapWeight(RfAccessPoint serving, RfAccessPoint other) {
    if (serving.band != other.band) {
      return 0;
    }

    final difference = (serving.channel - other.channel).abs();
    if (difference == 0) {
      return 1.0;
    }

    switch (serving.band) {
      case FrequencyBand.band24:
        if (difference >= 5) {
          return 0;
        }
        return switch (difference) {
          1 => 0.65,
          2 => 0.45,
          3 => 0.3,
          4 => 0.15,
          _ => 0,
        };
      case FrequencyBand.band5:
      case FrequencyBand.band6:
        return difference <= 4 ? 0.18 : 0;
    }
  }

  double _dbmToMilliwatts(double dbm) => math.pow(10, dbm / 10).toDouble();

  double _milliwattsToDbm(double value) {
    if (value <= 0) {
      return -120;
    }

    return 10 * math.log(value) / math.ln10;
  }
}
