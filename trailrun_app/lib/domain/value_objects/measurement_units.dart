/// Distance measurement value object
class Distance {
  const Distance._(this._meters);

  final double _meters;

  /// Create distance from meters
  factory Distance.meters(double meters) => Distance._(meters);

  /// Create distance from kilometers
  factory Distance.kilometers(double kilometers) => Distance._(kilometers * 1000);

  /// Create distance from miles
  factory Distance.miles(double miles) => Distance._(miles * 1609.344);

  /// Create distance from feet
  factory Distance.feet(double feet) => Distance._(feet * 0.3048);

  /// Get distance in meters
  double get meters => _meters;

  /// Get distance in kilometers
  double get kilometers => _meters / 1000;

  /// Get distance in miles
  double get miles => _meters / 1609.344;

  /// Get distance in feet
  double get feet => _meters / 0.3048;

  /// Add two distances
  Distance operator +(Distance other) => Distance._(_meters + other._meters);

  /// Subtract two distances
  Distance operator -(Distance other) => Distance._(_meters - other._meters);

  /// Multiply distance by scalar
  Distance operator *(double scalar) => Distance._(_meters * scalar);

  /// Divide distance by scalar
  Distance operator /(double scalar) => Distance._(_meters / scalar);

  /// Compare distances
  bool operator >(Distance other) => _meters > other._meters;
  bool operator <(Distance other) => _meters < other._meters;
  bool operator >=(Distance other) => _meters >= other._meters;
  bool operator <=(Distance other) => _meters <= other._meters;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Distance &&
          runtimeType == other.runtimeType &&
          _meters == other._meters;

  @override
  int get hashCode => _meters.hashCode;

  @override
  String toString() => 'Distance(${_meters}m)';
}

/// Pace measurement value object (time per distance)
class Pace {
  const Pace._(this._secondsPerKilometer);

  final double _secondsPerKilometer;

  /// Create pace from seconds per kilometer
  factory Pace.secondsPerKilometer(double seconds) => Pace._(seconds);

  /// Create pace from minutes per kilometer
  factory Pace.minutesPerKilometer(double minutes) => Pace._(minutes * 60);

  /// Create pace from seconds per mile
  factory Pace.secondsPerMile(double seconds) => Pace._(seconds / 1.609344);

  /// Create pace from minutes per mile
  factory Pace.minutesPerMile(double minutes) => Pace._(minutes * 60 / 1.609344);

  /// Create pace from distance and duration
  factory Pace.fromDistanceAndDuration(Distance distance, Duration duration) {
    final double kilometers = distance.kilometers;
    final double seconds = duration.inMilliseconds / 1000.0;
    return Pace._(seconds / kilometers);
  }

  /// Get pace in seconds per kilometer
  double get secondsPerKilometer => _secondsPerKilometer;

  /// Get pace in minutes per kilometer
  double get minutesPerKilometer => _secondsPerKilometer / 60;

  /// Get pace in seconds per mile
  double get secondsPerMile => _secondsPerKilometer * 1.609344;

  /// Get pace in minutes per mile
  double get minutesPerMile => _secondsPerKilometer * 1.609344 / 60;

  /// Format pace as MM:SS per kilometer
  String formatMinutesSeconds() {
    final int minutes = (_secondsPerKilometer / 60).floor();
    final int seconds = (_secondsPerKilometer % 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pace &&
          runtimeType == other.runtimeType &&
          _secondsPerKilometer == other._secondsPerKilometer;

  @override
  int get hashCode => _secondsPerKilometer.hashCode;

  @override
  String toString() => 'Pace(${formatMinutesSeconds()}/km)';
}

/// Elevation measurement value object
class Elevation {
  const Elevation._(this._meters);

  final double _meters;

  /// Create elevation from meters
  factory Elevation.meters(double meters) => Elevation._(meters);

  /// Create elevation from feet
  factory Elevation.feet(double feet) => Elevation._(feet * 0.3048);

  /// Get elevation in meters
  double get meters => _meters;

  /// Get elevation in feet
  double get feet => _meters / 0.3048;

  /// Add elevations
  Elevation operator +(Elevation other) => Elevation._(_meters + other._meters);

  /// Subtract elevations
  Elevation operator -(Elevation other) => Elevation._(_meters - other._meters);

  /// Compare elevations
  bool operator >(Elevation other) => _meters > other._meters;
  bool operator <(Elevation other) => _meters < other._meters;
  bool operator >=(Elevation other) => _meters >= other._meters;
  bool operator <=(Elevation other) => _meters <= other._meters;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Elevation &&
          runtimeType == other.runtimeType &&
          _meters == other._meters;

  @override
  int get hashCode => _meters.hashCode;

  @override
  String toString() => 'Elevation(${_meters}m)';
}

/// Speed measurement value object
class Speed {
  const Speed._(this._metersPerSecond);

  final double _metersPerSecond;

  /// Create speed from meters per second
  factory Speed.metersPerSecond(double mps) => Speed._(mps);

  /// Create speed from kilometers per hour
  factory Speed.kilometersPerHour(double kph) => Speed._(kph / 3.6);

  /// Create speed from miles per hour
  factory Speed.milesPerHour(double mph) => Speed._(mph * 0.44704);

  /// Get speed in meters per second
  double get metersPerSecond => _metersPerSecond;

  /// Get speed in kilometers per hour
  double get kilometersPerHour => _metersPerSecond * 3.6;

  /// Get speed in miles per hour
  double get milesPerHour => _metersPerSecond / 0.44704;

  /// Compare speeds
  bool operator >(Speed other) => _metersPerSecond > other._metersPerSecond;
  bool operator <(Speed other) => _metersPerSecond < other._metersPerSecond;
  bool operator >=(Speed other) => _metersPerSecond >= other._metersPerSecond;
  bool operator <=(Speed other) => _metersPerSecond <= other._metersPerSecond;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Speed &&
          runtimeType == other.runtimeType &&
          _metersPerSecond == other._metersPerSecond;

  @override
  int get hashCode => _metersPerSecond.hashCode;

  @override
  String toString() => 'Speed(${_metersPerSecond}m/s)';
}