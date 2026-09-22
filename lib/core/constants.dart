abstract final class AppConstants {
  static const appName = 'Spotly';
  static const tagline = 'Salons, food, pharmacies & more';

  /// Opening hours are in West Africa Time (UTC+1, no daylight saving),
  /// the time zone of every city Spotly covers, so open/closed status is
  /// correct wherever the viewer is.
  static const watUtcOffset = Duration(hours: 1);
}
