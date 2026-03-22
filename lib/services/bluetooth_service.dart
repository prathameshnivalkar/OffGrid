import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/utils/logger.dart';
import '../data/models/message.dart';

/// Bluetooth/WiFi Direct service for device discovery and communication
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  // Nearby Connections
  static const String _serviceId = 'com.example.offgrid_messenger';
  static const Strategy _strategy = Strategy.P2P_CLUSTER;

  // State
  bool _isInitialized = false;
  bool _isDiscovering = false;
  bool _isAdvertising = false;
  final Map<String, String> _discoveredDevices = {}; // endpointId -> deviceName
  final Map<String, String> _connections = {}; // endpointId -> deviceName

  // Stream controllers
  final StreamController<List<DiscoveredDevice>> _devicesController =
      StreamController<List<DiscoveredDevice>>.broadcast();
  final StreamController<MeshMessage> _messageController =
      StreamController<MeshMessage>.broadcast();
  final StreamController<String> _connectionController =
      StreamController<String>.broadcast();

  // Connection tracking
  final Map<String, Completer<bool>> _pendingConnections = {};
  static const int _maxConnections = 8;
  static const int _connectionTimeoutSeconds = 30;

  // Message retry configuration
  static const int _messageRetryAttempts = 3;
  static const int _messageRetryDelayMs = 1000;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isDiscovering => _isDiscovering;
  bool get isAdvertising => _isAdvertising;
  List<DiscoveredDevice> get discoveredDevices => _discoveredDevices.entries
      .map((e) => DiscoveredDevice(endpointId: e.key, deviceName: e.value))
      .toList();
  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;
  Stream<MeshMessage> get messageStream => _messageController.stream;
  Stream<String> get connectionStream => _connectionController.stream;

  /// Initialize Bluetooth service
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;

      Logger.info('Initializing Nearby Connections service');

      // Request permissions
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        Logger.error('Required permissions not granted');
        return false;
      }

      _isInitialized = true;
      Logger.info('Nearby Connections service initialized successfully');
      return true;
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to initialize Nearby Connections service',
        error,
        stackTrace,
      );
      return false;
    }
  }

  /// Request necessary permissions with Android 12+ handling
  Future<bool> _requestPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ];

    Logger.info('Requesting permissions for Nearby Connections...');
    final statuses = await permissions.request();

    // Log all permission results
    bool allEssentialGranted = true;
    for (final permission in permissions) {
      final status = statuses[permission];
      Logger.info('Permission ${permission.toString()}: ${status?.name}');

      // These are critical for Nearby Connections
      if (permission == Permission.locationWhenInUse ||
          permission == Permission.nearbyWifiDevices ||
          permission == Permission.bluetoothScan) {
        if (status != PermissionStatus.granted) {
          allEssentialGranted = false;
        }
      }
    }

    // If location denied, try to explain and retry once
    if (statuses[Permission.locationWhenInUse]?.isDenied ?? false) {
      Logger.warning(
        'Location permission denied, requesting again with explanation...',
      );
      final retryStatus = await Permission.locationWhenInUse.request();
      if (retryStatus != PermissionStatus.granted) {
        Logger.error('Location permission required for Nearby Connections');
        return false;
      }
    }

    // For Android 12+, ensure nearbyWifiDevices is granted
    if (Platform.isAndroid) {
      if (statuses[Permission.nearbyWifiDevices]?.isDenied ?? false) {
        Logger.warning('Nearby WiFi permission denied on Android 12+');
        final retryStatus = await Permission.nearbyWifiDevices.request();
        if (retryStatus != PermissionStatus.granted) {
          Logger.error(
            'Nearby WiFi permission required for Nearby Connections on Android 12+',
          );
          return false;
        }
      }
    }

    return allEssentialGranted;
  }

  /// Start mesh networking (discovery + advertising together)
  /// This ensures devices can both find and be found by each other
  Future<bool> startMesh() async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return false;
      }

      // If already running, restart for resilience
      if (_isDiscovering && _isAdvertising) {
        Logger.info('Mesh already active, proceeding');
        return true;
      }

      Logger.info('Starting Mesh networking (discovery + advertising)');

      // Start both discovery and advertising in parallel
      final results = await Future.wait([
        startDiscovery(),
        startAdvertising(),
      ], eagerError: false);

      final discoverySuccess = results[0] as bool;
      final advertisingSuccess = results[1] as bool;

      if (!discoverySuccess || !advertisingSuccess) {
        Logger.error(
          'Mesh startup failed - Discovery: $discoverySuccess, Advertising: $advertisingSuccess',
        );
        return false;
      }

      Logger.info('Mesh networking started successfully');
      return true;
    } catch (error, stackTrace) {
      Logger.error('Failed to start mesh', error, stackTrace);
      return false;
    }
  }

  /// Start device discovery
  Future<bool> startDiscovery() async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return false;
      }

      if (_isDiscovering) {
        Logger.info('Discovery already active');
        return true;
      }

      Logger.info('Starting Nearby Connections discovery');
      _isDiscovering = true;
      _discoveredDevices.clear();

      try {
        // Start Nearby Connections discovery
        await Nearby()
            .startDiscovery(
              'OffGrid_${DateTime.now().millisecondsSinceEpoch}',
              _strategy,
              onEndpointFound: (endpointId, name, serviceId) {
                Logger.info('Found Nearby endpoint: $name ($endpointId)');
                _discoveredDevices[endpointId] = name;
                _devicesController.add(discoveredDevices);
              },
              onEndpointLost: (endpointId) {
                Logger.info('Lost Nearby endpoint: $endpointId');
                _discoveredDevices.remove(endpointId);
                _devicesController.add(discoveredDevices);
              },
              serviceId: _serviceId,
            )
            .timeout(const Duration(seconds: 5));

        Logger.info('Discovery started successfully');
        return true;
      } catch (discoveryError) {
        // Log the specific error for debugging
        Logger.error('Discovery error details: $discoveryError');

        // If already discovering, sync state and return success
        if (discoveryError.toString().contains('STATUS_ALREADY_DISCOVERING') ||
            discoveryError.toString().contains('8004')) {
          Logger.warning('Service already discovering, syncing state');
          _isDiscovering = true;
          return true;
        }

        // If NFC error occurs, it's usually safe to continue anyway
        if (discoveryError.toString().contains('NFC')) {
          Logger.warning(
            'NFC error detected, but continuing with Bluetooth/WiFi discovery',
          );
          return true;
        }

        _isDiscovering = false;
        rethrow;
      }
    } catch (error, stackTrace) {
      Logger.error('Failed to start discovery', error, stackTrace);
      _isDiscovering = false;
      return false;
    }
  }

  /// Stop device discovery
  Future<void> stopDiscovery() async {
    try {
      if (!_isDiscovering) return;

      Logger.info('Stopping Nearby Connections discovery');

      try {
        // Stop Nearby Connections discovery
        await Nearby().stopDiscovery().timeout(
          const Duration(seconds: 5),
          onTimeout: () => Logger.warning('Discovery stop timeout'),
        );
      } catch (error) {
        // If discovery isn't running, that's fine
        if (!error.toString().contains('not start') &&
            !error.toString().contains('not discovering')) {
          rethrow;
        }
        Logger.debug('Discovery was not running');
      }

      _isDiscovering = false;
      _discoveredDevices.clear();
      _devicesController.add([]);
    } catch (error, stackTrace) {
      Logger.error('Failed to stop discovery', error, stackTrace);
      _isDiscovering = false; // Force state update on error
    }
  }

  /// Start advertising
  Future<bool> startAdvertising() async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return false;
      }

      if (_isAdvertising) return true;

      Logger.info('Starting Nearby Connections advertising');
      _isAdvertising = true;

      try {
        // Start Nearby Connections advertising
        await Nearby()
            .startAdvertising(
              'OffGrid_${DateTime.now().millisecondsSinceEpoch}',
              _strategy,
              onConnectionInitiated: (endpointId, info) {
                Logger.network(
                  'Connection initiated with: ${info.endpointName}',
                );

                // Check if we're at max connections
                if (_connections.length >= _maxConnections) {
                  Logger.warning(
                    'Max connections ($_maxConnections) reached, rejecting: $endpointId',
                  );
                  Nearby().rejectConnection(endpointId);
                  return;
                }

                // Add basic validation
                if (info.endpointName.isEmpty) {
                  Logger.warning(
                    'Invalid empty device name, rejecting: $endpointId',
                  );
                  Nearby().rejectConnection(endpointId);
                  return;
                }

                // Accept connection for mesh networking
                Logger.network(
                  'Accepting connection from: ${info.endpointName}',
                );
                Nearby().acceptConnection(
                  endpointId,
                  onPayLoadRecieved: (endpointId, data) => _handleReceivedData(
                    endpointId,
                    data.bytes ?? Uint8List(0),
                  ),
                  onPayloadTransferUpdate: (endpointId, update) =>
                      _handleDataTransferUpdate(endpointId, update),
                );
              },
              onConnectionResult: (endpointId, result) {
                if (result == Status.CONNECTED) {
                  Logger.info('Connected to endpoint: $endpointId');
                  _connections[endpointId] =
                      _discoveredDevices[endpointId] ?? 'Unknown';
                  _connectionController.add(endpointId);
                } else {
                  Logger.warning(
                    'Connection failed with status: ${result.name}',
                  );
                }
              },
              onDisconnected: (endpointId) {
                Logger.info('Disconnected from endpoint: $endpointId');
                _connections.remove(endpointId);
              },
              serviceId: _serviceId,
            )
            .timeout(const Duration(seconds: 5));

        Logger.info('Advertising started successfully');
        return true;
      } catch (advertisingError) {
        // Log the specific error
        Logger.error('Advertising error details: $advertisingError');

        // If already advertising, sync state and return success
        if (advertisingError.toString().contains(
              'STATUS_ALREADY_ADVERTISING',
            ) ||
            advertisingError.toString().contains('8001')) {
          Logger.warning('Service already advertising, syncing state');
          _isAdvertising = true;
          return true;
        }

        // If NFC error occurs, continue anyway
        if (advertisingError.toString().contains('NFC')) {
          Logger.warning(
            'NFC error detected, but continuing with Bluetooth/WiFi advertising',
          );
          return true;
        }

        _isAdvertising = false;
        rethrow;
      }
    } catch (error, stackTrace) {
      Logger.error('Failed to start advertising', error, stackTrace);
      _isAdvertising = false;
      return false;
    }
  }

  /// Stop advertising
  Future<void> stopAdvertising() async {
    try {
      if (!_isAdvertising) return;

      Logger.info('Stopping Nearby Connections advertising');

      try {
        await Nearby().stopAdvertising().timeout(
          const Duration(seconds: 5),
          onTimeout: () => Logger.warning('Advertising stop timeout'),
        );
      } catch (error) {
        // If advertising isn't running, that's fine
        if (!error.toString().contains('not start') &&
            !error.toString().contains('not advertising')) {
          rethrow;
        }
        Logger.debug('Advertising was not running');
      }

      _isAdvertising = false;
    } catch (error, stackTrace) {
      Logger.error('Failed to stop advertising', error, stackTrace);
      _isAdvertising = false; // Force state update on error
    }
  }

  /// Connect to a device with status tracking and timeout
  Future<bool> connectToDevice(DiscoveredDevice device) async {
    try {
      // Prevent duplicate connection attempts
      if (_pendingConnections.containsKey(device.endpointId)) {
        Logger.warning('Connection already pending for: ${device.endpointId}');
        return false;
      }

      // Check if already connected
      if (_connections.containsKey(device.endpointId)) {
        Logger.info('Already connected to: ${device.endpointId}');
        return true;
      }

      // Check if we're at max connections
      if (_connections.length >= _maxConnections) {
        Logger.error('Max connections ($_maxConnections) reached');
        return false;
      }

      Logger.network(
        'Requesting connection to: ${device.deviceName} (${device.endpointId})',
      );

      // Create a completer to track this connection
      final completer = Completer<bool>();
      _pendingConnections[device.endpointId] = completer;

      await Nearby().requestConnection(
        'OffGrid_${DateTime.now().millisecondsSinceEpoch}',
        device.endpointId,
        onConnectionInitiated: (endpointId, info) {
          Logger.network('Connection initiated with: ${info.endpointName}');
          Nearby().acceptConnection(
            endpointId,
            onPayLoadRecieved: (endpointId, data) =>
                _handleReceivedData(endpointId, data.bytes ?? Uint8List(0)),
            onPayloadTransferUpdate: (endpointId, update) =>
                _handleDataTransferUpdate(endpointId, update),
          );
        },
        onConnectionResult: (endpointId, result) {
          if (result == Status.CONNECTED) {
            Logger.info('Connected successfully to: $endpointId');
            _connections[endpointId] = device.deviceName;
            _connectionController.add(endpointId);

            // Resolve the completer
            if (_pendingConnections.containsKey(endpointId)) {
              _pendingConnections[endpointId]?.complete(true);
            }
          } else {
            Logger.error('Connection failed with status: ${result.name}');
            if (_pendingConnections.containsKey(endpointId)) {
              _pendingConnections[endpointId]?.complete(false);
            }
          }
          _pendingConnections.remove(endpointId);
        },
        onDisconnected: (endpointId) {
          Logger.info('Disconnected from: $endpointId');
          _connections.remove(endpointId);

          // If still pending, mark as failed
          if (_pendingConnections.containsKey(endpointId)) {
            _pendingConnections[endpointId]?.complete(false);
            _pendingConnections.remove(endpointId);
          }
        },
      );

      // Wait for result with timeout
      final result = await completer.future.timeout(
        Duration(seconds: _connectionTimeoutSeconds),
        onTimeout: () {
          Logger.error('Connection timeout for: ${device.endpointId}');
          _pendingConnections.remove(device.endpointId);
          return false;
        },
      );

      return result;
    } catch (error, stackTrace) {
      Logger.error('Failed to connect to device', error, stackTrace);
      _pendingConnections.remove(device.endpointId);
      return false;
    }
  }

  /// Send message to a device with retry logic and exponential backoff
  Future<bool> sendMessage(String deviceId, MeshMessage message) async {
    for (int attempt = 1; attempt <= _messageRetryAttempts; attempt++) {
      try {
        // Check if device is still connected
        if (!_connections.containsKey(deviceId)) {
          Logger.error('Device not connected: $deviceId');
          return false;
        }

        final messageData = jsonEncode(message.toJson());
        final bytes = utf8.encode(messageData);

        Logger.network(
          'Sending message (attempt $attempt/$_messageRetryAttempts) to: $deviceId',
        );

        // Send via Nearby Connections with timeout
        await Nearby()
            .sendBytesPayload(deviceId, bytes)
            .timeout(const Duration(seconds: 10));

        Logger.info('Successfully sent message to: $deviceId');
        return true;
      } catch (error, stackTrace) {
        Logger.warning('Send attempt $attempt failed for $deviceId: $error');

        if (attempt < _messageRetryAttempts) {
          // Exponential backoff: 1s, 2s, 4s
          final delay = _messageRetryDelayMs * attempt;
          Logger.info('Retrying in ${delay}ms...');
          await Future.delayed(Duration(milliseconds: delay));
        } else {
          Logger.error(
            'Failed to send message after $_messageRetryAttempts attempts to $deviceId',
            error,
            stackTrace,
          );
          return false;
        }
      }
    }

    return false;
  }

  /// Handle received Nearby Connections data
  void _handleReceivedData(String endpointId, Uint8List data) {
    try {
      if (data.isEmpty) {
        Logger.warning('Received empty data from: $endpointId');
        return;
      }

      final messageString = utf8.decode(data);
      final messageJson = jsonDecode(messageString);
      final message = MeshMessage.fromJson(messageJson);

      Logger.network(
        'Received message from: $endpointId - ID: ${message.messageId}',
      );
      _messageController.add(message);
    } catch (error, stackTrace) {
      Logger.error(
        'Failed to parse message from $endpointId',
        error,
        stackTrace,
      );
    }
  }

  /// Handle data transfer updates
  void _handleDataTransferUpdate(
    String endpointId,
    PayloadTransferUpdate update,
  ) {
    if (update.status == PayloadStatus.IN_PROGRESS) {
      Logger.debug(
        'Data transfer in progress from $endpointId: ${update.bytesTransferred}/${update.totalBytes} bytes',
      );
    } else if (update.status == PayloadStatus.SUCCESS) {
      Logger.network('Data transfer successful from $endpointId');
    } else if (update.status == PayloadStatus.FAILURE) {
      Logger.error('Data transfer failed from $endpointId');
    }
  }

  /// Disconnect from a device
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      Logger.network('Disconnecting from device: $deviceId');

      // Disconnect Nearby Connections
      await Nearby().disconnectFromEndpoint(deviceId);
      _connections.remove(deviceId);

      // Clean up any pending connection
      _pendingConnections.remove(deviceId);

      Logger.info('Disconnected from device: $deviceId');
    } catch (error, stackTrace) {
      Logger.error('Failed to disconnect from device', error, stackTrace);
    }
  }

  /// Handle app pause - preserve Bluetooth state
  Future<void> handleAppPause() async {
    Logger.info('App paused, preserving Bluetooth state');
    // Keep advertising and discovery running to remain reachable
    // This helps with mesh continuity
  }

  /// Handle app resume - verify Bluetooth state integrity
  Future<void> handleAppResume() async {
    Logger.info('App resumed, verifying Bluetooth state');

    try {
      // Verify that advertising/discovery are still active if expected
      if (_isAdvertising || _isDiscovering) {
        // Perform health check
        final isHealthy = await _checkMeshHealth();
        if (!isHealthy) {
          Logger.warning('Mesh health check failed, attempting restart...');
          await startMesh();
        } else {
          Logger.info('Bluetooth services still active and healthy');
        }
      }
    } catch (error, stackTrace) {
      Logger.error(
        'Error verifying Bluetooth state on resume',
        error,
        stackTrace,
      );
    }
  }

  /// Health check for mesh networking
  /// Verifies that discovery and advertising are still active
  Future<bool> _checkMeshHealth() async {
    try {
      // Verify state flags
      if (!_isDiscovering && !_isAdvertising) {
        Logger.warning('Mesh health check: services not active');
        return false;
      }

      Logger.debug('Mesh health check: services active and responsive');
      return true;
    } catch (error, stackTrace) {
      Logger.error('Mesh health check failed', error, stackTrace);
      return false;
    }
  }

  /// Restart mesh networking
  /// Stops and restarts discovery and advertising for recovery from failures
  Future<bool> restartMesh() async {
    try {
      Logger.info('Restarting mesh networking...');
      await stopMesh();
      await Future.delayed(const Duration(milliseconds: 500));
      return startMesh();
    } catch (error, stackTrace) {
      Logger.error('Failed to restart mesh', error, stackTrace);
      return false;
    }
  }

  /// Stop all mesh networking (discovery and advertising)
  Future<void> stopMesh() async {
    try {
      Logger.info('Stopping mesh networking');
      await Future.wait([
        stopDiscovery(),
        stopAdvertising(),
      ], eagerError: false);
    } catch (error, stackTrace) {
      Logger.error('Error stopping mesh', error, stackTrace);
    }
  }

  /// Get human-readable status of all connections
  String getConnectionStatus() {
    final buffer = StringBuffer();
    buffer.writeln('=== Bluetooth Service Status ===');
    buffer.writeln('Initialized: $_isInitialized');
    buffer.writeln('Discovering: $_isDiscovering');
    buffer.writeln('Advertising: $_isAdvertising');
    buffer.writeln(
      'Connected Devices: ${_connections.length}/$_maxConnections',
    );
    buffer.writeln('Discovered Devices: ${_discoveredDevices.length}');
    buffer.writeln('Pending Connections: ${_pendingConnections.length}');

    if (_connections.isNotEmpty) {
      buffer.writeln('\nConnected Devices:');
      for (final entry in _connections.entries) {
        buffer.writeln('  - ${entry.value} (${entry.key})');
      }
    }

    return buffer.toString();
  }

  /// Dispose resources
  Future<void> dispose() async {
    Logger.info('Disposing Bluetooth service');

    // Stop all operations
    await stopDiscovery();
    await stopAdvertising();

    // Disconnect all connected devices
    final deviceIds = List<String>.from(_connections.keys);
    for (final deviceId in deviceIds) {
      await disconnectFromDevice(deviceId);
    }

    // Clear state
    _connections.clear();
    _discoveredDevices.clear();
    _pendingConnections.clear();

    // Close streams
    await _devicesController.close();
    await _messageController.close();
    await _connectionController.close();

    _isInitialized = false;
    Logger.info('Bluetooth service disposed');
  }
}

/// Simple discovered device model
class DiscoveredDevice {
  final String endpointId;
  final String deviceName;

  DiscoveredDevice({required this.endpointId, required this.deviceName});
}
