/// Represents a contact in the mesh network
class Contact {
  final String id;
  final String name;
  final String publicKey;
  final DateTime? lastSeen;
  final bool isOnline;
  final String? deviceInfo;
  final int messageCount;
  final DateTime? lastMessageTime;
  
  const Contact({
    required this.id,
    required this.name,
    required this.publicKey,
    this.lastSeen,
    this.isOnline = false,
    this.deviceInfo,
    this.messageCount = 0,
    this.lastMessageTime,
  });
  
  /// Create a copy with updated fields
  Contact copyWith({
    String? id,
    String? name,
    String? publicKey,
    DateTime? lastSeen,
    bool? isOnline,
    String? deviceInfo,
    int? messageCount,
    DateTime? lastMessageTime,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      publicKey: publicKey ?? this.publicKey,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      messageCount: messageCount ?? this.messageCount,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
  
  /// Convert to JSON for network transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'publicKey': publicKey,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'isOnline': isOnline,
      'deviceInfo': deviceInfo,
    };
  }
  
  /// Create from JSON received from network
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      publicKey: json['publicKey'] as String,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int)
          : null,
      isOnline: json['isOnline'] as bool? ?? false,
      deviceInfo: json['deviceInfo'] as String?,
    );
  }
  
  /// Convert to database map
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': name,
      'public_key': publicKey,
      'last_seen': lastSeen?.millisecondsSinceEpoch,
      'is_online': isOnline ? 1 : 0,
      'device_info': deviceInfo,
      'message_count': messageCount,
      'last_message_time': lastMessageTime?.millisecondsSinceEpoch,
    };
  }
  
  /// Create from database map
  factory Contact.fromDatabase(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as String,
      name: map['name'] as String,
      publicKey: map['public_key'] as String,
      lastSeen: map['last_seen'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_seen'] as int)
          : null,
      isOnline: (map['is_online'] as int?) == 1,
      deviceInfo: map['device_info'] as String?,
      messageCount: map['message_count'] as int? ?? 0,
      lastMessageTime: map['last_message_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_message_time'] as int)
          : null,
    );
  }
  
  /// Get display name with fallback
  String get displayName {
    if (name.isNotEmpty) return name;
    return 'Device ${id.substring(0, 8)}';
  }
  
  /// Get online status text
  String get statusText {
    if (isOnline) return 'Online';
    if (lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSeen!);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return 'Long time ago';
      }
    }
    return 'Never seen';
  }
  
  /// Get short device ID for display
  String get shortId => id.length > 8 ? id.substring(0, 8) : id;
  
  /// Check if contact was recently active
  bool get isRecentlyActive {
    if (isOnline) return true;
    if (lastSeen == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen!);
    return difference.inHours < 24; // Active within last 24 hours
  }
  
  /// Get initials for avatar
  String get initials {
    final words = displayName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return '?';
  }
  
  @override
  String toString() {
    return 'Contact(id: $id, name: $name, online: $isOnline)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

/// Contact discovery information
class ContactDiscovery {
  final String endpointId;
  final String deviceName;
  final String? deviceInfo;
  final DateTime discoveredAt;
  final bool isConnected;
  
  const ContactDiscovery({
    required this.endpointId,
    required this.deviceName,
    this.deviceInfo,
    required this.discoveredAt,
    this.isConnected = false,
  });
  
  /// Convert to Contact when connection is established
  Contact toContact({
    required String publicKey,
  }) {
    return Contact(
      id: endpointId,
      name: deviceName,
      publicKey: publicKey,
      lastSeen: DateTime.now(),
      isOnline: isConnected,
      deviceInfo: deviceInfo,
    );
  }
  
  @override
  String toString() {
    return 'ContactDiscovery(endpoint: $endpointId, name: $deviceName, connected: $isConnected)';
  }
}