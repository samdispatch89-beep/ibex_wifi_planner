class UserDensityZone {
  const UserDensityZone({
    required this.id,
    required this.name,
    required this.xMeters,
    required this.yMeters,
    required this.widthMeters,
    required this.heightMeters,
    required this.expectedUsers,
    required this.bandwidthPerUserMbps,
    this.floor = 0,
  });

  final String id;
  final String name;
  final double xMeters;
  final double yMeters;
  final double widthMeters;
  final double heightMeters;
  final int expectedUsers;
  final double bandwidthPerUserMbps;
  final int floor;

  double get right => xMeters + widthMeters;
  double get bottom => yMeters + heightMeters;
  double get areaSqMeters => widthMeters * heightMeters;
  double get demandMbps => expectedUsers * bandwidthPerUserMbps;

  bool contains(double x, double y) {
    return x >= xMeters && x <= right && y >= yMeters && y <= bottom;
  }
}
