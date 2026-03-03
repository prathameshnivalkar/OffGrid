import 'dart:developer' as developer;

/// Centralized logging utility for the application
class Logger {
  static const String _tag = 'OffGridMessenger';
  
  /// Log debug information
  static void debug(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 500, // Debug level
    );
  }
  
  /// Log informational messages
  static void info(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 800, // Info level
    );
  }
  
  /// Log warning messages
  static void warning(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 900, // Warning level
    );
  }
  
  /// Log error messages
  static void error(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log network-related messages
  static void network(String message) {
    debug(message, 'Network');
  }
  
  /// Log routing-related messages
  static void routing(String message) {
    debug(message, 'Routing');
  }
  
  /// Log encryption-related messages
  static void encryption(String message) {
    debug(message, 'Encryption');
  }
  
  /// Log database-related messages
  static void database(String message) {
    debug(message, 'Database');
  }
  
  /// Log UI-related messages
  static void ui(String message) {
    debug(message, 'UI');
  }
}