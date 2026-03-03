/// Network and routing constants for mesh networking
class NetworkConstants {
  // Nearby Connections
  static const String serviceId = 'com.offgrid.messenger';
  static const String strategy = 'P2P_CLUSTER'; // Supports up to 8 connections
  
  // Connection Settings
  static const int maxConnections = 8;
  static const int connectionTimeoutMs = 30000; // 30 seconds
  static const int discoveryTimeoutMs = 60000; // 1 minute
  
  // Routing Protocol (AODV)
  static const int maxHopCount = 7;
  static const int defaultTtl = 10;
  static const int routeTimeoutMs = 300000; // 5 minutes
  static const int routeDiscoveryTimeoutMs = 10000; // 10 seconds
  static const int maxRouteDiscoveryRetries = 3;
  
  // Message Queue
  static const int maxQueueSize = 1000;
  static const int messageRetryAttempts = 3;
  static const int messageRetryDelayMs = 5000; // 5 seconds
  
  // Sequence Numbers
  static const int maxSequenceNumber = 65535; // 16-bit
  static const int sequenceNumberIncrement = 1;
  
  // Payload Sizes
  static const int maxPayloadSize = 32768; // 32KB
  static const int maxMessageContentSize = 1024; // 1KB for text messages
  
  // Network Discovery
  static const int advertisingDurationMs = 0; // Continuous
  static const int discoveryDurationMs = 0; // Continuous
  
  // Background Service
  static const int backgroundSyncIntervalMs = 30000; // 30 seconds
  static const int connectionHealthCheckMs = 10000; // 10 seconds
  
  // Encryption
  static const int rsaKeySize = 2048;
  static const int aesKeySize = 256;
  static const String encryptionAlgorithm = 'AES/CBC/PKCS7';
  
  // Device Identification
  static const int deviceIdLength = 16; // UUID without hyphens
  static const String deviceNamePrefix = 'OffGrid_';
}