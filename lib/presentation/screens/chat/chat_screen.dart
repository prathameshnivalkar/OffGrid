import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/network_state_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../config/theme.dart';
import '../../../data/models/message.dart';

/// Chat screen for messaging with a specific contact
class ChatScreen extends StatefulWidget {
  final String contactId;
  final String contactName;
  
  const ChatScreen({
    super.key,
    required this.contactId,
    required this.contactName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Mark conversation as read when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().markConversationAsRead(widget.contactId);
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }
  
  /// Build app bar with contact info
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<NetworkStateProvider>(
        builder: (context, networkProvider, child) {
          final contact = networkProvider.connectedContacts
              .where((c) => c.id == widget.contactId)
              .firstOrNull;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.contactName),
              Text(
                contact?.statusText ?? 'Offline',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info),
          onPressed: () => _showContactInfo(),
        ),
      ],
    );
  }
  
  /// Build messages list
  Widget _buildMessagesList() {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, child) {
        final messages = messageProvider.getConversation(widget.contactId);
        
        if (messages.isEmpty) {
          return _buildEmptyChat();
        }
        
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageBubble(message);
          },
        );
      },
    );
  }
  
  /// Build empty chat state
  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Send a message to start the conversation',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build message bubble
  Widget _buildMessageBubble(MeshMessage message) {
    final isSent = !message.isIncoming;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.smallPadding / 2),
      child: Row(
        mainAxisAlignment: isSent 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!isSent) ...[
            CircleAvatar(
              radius: 16,
              child: Text(
                widget.contactName.isNotEmpty 
                    ? widget.contactName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
              decoration: BoxDecoration(
                color: AppTheme.getMessageBubbleColor(context, isSent),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: AppTheme.getMessageTextColor(context, isSent),
                    ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding / 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.getMessageTextColor(context, isSent)
                              .withOpacity(0.7),
                        ),
                      ),
                      if (isSent) ...[
                        const SizedBox(width: AppConstants.smallPadding / 2),
                        Icon(
                          _getMessageStatusIcon(message.status),
                          size: 12,
                          color: AppTheme.getMessageTextColor(context, isSent)
                              .withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isSent) ...[
            const SizedBox(width: AppConstants.smallPadding),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Build message input
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.smallPadding,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          FloatingActionButton.small(
            onPressed: _sendMessage,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
  
  /// Send message
  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    
    context.read<MessageProvider>().sendMessage(
      destinationId: widget.contactId,
      content: content,
    );
    
    _messageController.clear();
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppConstants.shortAnimation,
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  /// Format message timestamp
  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
  
  /// Get message status icon
  IconData _getMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.pending:
        return Icons.schedule;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }
  
  /// Show contact information
  void _showContactInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.contactName),
        content: Consumer<NetworkStateProvider>(
          builder: (context, networkProvider, child) {
            final contact = networkProvider.connectedContacts
                .where((c) => c.id == widget.contactId)
                .firstOrNull;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Device ID: ${widget.contactId}'),
                Text('Status: ${contact?.statusText ?? 'Offline'}'),
                if (contact?.deviceInfo != null)
                  Text('Device: ${contact!.deviceInfo}'),
                if (contact?.lastSeen != null)
                  Text('Last seen: ${contact!.lastSeen}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}