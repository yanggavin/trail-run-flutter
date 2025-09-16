/// Immutable value object representing a timestamp with timezone awareness
class Timestamp {
  const Timestamp(this.dateTime);

  final DateTime dateTime;

  /// Create timestamp from milliseconds since epoch
  factory Timestamp.fromMilliseconds(int milliseconds) {
    return Timestamp(DateTime.fromMillisecondsSinceEpoch(milliseconds));
  }

  /// Create timestamp from current time
  factory Timestamp.now() {
    return Timestamp(DateTime.now());
  }

  /// Create timestamp from UTC
  factory Timestamp.utc(int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    return Timestamp(DateTime.utc(year, month, day, hour, minute, second, millisecond, microsecond));
  }

  /// Get milliseconds since epoch
  int get millisecondsSinceEpoch => dateTime.millisecondsSinceEpoch;

  /// Get UTC timestamp
  Timestamp get utc => Timestamp(dateTime.toUtc());

  /// Get local timestamp
  Timestamp get local => Timestamp(dateTime.toLocal());

  /// Check if this timestamp is before another
  bool isBefore(Timestamp other) => dateTime.isBefore(other.dateTime);

  /// Check if this timestamp is after another
  bool isAfter(Timestamp other) => dateTime.isAfter(other.dateTime);

  /// Get difference between timestamps
  Duration difference(Timestamp other) => dateTime.difference(other.dateTime);

  /// Add duration to timestamp
  Timestamp add(Duration duration) => Timestamp(dateTime.add(duration));

  /// Subtract duration from timestamp
  Timestamp subtract(Duration duration) => Timestamp(dateTime.subtract(duration));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Timestamp &&
          runtimeType == other.runtimeType &&
          dateTime == other.dateTime;

  @override
  int get hashCode => dateTime.hashCode;

  @override
  String toString() => 'Timestamp($dateTime)';
}