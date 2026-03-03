/// Represents a route entry in the AODV routing table
class RouteEntry {
  final String destinationId;
  final String nextHop;
  final int hopCount;
  final int sequenceNumber;
  final DateTime lastUpdated;
  final bool isActive;
  final DateTime? expiryTime;
  final List<String> precursors;
  
  const RouteEntry({
    required this.destinationId,
    required this.nextHop,
    required this.hopCount,
    required this.sequenceNumber,
    required this.lastUpdated,
    this.isActive = true,
    this.expiryTime,
    this.precursors = const [],
  });
  
  /// Create a copy with updated fields
  RouteEntry copyWith({
    String? destinationId,
    String? nextHop,
    int? hopCount,
    int? sequenceNumber,
    DateTime? lastUpdated,
    bool? isActive,
    DateTime? expiryTime,
    List<String>? precursors,
  }) {
    return RouteEntry(
      destinationId: destinationId ?? this.destinationId,
      nextHop: nextHop ?? this.nextHop,
      hopCount: hopCount ?? this.hopCount,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
      expiryTime: expiryTime ?? this.expiryTime,
      precursors: precursors ?? this.precursors,
    );
  }
  
  /// Convert to database map
  Map<String, dynamic> toDatabase() {
    return {
      'destination_id': destinationId,
      'next_hop': nextHop,
      'hop_count': hopCount,
      'sequence_number': sequenceNumber,
      'last_updated': lastUpdated.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
      'expiry_time': expiryTime?.millisecondsSinceEpoch,
      'precursors': precursors.join(','),
    };
  }
  
  /// Create from database map
  factory RouteEntry.fromDatabase(Map<String, dynamic> map) {
    return RouteEntry(
      destinationId: map['destination_id'] as String,
      nextHop: map['next_hop'] as String,
      hopCount: map['hop_count'] as int,
      sequenceNumber: map['sequence_number'] as int,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['last_updated'] as int),
      isActive: (map['is_active'] as int) == 1,
      expiryTime: map['expiry_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiry_time'] as int)
          : null,
      precursors: map['precursors'] != null && (map['precursors'] as String).isNotEmpty
          ? (map['precursors'] as String).split(',')
          : [],
    );
  }
  
  /// Check if route has expired
  bool get isExpired {
    if (expiryTime == null) return false;
    return DateTime.now().isAfter(expiryTime!);
  }
  
  /// Check if route is valid (active and not expired)
  bool get isValid => isActive && !isExpired;
  
  /// Get route age in milliseconds
  int get ageMs => DateTime.now().difference(lastUpdated).inMilliseconds;
  
  /// Get time until expiry in milliseconds
  int? get timeToExpiryMs {
    if (expiryTime == null) return null;
    final remaining = expiryTime!.difference(DateTime.now()).inMilliseconds;
    return remaining > 0 ? remaining : 0;
  }
  
  @override
  String toString() {
    return 'RouteEntry(dest: $destinationId, nextHop: $nextHop, hops: $hopCount, seq: $sequenceNumber, active: $isActive)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteEntry && other.destinationId == destinationId;
  }
  
  @override
  int get hashCode => destinationId.hashCode;
}

/// Represents a network node in the mesh topology
class NetworkNode {
  final String nodeId;
  final String name;
  final bool isOnline;
  final DateTime lastSeen;
  final int hopCount;
  final String? nextHop;
  final List<String> connectedNodes;
  final double? signalStrength;
  final String? deviceInfo;
  
  const NetworkNode({
    required this.nodeId,
    required this.name,
    required this.isOnline,
    required this.lastSeen,
    required this.hopCount,
    this.nextHop,
    this.connectedNodes = const [],
    this.signalStrength,
    this.deviceInfo,
  });
  
  /// Create a copy with updated fields
  NetworkNode copyWith({
    String? nodeId,
    String? name,
    bool? isOnline,
    DateTime? lastSeen,
    int? hopCount,
    String? nextHop,
    List<String>? connectedNodes,
    double? signalStrength,
    String? deviceInfo,
  }) {
    return NetworkNode(
      nodeId: nodeId ?? this.nodeId,
      name: name ?? this.name,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      hopCount: hopCount ?? this.hopCount,
      nextHop: nextHop ?? this.nextHop,
      connectedNodes: connectedNodes ?? this.connectedNodes,
      signalStrength: signalStrength ?? this.signalStrength,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }
  
  /// Check if node is directly connected (1 hop)
  bool get isDirectlyConnected => hopCount == 1;
  
  /// Check if node is reachable
  bool get isReachable => isOnline && nextHop != null;
  
  /// Get display name with fallback
  String get displayName {
    if (name.isNotEmpty) return name;
    return 'Node ${nodeId.substring(0, 8)}';
  }
  
  /// Get connection quality based on hop count and signal strength
  ConnectionQuality get connectionQuality {
    if (!isOnline) return ConnectionQuality.offline;
    
    if (hopCount == 1) {
      if (signalStrength != null) {
        if (signalStrength! > 0.8) return ConnectionQuality.excellent;
        if (signalStrength! > 0.6) return ConnectionQuality.good;
        if (signalStrength! > 0.4) return ConnectionQuality.fair;
        return ConnectionQuality.poor;
      }
      return ConnectionQuality.good; // Direct connection, assume good
    } else if (hopCount <= 3) {
      return ConnectionQuality.fair;
    } else {
      return ConnectionQuality.poor;
    }
  }
  
  @override
  String toString() {
    return 'NetworkNode(id: $nodeId, name: $name, hops: $hopCount, online: $isOnline)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkNode && other.nodeId == nodeId;
  }
  
  @override
  int get hashCode => nodeId.hashCode;
}

/// Connection quality levels
enum ConnectionQuality {
  excellent,
  good,
  fair,
  poor,
  offline,
}

/// Extension for connection quality display
extension ConnectionQualityExtension on ConnectionQuality {
  String get displayName {
    switch (this) {
      case ConnectionQuality.excellent:
        return 'Excellent';
      case ConnectionQuality.good:
        return 'Good';
      case ConnectionQuality.fair:
        return 'Fair';
      case ConnectionQuality.poor:
        return 'Poor';
      case ConnectionQuality.offline:
        return 'Offline';
    }
  }
  
  /// Get color representation for UI
  int get colorValue {
    switch (this) {
      case ConnectionQuality.excellent:
        return 0xFF4CAF50; // Green
      case ConnectionQuality.good:
        return 0xFF8BC34A; // Light Green
      case ConnectionQuality.fair:
        return 0xFFFF9800; // Orange
      case ConnectionQuality.poor:
        return 0xFFFF5722; // Deep Orange
      case ConnectionQuality.offline:
        return 0xFF9E9E9E; // Grey
    }
  }
}