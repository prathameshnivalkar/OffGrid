import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/utils/logger.dart';
import '../data/models/contact.dart';
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

  /// Request necessary permissions
  Future<bool> _requestPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ];

    final statuses = await permissions.request();

    for (final permission in permissions) {
      if (statuses[permission] != PermissionStatus.granted) {
        Logger.warning('Permission ${permission.toString()} not granted');
      }
    }

    // Check if essential permissions are granted
    return statuses[Permission.locationWhenInUse] == PermissionStatus.granted;
  }

  /// Start device discovery
  Future<bool> startDiscovery() async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return false;
      }

      if (_isDiscovering) return true;

      Logger.info('Starting Nearby Connections discovery');
      _isDiscovering = true;
      _discoveredDevices.clear();

      // Start Nearby Connections discovery
      await Nearby().startDiscovery(
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
      );

      return true;
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
      _isDiscovering = false;

      // Stop Nearby Connections discovery
      await Nearby().stopDiscovery();

      _discoveredDevices.clear();
      _devicesController.add([]);
    } catch (error, stackTrace) {
      Logger.error('Failed to stop discovery', error, stackTrace);
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

      // Start Nearby Connections advertising
      await Nearby().startAdvertising(
        'OffGrid_${DateTime.now().millisecondsSinceEpoch}',
        _strategy,
        onConnectionInitiated: (endpointId, info) {
          Logger.info('Connection initiated with: ${info.endpointName}');
          // Auto-accept connections for mesh networking
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
            Logger.info('Connected to endpoint: $endpointId');
            _connections[endpointId] =
                _discoveredDevices[endpointId] ?? 'Unknown';
            _connectionController.add(endpointId);
          }
        },
        onDisconnected: (endpointId) {
          Logger.info('Disconnected from endpoint: $endpointId');
          _connections.remove(endpointId);
        },
        serviceId: _serviceId,
      );

      return true;
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
      _isAdvertising = false;

      await Nearby().stopAdvertising();
    } catch (error, stackTrace) {
      Logger.error('Failed to stop advertising', error, stackTrace);
    }
  }

  /// Connect to a device
  Future<bool> connectToDevice(DiscoveredDevice device) async {
    try {
      Logger.info(
        'Connecting to device: ${device.deviceName} (${device.endpointId})',
      );

      await Nearby().requestConnection(
        'OffGrid_${DateTime.now().millisecondsSinceEpoch}',
        device.endpointId,
        onConnectionInitiated: (endpointId, info) {
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
            Logger.info('Connected to Nearby device: $endpointId');
            _connections[endpointId] = device.deviceName;
            _connectionController.add(endpointId);
          }
        },
        onDisconnected: (endpointId) {
          Logger.info('Disconnected from Nearby device: $endpointId');
          _connections.remove(endpointId);
        },
      );

      return true;
    } catch (error, stackTrace) {
      Logger.error('Failed to connect to device', error, stackTrace);
      return false;
    }
  }

  /// Send message to a device
  Future<bool> sendMessage(String deviceId, MeshMessage message) async {
    try {
      final messageData = jsonEncode(message.toJson());
      final bytes = utf8.encode(messageData);

      // Send via Nearby Connections
      await Nearby().sendBytesPayload(deviceId, bytes);
      Logger.info('Sent message via Nearby Connections to: $deviceId');
      return true;
    } catch (error, stackTrace) {
      Logger.error('Failed to send message', error, stackTrace);
      return false;
    }
  }

  /// Handle received Nearby Connections data
  void _handleReceivedData(String endpointId, Uint8List data) {
    try {
      final messageString = utf8.decode(data);
      final messageJson = jsonDecode(messageString);
      final message = MeshMessage.fromJson(messageJson);

      Logger.info('Received Nearby message from: $endpointId');
      _messageController.add(message);
    } catch (error, stackTrace) {
      Logger.error('Failed to parse Nearby message', error, stackTrace);
    }
  }

  /// Handle data transfer updates
  void _handleDataTransferUpdate(
    String endpointId,
    PayloadTransferUpdate update,
  ) {
    Logger.info('Data transfer update from $endpointId: ${update.status}');
  }

  /// Disconnect from a device
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      Logger.info('Disconnecting from device: $deviceId');

      // Disconnect Nearby Connections
      await Nearby().disconnectFromEndpoint(deviceId);
      _connections.remove(deviceId);
    } catch (error, stackTrace) {
      Logger.error('Failed to disconnect from device', error, stackTrace);
    }
  }

  /// Dispose resources
  void dispose() {
    Logger.info('Disposing Nearby Connections service');

    stopDiscovery();
    stopAdvertising();

    _connections.clear();

    _devicesController.close();
    _messageController.close();
    _connectionController.close();
  }
}

/// Simple discovered device model
class DiscoveredDevice {
  final String endpointId;
  final String deviceName;

  DiscoveredDevice({required this.endpointId, required this.deviceName});
}
