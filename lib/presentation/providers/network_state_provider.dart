import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';
import '../../data/models/contact.dart';
import '../../data/models/route.dart';
import '../../services/bluetooth_service.dart';

/// Network state management provider
class NetworkStateProvider extends ChangeNotifier {
  // Bluetooth service and subscriptions
  final BluetoothService _bluetoothService = BluetoothService();

  // Connection state
  bool _isDiscovering = false;
  bool _isAdvertising = false;
  List<Contact> _connectedContacts = [];
  List<ContactDiscovery> _discoveredDevices = [];

  // Routing state
  List<RouteEntry> _routingTable = [];
  List<NetworkNode> _networkNodes = [];

  // Network statistics
  int _totalMessagesRouted = 0;
  int _activeConnections = 0;
  DateTime? _lastNetworkActivity;

  // Error state
  String? _lastError;

  NetworkStateProvider() {
    _initializeService();
  }

  /// Initialize Bluetooth service and listen to streams
  Future<void> _initializeService() async {
    try {
      Logger.info(
        'Initializing NetworkStateProvider with real Bluetooth service',
      );

      // Initialize Bluetooth service
      final initialized = await _bluetoothService.initialize();
      if (!initialized) {
        _lastError = 'Failed to initialize Bluetooth service';
        notifyListeners();
        return;
      }

      // Listen to device discovery stream
      _bluetoothService.devicesStream.listen(
        (devices) {
          _handleDiscoveredDevices(devices);
        },
        onError: (error) {
          Logger.error('Error in devices stream: $error');
          _lastError = 'Device discovery error: $error';
          notifyListeners();
        },
      );

      // Listen to connection stream
      _bluetoothService.connectionStream.listen(
        (endpointId) {
          _handleDeviceConnected(endpointId);
        },
        onError: (error) {
          Logger.error('Error in connection stream: $error');
          _lastError = 'Connection error: $error';
          notifyListeners();
        },
      );

      Logger.info('NetworkStateProvider initialized successfully');
    } catch (error, stackTrace) {
      Logger.error('Failed to initialize service', error, stackTrace);
      _lastError = 'Service initialization failed: $error';
      notifyListeners();
    }
  }

  /// Handle discovered devices list update
  void _handleDiscoveredDevices(List<DiscoveredDevice> devices) {
    _discoveredDevices = devices
        .map(
          (d) => ContactDiscovery(
            endpointId: d.endpointId,
            deviceName: d.deviceName,
            discoveredAt: DateTime.now(),
            isConnected: false,
          ),
        )
        .toList();

    Logger.network('Updated discovered devices: ${devices.length}');
    _lastNetworkActivity = DateTime.now();
    notifyListeners();
  }

  /// Handle device connected
  void _handleDeviceConnected(String deviceId) {
    // Find the device in discovered devices and move to connected
    final discoveredIndex = _discoveredDevices.indexWhere(
      (d) => d.endpointId == deviceId,
    );

    if (discoveredIndex >= 0) {
      final discoveredDevice = _discoveredDevices[discoveredIndex];
      final contact = discoveredDevice.toContact(
        publicKey: 'bluetooth_$deviceId',
      );

      // Remove from discovered and add to connected
      _discoveredDevices.removeAt(discoveredIndex);
      _connectedContacts.add(contact);

      _activeConnections = _connectedContacts.length;
      _lastNetworkActivity = DateTime.now();

      Logger.network(
        'Device connected: $deviceId - ${discoveredDevice.deviceName}',
      );
      notifyListeners();
    }
  }

  bool get isDiscovering => _isDiscovering;
  bool get isAdvertising => _isAdvertising;
  List<Contact> get connectedContacts => List.unmodifiable(_connectedContacts);
  List<ContactDiscovery> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  List<RouteEntry> get routingTable => List.unmodifiable(_routingTable);
  List<NetworkNode> get networkNodes => List.unmodifiable(_networkNodes);
  int get totalMessagesRouted => _totalMessagesRouted;
  int get activeConnections => _activeConnections;
  DateTime? get lastNetworkActivity => _lastNetworkActivity;
  String? get lastError => _lastError;
  bool get hasError => _lastError != null;
  bool get isNetworkActive =>
      _isDiscovering || _isAdvertising || _connectedContacts.isNotEmpty;

  /// Start device discovery
  Future<void> startDiscovery() async {
    try {
      if (_isDiscovering) return;

      Logger.network('Starting device discovery');
      _isDiscovering = true;
      _lastError = null;
      _discoveredDevices.clear();
      notifyListeners();

      // Start actual discovery via Bluetooth service
      final success = await _bluetoothService.startDiscovery();
      if (!success) {
        _lastError = 'Failed to start discovery';
        _isDiscovering = false;
      }
      notifyListeners();
    } catch (error, stackTrace) {
      Logger.error('Failed to start discovery', error, stackTrace);
      _lastError = 'Failed to start discovery: $error';
      _isDiscovering = false;
      notifyListeners();
    }
  }

  /// Stop device discovery
  Future<void> stopDiscovery() async {
    try {
      if (!_isDiscovering) return;

      Logger.network('Stopping device discovery');
      _isDiscovering = false;

      // Stop discovery via Bluetooth service
      await _bluetoothService.stopDiscovery();

      _discoveredDevices.clear();
      notifyListeners();
    } catch (error, stackTrace) {
      Logger.error('Failed to stop discovery', error, stackTrace);
      _lastError = 'Failed to stop discovery: $error';
      notifyListeners();
    }
  }

  /// Start advertising device
  Future<void> startAdvertising() async {
    try {
      if (_isAdvertising) return;

      Logger.network('Starting device advertising');
      _isAdvertising = true;
      _lastError = null;
      notifyListeners();

      // Start actual advertising via Bluetooth service
      final success = await _bluetoothService.startAdvertising();
      if (!success) {
        _lastError = 'Failed to start advertising';
        _isAdvertising = false;
      }
      notifyListeners();
    } catch (error, stackTrace) {
      Logger.error('Failed to start advertising', error, stackTrace);
      _lastError = 'Failed to start advertising: $error';
      _isAdvertising = false;
      notifyListeners();
    }
  }

  /// Stop advertising device
  Future<void> stopAdvertising() async {
    try {
      if (!_isAdvertising) return;

      Logger.network('Stopping device advertising');
      _isAdvertising = false;

      // Stop advertising via Bluetooth service
      await _bluetoothService.stopAdvertising();

      notifyListeners();
    } catch (error, stackTrace) {
      Logger.error('Failed to stop advertising', error, stackTrace);
      _lastError = 'Failed to stop advertising: $error';
      notifyListeners();
    }
  }

  /// Connect to a discovered device
  Future<void> connectToDevice(ContactDiscovery device) async {
    try {
      Logger.network('Connecting to device: ${device.deviceName}');

      // Create DiscoveredDevice for BluetoothService
      final discoveredDevice = DiscoveredDevice(
        endpointId: device.endpointId,
        deviceName: device.deviceName,
      );

      // Use actual Bluetooth service connection
      final success = await _bluetoothService.connectToDevice(discoveredDevice);

      if (!success) {
        _lastError = 'Failed to connect to ${device.deviceName}';
        notifyListeners();
        return;
      }

      // Device connection will be handled by the connection stream listener
      Logger.network('Connection request sent to: ${device.deviceName}');
      notifyListeners();
    } catch (error, stackTrace) {
      Logger.error('Failed to connect to device', error, stackTrace);
      _lastError = 'Failed to connect to ${device.deviceName}: $error';
      notifyListeners();
    }
  }

  /// Disconnect from a device
  Future<void> disconnectFromDevice(String contactId) async {
    try {
      Logger.network('Disconnecting from device: $contactId');

      // Disconnect via Bluetooth service
      await _bluetoothService.disconnectFromDevice(contactId);

      // Remove from connected contacts
      _connectedContacts.removeWhere((c) => c.id == contactId);

      // Remove related routes
      _routingTable.removeWhere(
        (r) => r.nextHop == contactId || r.destinationId == contactId,
      );

      _activeConnections = _connectedContacts.length;
      _lastNetworkActivity = DateTime.now();

      Logger.network('Disconnected from device: $contactId');
      notifyListeners();
    } catch (error, stackTrace) {
      Logger.error('Failed to disconnect from device', error, stackTrace);
      _lastError = 'Failed to disconnect from device: $error';
      notifyListeners();
    }
  }

  /// Add or update a route in the routing table
  void updateRoute(RouteEntry route) {
    final existingIndex = _routingTable.indexWhere(
      (r) => r.destinationId == route.destinationId,
    );

    if (existingIndex >= 0) {
      _routingTable[existingIndex] = route;
      Logger.routing('Updated route to ${route.destinationId}');
    } else {
      _routingTable.add(route);
      Logger.routing('Added new route to ${route.destinationId}');
    }

    _updateNetworkNodes();
    notifyListeners();
  }

  /// Remove a route from the routing table
  void removeRoute(String destinationId) {
    final initialLength = _routingTable.length;
    _routingTable.removeWhere((r) => r.destinationId == destinationId);
    final removed = initialLength - _routingTable.length;
    if (removed > 0) {
      Logger.routing('Removed route to $destinationId');
      _updateNetworkNodes();
      notifyListeners();
    }
  }

  /// Get route to destination
  RouteEntry? getRoute(String destinationId) {
    return _routingTable
        .where((r) => r.destinationId == destinationId && r.isValid)
        .cast<RouteEntry?>()
        .firstWhere((r) => true, orElse: () => null);
  }

  /// Increment message routing counter
  void incrementMessageRouted() {
    _totalMessagesRouted++;
    _lastNetworkActivity = DateTime.now();
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  /// Update network nodes based on routing table and connections
  void _updateNetworkNodes() {
    final nodes = <NetworkNode>[];

    // Add directly connected nodes
    for (final contact in _connectedContacts) {
      nodes.add(
        NetworkNode(
          nodeId: contact.id,
          name: contact.name,
          isOnline: contact.isOnline,
          lastSeen: contact.lastSeen ?? DateTime.now(),
          hopCount: 1,
          connectedNodes: [],
        ),
      );
    }

    // Add nodes from routing table
    for (final route in _routingTable.where((r) => r.isValid)) {
      if (!nodes.any((n) => n.nodeId == route.destinationId)) {
        nodes.add(
          NetworkNode(
            nodeId: route.destinationId,
            name: 'Node ${route.destinationId.substring(0, 8)}',
            isOnline: true,
            lastSeen: route.lastUpdated,
            hopCount: route.hopCount,
            nextHop: route.nextHop,
            connectedNodes: [],
          ),
        );
      }
    }

    _networkNodes = nodes;
  }

  @override
  void dispose() {
    Logger.network('Network state provider disposed');
    super.dispose();
  }
}
