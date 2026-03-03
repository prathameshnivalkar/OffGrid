import 'dart:convert';

/// Represents a message in the mesh network
class MeshMessage {
  final String messageId;
  final String sourceId;
  final String destinationId;
  final String content;
  final MessageType type;
  final int ttl;
  final int sequenceNumber;
  final DateTime timestamp;
  final List<String> routePath;
  final bool requiresAck;
  final MessageStatus status;
  final bool isIncoming;
  
  const MeshMessage({
    required this.messageId,
    required this.sourceId,
    required this.destinationId,
    required this.content,
    required this.type,
    required this.ttl,
    required this.sequenceNumber,
    required this.timestamp,
    this.routePath = const [],
    this.requiresAck = true,
    this.status = MessageStatus.pending,
    this.isIncoming = false,
  });
  
  /// Create a copy with updated fields
  MeshMessage copyWith({
    String? messageId,
    String? sourceId,
    String? destinationId,
    String? content,
    MessageType? type,
    int? ttl,
    int? sequenceNumber,
    DateTime? timestamp,
    List<String>? routePath,
    bool? requiresAck,
    MessageStatus? status,
    bool? isIncoming,
  }) {
    return MeshMessage(
      messageId: messageId ?? this.messageId,
      sourceId: sourceId ?? this.sourceId,
      destinationId: destinationId ?? this.destinationId,
      content: content ?? this.content,
      type: type ?? this.type,
      ttl: ttl ?? this.ttl,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      timestamp: timestamp ?? this.timestamp,
      routePath: routePath ?? this.routePath,
      requiresAck: requiresAck ?? this.requiresAck,
      status: status ?? this.status,
      isIncoming: isIncoming ?? this.isIncoming,
    );
  }
  
  /// Convert to JSON for network transmission
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'sourceId': sourceId,
      'destinationId': destinationId,
      'content': content,
      'type': type.name,
      'ttl': ttl,
      'sequenceNumber': sequenceNumber,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'routePath': routePath,
      'requiresAck': requiresAck,
    };
  }
  
  /// Create from JSON received from network
  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      messageId: json['messageId'] as String,
      sourceId: json['sourceId'] as String,
      destinationId: json['destinationId'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      ttl: json['ttl'] as int,
      sequenceNumber: json['sequenceNumber'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      routePath: List<String>.from(json['routePath'] as List),
      requiresAck: json['requiresAck'] as bool? ?? true,
    );
  }
  
  /// Convert to database map
  Map<String, dynamic> toDatabase() {
    return {
      'id': messageId,
      'source_id': sourceId,
      'destination_id': destinationId,
      'content': content,
      'type': type.name,
      'ttl': ttl,
      'sequence_number': sequenceNumber,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'route_path': jsonEncode(routePath),
      'requires_ack': requiresAck ? 1 : 0,
      'status': status.name,
      'is_incoming': isIncoming ? 1 : 0,
    };
  }
  
  /// Create from database map
  factory MeshMessage.fromDatabase(Map<String, dynamic> map) {
    return MeshMessage(
      messageId: map['id'] as String,
      sourceId: map['source_id'] as String,
      destinationId: map['destination_id'] as String,
      content: map['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      ttl: map['ttl'] as int,
      sequenceNumber: map['sequence_number'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      routePath: List<String>.from(jsonDecode(map['route_path'] as String)),
      requiresAck: (map['requires_ack'] as int) == 1,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.pending,
      ),
      isIncoming: (map['is_incoming'] as int) == 1,
    );
  }
  
  /// Convert to bytes for network transmission
  List<int> toBytes() {
    return utf8.encode(jsonEncode(toJson()));
  }
  
  /// Create from bytes received from network
  factory MeshMessage.fromBytes(List<int> bytes) {
    final jsonString = utf8.decode(bytes);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return MeshMessage.fromJson(json);
  }
  
  /// Check if message has expired based on TTL
  bool get isExpired => ttl <= 0;
  
  /// Check if message is a routing control message
  bool get isControlMessage => 
      type == MessageType.routeRequest ||
      type == MessageType.routeReply ||
      type == MessageType.routeError;
  
  /// Get display content for UI
  String get displayContent {
    switch (type) {
      case MessageType.text:
        return content;
      case MessageType.routeRequest:
        return 'Route discovery in progress...';
      case MessageType.routeReply:
        return 'Route established';
      case MessageType.routeError:
        return 'Route error occurred';
      case MessageType.acknowledgment:
        return 'Message delivered';
    }
  }
  
  @override
  String toString() {
    return 'MeshMessage(id: $messageId, from: $sourceId, to: $destinationId, type: ${type.name}, status: ${status.name})';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeshMessage && other.messageId == messageId;
  }
  
  @override
  int get hashCode => messageId.hashCode;
}

/// Message types in the mesh network
enum MessageType {
  text,
  routeRequest,
  routeReply,
  routeError,
  acknowledgment,
}

/// Message delivery status
enum MessageStatus {
  pending,
  sent,
  delivered,
  failed,
}

/// Extension to get string representations
extension MessageTypeExtension on MessageType {
  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Text Message';
      case MessageType.routeRequest:
        return 'Route Request';
      case MessageType.routeReply:
        return 'Route Reply';
      case MessageType.routeError:
        return 'Route Error';
      case MessageType.acknowledgment:
        return 'Acknowledgment';
    }
  }
}

extension MessageStatusExtension on MessageStatus {
  String get displayName {
    switch (this) {
      case MessageStatus.pending:
        return 'Pending';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.failed:
        return 'Failed';
    }
  }
}