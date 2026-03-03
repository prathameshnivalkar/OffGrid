/// Application-wide constants for OffGrid Mesh Messenger
class AppConstants {
  // App Information
  static const String appName = 'OffGrid Messenger';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Disaster-proof mesh messaging';
  
  // Database
  static const String databaseName = 'offgrid_messenger.db';
  static const int databaseVersion = 1;
  
  // Shared Preferences Keys
  static const String keyDeviceId = 'device_id';
  static const String keyDeviceName = 'device_name';
  static const String keyPublicKey = 'public_key';
  static const String keyPrivateKey = 'private_key';
  static const String keyFirstLaunch = 'first_launch';
  
  // Message Types
  static const String messageTypeText = 'TEXT';
  static const String messageTypeRouteRequest = 'RREQ';
  static const String messageTypeRouteReply = 'RREP';
  static const String messageTypeRouteError = 'RERR';
  static const String messageTypeAcknowledgment = 'ACK';
  
  // Message Status
  static const String messageStatusPending = 'PENDING';
  static const String messageStatusSent = 'SENT';
  static const String messageStatusDelivered = 'DELIVERED';
  static const String messageStatusFailed = 'FAILED';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}