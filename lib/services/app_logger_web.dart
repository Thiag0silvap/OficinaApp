class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  Future<void> info(String message) async {}
  Future<void> warning(String message) async {}
  Future<void> error(String message) async {}
}
