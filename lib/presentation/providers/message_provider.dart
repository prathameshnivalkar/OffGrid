import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/device_utils.dart';
import '../../data/models/message.dart';

/// Message state management provider with Bluetooth integration
class MessageProvider extends ChangeNotifier {
  final List<MeshMessage> _messages = [];
  final Map<String, List<MeshMessage>> _conversationCache = {};
  final Uuid _uuid = const Uuid();
  
  // Network integration
  Function(String, MeshMessage)? _sendMessageCallback;
  
  // State
  bool _isLoading = false;
  String? _lastError;
  int _sequenceNumber = 0;
  
  // Getters
  List<MeshMessage> get allMessages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get hasError => _lastError != null;
  int get totalMessages => _messages.length;
  int get pendingMessages => _messages.where((m) => m.status == MessageStatus.pending).length;
  int get sentMessages => _messages.where((m) => m.status == MessageStatus.sent).length;
  int get deliveredMessages => _messages.where((m) => m.status == MessageStatus.delivered).length;
  
  MessageProvider() {
    _initializeSequenceNumber();
  }

  /// Set network callback for sending messages
  void setNetworkCallback(Function(String, MeshMessage) callback) {
    _sendMessageCallback = callback;
    Logger.info('Network callback set for message provider');
  }
  
  /// Initialize sequence number
  Future<void> _initializeSequenceNumber() async {
    _sequenceNumber = DeviceUtils.generateSequenceNumber();
    Logger.info('Initialized message sequence number: $_sequenceNumber');
  }
  
  /// Get conversation messages for a specific contact
  List<MeshMessage> getConversation(String contactId) {
    if (_conversationCache.containsKey(contactId)) {
      return List.unmodifiable(_conversationCache[contactId]!);
    }
    
    final conversation = _messages
        .where((m) => 
            (m.sourceId == contactId || m.destinationId == contactId) &&
            m.type == MessageType.text)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    _conversationCache[contactId] = conversation;
    return List.unmodifiable(conversation);
  }
  
  /// Send a text message
  Future<void> sendMessage({
    required String destinationId,
    required String content,
    bool requiresAck = true,
  }) async {
    try {
      _lastError = null;
      
      final deviceId = await DeviceUtils.getDeviceId();
      final messageId = _uuid.v4();
      
      final message = MeshMessage(
        messageId: messageId,
        sourceId: deviceId,
        destinationId: destinationId,
        content: content,
        type: MessageType.text,
        ttl: 10, // Default TTL
        sequenceNumber: _getNextSequenceNumber(),
        timestamp: DateTime.now(),
        requiresAck: requiresAck,
        status: MessageStatus.pending,
        isIncoming: false,
      );
      
      // Add to messages list
      _messages.add(message);
      
      // Update conversation cache
      _updateConversationCache(destinationId, message);
      
      Logger.info('Created message: ${message.messageId} to $destinationId');
      notifyListeners();
      
      // Send through Bluetooth network if available
      if (_sendMessageCallback != null) {
        try {
          await _sendMessageCallback!(destinationId, message);
          updateMessageStatus(message.messageId, MessageStatus.sent);
        } catch (error) {
          Logger.error('Failed to send via Bluetooth', error);
          updateMessageStatus(message.messageId, MessageStatus.failed);
        }
      } else {
        // Fallback to simulation
        await _simulateMessageSending(message);
      }
      
    } catch (error, stackTrace) {
      Logger.error('Failed to send message', error, stackTrace);
      _lastError = 'Failed to send message: $error';
      notifyListeners();
    }
  }
  
  /// Receive a message from the network
  Future<void> receiveMessage(MeshMessage message) async {
    try {
      // Check if message already exists (prevent duplicates)
      if (_messages.any((m) => m.messageId == message.messageId)) {
        Logger.info('Duplicate message ignored: ${message.messageId}');
        return;
      }
      
      // Mark as incoming
      final incomingMessage = message.copyWith(isIncoming: true);
      
      // Add to messages list
      _messages.add(incomingMessage);
      
      // Update conversation cache
      _updateConversationCache(message.sourceId, incomingMessage);
      
      Logger.info('Received message: ${message.messageId} from ${message.sourceId}');
      notifyListeners();
      
      // Send acknowledgment if required
      if (message.requiresAck) {
        await _sendAcknowledgment(message);
      }
      
    } catch (error, stackTrace) {
      Logger.error('Failed to receive message', error, stackTrace);
      _lastError = 'Failed to receive message: $error';
      notifyListeners();
    }
  }
  
  /// Update message status
  void updateMessageStatus(String messageId, MessageStatus status) {
    final messageIndex = _messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex >= 0) {
      final updatedMessage = _messages[messageIndex].copyWith(status: status);
      _messages[messageIndex] = updatedMessage;
      
      // Update conversation cache
      final contactId = updatedMessage.isIncoming 
          ? updatedMessage.sourceId 
          : updatedMessage.destinationId;
      _updateConversationCache(contactId, updatedMessage);
      
      Logger.info('Updated message status: $messageId -> ${status.name}');
      notifyListeners();
    }
  }
  
  /// Delete a message
  void deleteMessage(String messageId) {
    final messageIndex = _messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex >= 0) {
      final message = _messages[messageIndex];
      _messages.removeAt(messageIndex);
      
      // Update conversation cache
      final contactId = message.isIncoming 
          ? message.sourceId 
          : message.destinationId;
      _invalidateConversationCache(contactId);
      
      Logger.info('Deleted message: $messageId');
      notifyListeners();
    }
  }
  
  /// Delete entire conversation
  void deleteConversation(String contactId) {
    final initialLength = _messages.length;
    _messages.removeWhere((m) => 
        m.sourceId == contactId || m.destinationId == contactId);
    final removedCount = initialLength - _messages.length;
    
    if (removedCount > 0) {
      _conversationCache.remove(contactId);
      Logger.info('Deleted conversation with $contactId ($removedCount messages)');
      notifyListeners();
    }
  }
  
  /// Get last message for a contact
  MeshMessage? getLastMessage(String contactId) {
    final conversation = getConversation(contactId);
    return conversation.isNotEmpty ? conversation.last : null;
  }
  
  /// Get unread message count for a contact
  int getUnreadCount(String contactId) {
    // TODO: Implement read status tracking
    return 0;
  }
  
  /// Mark conversation as read
  void markConversationAsRead(String contactId) {
    // TODO: Implement read status tracking
    Logger.info('Marked conversation as read: $contactId');
  }
  
  /// Clear error message
  void clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }
  
  /// Get next sequence number
  int _getNextSequenceNumber() {
    _sequenceNumber = DeviceUtils.incrementSequenceNumber(_sequenceNumber);
    return _sequenceNumber;
  }
  
  /// Update conversation cache for a contact
  void _updateConversationCache(String contactId, MeshMessage message) {
    if (_conversationCache.containsKey(contactId)) {
      final conversation = _conversationCache[contactId]!;
      final existingIndex = conversation.indexWhere((m) => m.messageId == message.messageId);
      
      if (existingIndex >= 0) {
        conversation[existingIndex] = message;
      } else {
        conversation.add(message);
        conversation.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
    } else {
      _conversationCache[contactId] = [message];
    }
  }
  
  /// Invalidate conversation cache for a contact
  void _invalidateConversationCache(String contactId) {
    _conversationCache.remove(contactId);
  }
  
  /// Send acknowledgment for received message
  Future<void> _sendAcknowledgment(MeshMessage originalMessage) async {
    try {
      final deviceId = await DeviceUtils.getDeviceId();
      
      final ackMessage = MeshMessage(
        messageId: _uuid.v4(),
        sourceId: deviceId,
        destinationId: originalMessage.sourceId,
        content: 'ACK:${originalMessage.messageId}',
        type: MessageType.acknowledgment,
        ttl: 5,
        sequenceNumber: _getNextSequenceNumber(),
        timestamp: DateTime.now(),
        requiresAck: false,
        status: MessageStatus.pending,
        isIncoming: false,
      );
      
      // TODO: Send through network layer
      Logger.info('Sent acknowledgment for message: ${originalMessage.messageId}');
      
    } catch (error, stackTrace) {
      Logger.error('Failed to send acknowledgment', error, stackTrace);
    }
  }
  
  /// Simulate message sending for testing
  Future<void> _simulateMessageSending(MeshMessage message) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Update status to sent
    updateMessageStatus(message.messageId, MessageStatus.sent);
    
    // Simulate delivery after another delay
    await Future.delayed(const Duration(seconds: 2));
    updateMessageStatus(message.messageId, MessageStatus.delivered);
  }
  
  @override
  void dispose() {
    Logger.info('Message provider disposed');
    super.dispose();
  }
}