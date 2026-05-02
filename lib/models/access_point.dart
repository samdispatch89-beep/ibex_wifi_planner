enum FrequencyBand { band24, band5, band6 }

enum AntennaPattern { omnidirectional, directional }

extension FrequencyBandX on FrequencyBand {
  String get label {
    switch (this) {
      case FrequencyBand.band24:
        return '2.4 GHz';
      case FrequencyBand.band5:
        return '5 GHz';
      case FrequencyBand.band6:
        return '6 GHz';
    }
  }

  double get frequencyMhz {
    switch (this) {
      case FrequencyBand.band24:
        return 2437;
      case FrequencyBand.band5:
        return 5180;
      case FrequencyBand.band6:
        return 5975;
    }
  }

  List<int> get recommendedChannels {
    switch (this) {
      case FrequencyBand.band24:
        return const [1, 6, 11];
      case FrequencyBand.band5:
        return const [36, 40, 44, 48, 149, 153, 157, 161];
      case FrequencyBand.band6:
        return const [5, 21, 37, 53, 69, 85, 101, 117, 133, 149, 165, 181];
    }
  }
}

class RfAccessPoint {
  const RfAccessPoint({
    required this.id,
    required this.name,
    required this.xMeters,
    required this.yMeters,
    required this.floor,
    required this.txPowerDbm,
    required this.channel,
    required this.band,
    this.antennaPattern = AntennaPattern.omnidirectional,
    this.antennaGainDbi = 3,
    this.azimuthDegrees = 0,
    this.enabled = true,
    this.maxClients = 45,
  });

  final String id;
  final String name;
  final double xMeters;
  final double yMeters;
  final int floor;
  final double txPowerDbm;
  final int channel;
  final FrequencyBand band;
  final AntennaPattern antennaPattern;
  final double antennaGainDbi;
  final double azimuthDegrees;
  final bool enabled;
  final int maxClients;

  double get frequencyMhz => band.frequencyMhz;

  RfAccessPoint copyWith({
    String? id,
    String? name,
    double? xMeters,
    double? yMeters,
    int? floor,
    double? txPowerDbm,
    int? channel,
    FrequencyBand? band,
    AntennaPattern? antennaPattern,
    double? antennaGainDbi,
    double? azimuthDegrees,
    bool? enabled,
    int? maxClients,
  }) {
    return RfAccessPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      xMeters: xMeters ?? this.xMeters,
      yMeters: yMeters ?? this.yMeters,
      floor: floor ?? this.floor,
      txPowerDbm: txPowerDbm ?? this.txPowerDbm,
      channel: channel ?? this.channel,
      band: band ?? this.band,
      antennaPattern: antennaPattern ?? this.antennaPattern,
      antennaGainDbi: antennaGainDbi ?? this.antennaGainDbi,
      azimuthDegrees: azimuthDegrees ?? this.azimuthDegrees,
      enabled: enabled ?? this.enabled,
      maxClients: maxClients ?? this.maxClients,
    );
  }
}
