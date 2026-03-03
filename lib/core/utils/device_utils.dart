import 'dart:io';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../constants/network_constants.dart';

/// Utility functions for device identification and management
class DeviceUtils {
  static const Uuid _uuid = Uuid();
  static final Random _random = Random();
  
  /// Generate a unique device ID
  static String generateDeviceId() {
    return _uuid.v4().replaceAll('-', '').substring(0, NetworkConstants.deviceIdLength);
  }
  
  /// Generate a human-readable device name
  static String generateDeviceName() {
    final adjectives = [
      'Swift', 'Bright', 'Silent', 'Strong', 'Quick', 'Smart', 'Bold', 'Calm',
      'Brave', 'Clear', 'Fast', 'Sharp', 'Wise', 'Alert', 'Keen', 'Agile'
    ];
    
    final nouns = [
      'Eagle', 'Wolf', 'Fox', 'Hawk', 'Lion', 'Bear', 'Tiger', 'Falcon',
      'Raven', 'Lynx', 'Panther', 'Jaguar', 'Cheetah', 'Leopard', 'Puma', 'Cougar'
    ];
    
    final adjective = adjectives[_random.nextInt(adjectives.length)];
    final noun = nouns[_random.nextInt(nouns.length)];
    final number = _random.nextInt(999) + 1;
    
    return '${NetworkConstants.deviceNamePrefix}${adjective}_${noun}_$number';
  }
  
  /// Get or create device ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(AppConstants.keyDeviceId);
    
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = generateDeviceId();
      await prefs.setString(AppConstants.keyDeviceId, deviceId);
    }
    
    return deviceId;
  }
  
  /// Get or create device name
  static Future<String> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceName = prefs.getString(AppConstants.keyDeviceName);
    
    if (deviceName == null || deviceName.isEmpty) {
      deviceName = generateDeviceName();
      await prefs.setString(AppConstants.keyDeviceName, deviceName);
    }
    
    return deviceName;
  }
  
  /// Update device name
  static Future<void> setDeviceName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyDeviceName, name);
  }
  
  /// Check if this is the first app launch
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(AppConstants.keyFirstLaunch);
  }
  
  /// Mark first launch as complete
  static Future<void> markFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyFirstLaunch, false);
  }
  
  /// Get device platform information
  static String getPlatformInfo() {
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }
  
  /// Generate a random sequence number
  static int generateSequenceNumber() {
    return _random.nextInt(NetworkConstants.maxSequenceNumber);
  }
  
  /// Increment sequence number with wraparound
  static int incrementSequenceNumber(int current) {
    return (current + NetworkConstants.sequenceNumberIncrement) % 
           (NetworkConstants.maxSequenceNumber + 1);
  }
  
  /// Format timestamp for display
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
  
  /// Validate device ID format
  static bool isValidDeviceId(String deviceId) {
    return deviceId.length == NetworkConstants.deviceIdLength &&
           RegExp(r'^[a-f0-9]+$').hasMatch(deviceId.toLowerCase());
  }
}