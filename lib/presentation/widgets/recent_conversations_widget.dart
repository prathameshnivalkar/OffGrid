import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/message_provider.dart';
import '../providers/network_state_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/device_utils.dart';
import '../../config/routes.dart';
import '../../data/models/message.dart';

/// Widget displaying recent conversations
class RecentConversationsWidget extends StatelessWidget {
  final bool showAll;
  final int maxItems;
  
  const RecentConversationsWidget({
    super.key,
    this.showAll = false,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<MessageProvider, NetworkStateProvider>(
      builder: (context, messageProvider, networkProvider, child) {
        final conversations = _getRecentConversations(
          messageProvider,
          networkProvider,
        );
        
        if (conversations.isEmpty) {
          return _buildEmptyState(context);
        }
        
        final displayConversations = showAll 
            ? conversations 
            : conversations.take(maxItems).toList();
        
        return Column(
          children: [
            ...displayConversations.map(
              (conversation) => _buildConversationTile(
                context,
                conversation,
                messageProvider,
              ),
            ),
            
            if (!showAll && conversations.length > maxItems)
              _buildViewAllButton(context),
          ],
        );
      },
    );
  }
  
  /// Get recent conversations from messages and contacts
  List<ConversationSummary> _getRecentConversations(
    MessageProvider messageProvider,
    NetworkStateProvider networkProvider,
  ) {
    final conversations = <String, ConversationSummary>{};
    
    // Group messages by contact
    for (final message in messageProvider.allMessages) {
      if (message.type != MessageType.text) continue;
      
      final contactId = message.isIncoming 
          ? message.sourceId 
          : message.destinationId;
      
      if (!conversations.containsKey(contactId)) {
        final contact = networkProvider.connectedContacts
            .where((c) => c.id == contactId)
            .firstOrNull;
        
        conversations[contactId] = ConversationSummary(
          contactId: contactId,
          contactName: contact?.displayName ?? 'Unknown Device',
          isOnline: contact?.isOnline ?? false,
          lastMessage: message,
          unreadCount: 0, // TODO: Implement unread count
        );
      } else {
        final existing = conversations[contactId]!;
        if (message.timestamp.isAfter(existing.lastMessage.timestamp)) {
          conversations[contactId] = existing.copyWith(lastMessage: message);
        }
      }
    }
    
    // Sort by last message timestamp
    final sortedConversations = conversations.values.toList()
      ..sort((a, b) => b.lastMessage.timestamp.compareTo(a.lastMessage.timestamp));
    
    return sortedConversations;
  }
  
  /// Build empty state when no conversations exist
  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          children: [
            Icon(
              Icons.message_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Connect to nearby devices to start messaging',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ElevatedButton.icon(
              onPressed: () => AppRoutes.navigateToContacts(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Find Contacts'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build conversation tile
  Widget _buildConversationTile(
    BuildContext context,
    ConversationSummary conversation,
    MessageProvider messageProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: _buildAvatar(context, conversation),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.contactName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              DeviceUtils.formatTimestamp(conversation.lastMessage.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            if (!conversation.lastMessage.isIncoming) ...[
              Icon(
                _getMessageStatusIcon(conversation.lastMessage.status),
                size: 16,
                color: _getMessageStatusColor(
                  context,
                  conversation.lastMessage.status,
                ),
              ),
              const SizedBox(width: AppConstants.smallPadding / 2),
            ],
            Expanded(
              child: Text(
                conversation.lastMessage.displayContent,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            if (conversation.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.smallPadding,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => AppRoutes.navigateToChat(
          context,
          contactId: conversation.contactId,
          contactName: conversation.contactName,
        ),
        onLongPress: () => _showConversationOptions(
          context,
          conversation,
          messageProvider,
        ),
      ),
    );
  }
  
  /// Build avatar for conversation
  Widget _buildAvatar(BuildContext context, ConversationSummary conversation) {
    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            conversation.contactName.isNotEmpty 
                ? conversation.contactName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (conversation.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  /// Build view all button
  Widget _buildViewAllButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.smallPadding),
      child: TextButton(
        onPressed: () {
          // Switch to messages tab
          // TODO: Implement tab switching
        },
        child: const Text('View All Conversations'),
      ),
    );
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
  
  /// Get message status color
  Color _getMessageStatusColor(BuildContext context, MessageStatus status) {
    switch (status) {
      case MessageStatus.pending:
        return Colors.orange;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.green;
      case MessageStatus.failed:
        return Colors.red;
    }
  }
  
  /// Show conversation options
  void _showConversationOptions(
    BuildContext context,
    ConversationSummary conversation,
    MessageProvider messageProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.mark_chat_read),
            title: const Text('Mark as Read'),
            onTap: () {
              messageProvider.markConversationAsRead(conversation.contactId);
              Navigator.pop(bottomSheetContext);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Conversation'),
            onTap: () {
              Navigator.pop(bottomSheetContext);
              _confirmDeleteConversation(context, conversation, messageProvider);
            },
          ),
        ],
      ),
    );
  }
  
  /// Confirm delete conversation
  void _confirmDeleteConversation(
    BuildContext context,
    ConversationSummary conversation,
    MessageProvider messageProvider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
          'Are you sure you want to delete the conversation with ${conversation.contactName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              messageProvider.deleteConversation(conversation.contactId);
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Conversation summary data class
class ConversationSummary {
  final String contactId;
  final String contactName;
  final bool isOnline;
  final MeshMessage lastMessage;
  final int unreadCount;
  
  const ConversationSummary({
    required this.contactId,
    required this.contactName,
    required this.isOnline,
    required this.lastMessage,
    required this.unreadCount,
  });
  
  ConversationSummary copyWith({
    String? contactId,
    String? contactName,
    bool? isOnline,
    MeshMessage? lastMessage,
    int? unreadCount,
  }) {
    return ConversationSummary(
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      isOnline: isOnline ?? this.isOnline,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}