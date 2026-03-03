/// Base exception class for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
  
  const AppException(this.message, {this.code, this.details});
  
  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.details});
}

/// Connection-related exceptions
class ConnectionException extends NetworkException {
  const ConnectionException(super.message, {super.code, super.details});
}

/// Routing-related exceptions
class RoutingException extends NetworkException {
  const RoutingException(super.message, {super.code, super.details});
}

/// Database-related exceptions
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.details});
}

/// Encryption-related exceptions
class EncryptionException extends AppException {
  const EncryptionException(super.message, {super.code, super.details});
}

/// Permission-related exceptions
class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.details});
}

/// Message-related exceptions
class MessageException extends AppException {
  const MessageException(super.message, {super.code, super.details});
}

/// Device-related exceptions
class DeviceException extends AppException {
  const DeviceException(super.message, {super.code, super.details});
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.details});
}

/// Timeout exceptions
class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.code, super.details});
}

/// Service unavailable exceptions
class ServiceUnavailableException extends AppException {
  const ServiceUnavailableException(super.message, {super.code, super.details});
}

/// Specific network error codes
class NetworkErrorCodes {
  static const String connectionFailed = 'CONNECTION_FAILED';
  static const String connectionLost = 'CONNECTION_LOST';
  static const String discoveryFailed = 'DISCOVERY_FAILED';
  static const String advertisingFailed = 'ADVERTISING_FAILED';
  static const String payloadTransferFailed = 'PAYLOAD_TRANSFER_FAILED';
  static const String endpointNotFound = 'ENDPOINT_NOT_FOUND';
  static const String maxConnectionsReached = 'MAX_CONNECTIONS_REACHED';
}

/// Specific routing error codes
class RoutingErrorCodes {
  static const String routeNotFound = 'ROUTE_NOT_FOUND';
  static const String routeExpired = 'ROUTE_EXPIRED';
  static const String routeDiscoveryTimeout = 'ROUTE_DISCOVERY_TIMEOUT';
  static const String maxHopsExceeded = 'MAX_HOPS_EXCEEDED';
  static const String routingTableFull = 'ROUTING_TABLE_FULL';
}

/// Specific encryption error codes
class EncryptionErrorCodes {
  static const String keyGenerationFailed = 'KEY_GENERATION_FAILED';
  static const String encryptionFailed = 'ENCRYPTION_FAILED';
  static const String decryptionFailed = 'DECRYPTION_FAILED';
  static const String invalidKey = 'INVALID_KEY';
  static const String signatureFailed = 'SIGNATURE_FAILED';
  static const String verificationFailed = 'VERIFICATION_FAILED';
}

/// Specific database error codes
class DatabaseErrorCodes {
  static const String initializationFailed = 'INITIALIZATION_FAILED';
  static const String insertFailed = 'INSERT_FAILED';
  static const String updateFailed = 'UPDATE_FAILED';
  static const String deleteFailed = 'DELETE_FAILED';
  static const String queryFailed = 'QUERY_FAILED';
  static const String migrationFailed = 'MIGRATION_FAILED';
}