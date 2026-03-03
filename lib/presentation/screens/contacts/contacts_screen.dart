import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/network_state_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../config/routes.dart';
import '../../../data/models/contact.dart';

/// Screen for managing contacts and discovering new devices
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Start discovery when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final networkProvider = context.read<NetworkStateProvider>();
      if (!networkProvider.isDiscovering) {
        networkProvider.startDiscovery();
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConnectedTab(),
          _buildDiscoveredTab(),
        ],
      ),
    );
  }
  
  /// Build app bar with tabs
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Contacts'),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.people),
            text: 'Connected',
          ),
          Tab(
            icon: Icon(Icons.search),
            text: 'Discover',
          ),
        ],
      ),
      actions: [
        Consumer<NetworkStateProvider>(
          builder: (context, networkProvider, child) {
            return IconButton(
              icon: Icon(
                networkProvider.isDiscovering 
                    ? Icons.stop 
                    : Icons.refresh,
              ),
              onPressed: networkProvider.isDiscovering
                  ? networkProvider.stopDiscovery
                  : networkProvider.startDiscovery,
            );
          },
        ),
      ],
    );
  }
  
  /// Build connected contacts tab
  Widget _buildConnectedTab() {
    return Consumer<NetworkStateProvider>(
      builder: (context, networkProvider, child) {
        final connectedContacts = networkProvider.connectedContacts;
        
        if (connectedContacts.isEmpty) {
          return _buildEmptyConnectedState();
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: connectedContacts.length,
          itemBuilder: (context, index) {
            final contact = connectedContacts[index];
            return _buildConnectedContactTile(contact, networkProvider);
          },
        );
      },
    );
  }
  
  /// Build discovered devices tab
  Widget _buildDiscoveredTab() {
    return Consumer<NetworkStateProvider>(
      builder: (context, networkProvider, child) {
        return Column(
          children: [
            // Discovery status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  if (networkProvider.isDiscovering)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.search_off,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  const SizedBox(width: AppConstants.smallPadding),
                  Text(
                    networkProvider.isDiscovering 
                        ? 'Discovering nearby devices...'
                        : 'Discovery stopped',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            
            // Discovered devices list
            Expanded(
              child: _buildDiscoveredDevicesList(networkProvider),
            ),
          ],
        );
      },
    );
  }
  
  /// Build empty connected state
  Widget _buildEmptyConnectedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'No connected contacts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Discover and connect to nearby devices to start messaging',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(1); // Switch to discover tab
                context.read<NetworkStateProvider>().startDiscovery();
              },
              icon: const Icon(Icons.search),
              label: const Text('Start Discovery'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build discovered devices list
  Widget _buildDiscoveredDevicesList(NetworkStateProvider networkProvider) {
    final discoveredDevices = networkProvider.discoveredDevices;
    
    if (discoveredDevices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                networkProvider.isDiscovering 
                    ? 'Looking for devices...'
                    : 'No devices found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                networkProvider.isDiscovering
                    ? 'Make sure other devices are running OffGrid Messenger and have discovery enabled'
                    : 'Tap the refresh button to start discovering nearby devices',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: discoveredDevices.length,
      itemBuilder: (context, index) {
        final device = discoveredDevices[index];
        return _buildDiscoveredDeviceTile(device, networkProvider);
      },
    );
  }
  
  /// Build connected contact tile
  Widget _buildConnectedContactTile(
    Contact contact,
    NetworkStateProvider networkProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                contact.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (contact.isOnline)
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
        ),
        title: Text(
          contact.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.statusText),
            Text(
              'ID: ${contact.shortId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () => AppRoutes.navigateToChat(
                context,
                contactId: contact.id,
                contactName: contact.displayName,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleContactAction(
                value,
                contact,
                networkProvider,
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'info',
                  child: ListTile(
                    leading: Icon(Icons.info),
                    title: Text('Contact Info'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'disconnect',
                  child: ListTile(
                    leading: Icon(Icons.link_off),
                    title: Text('Disconnect'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
  
  /// Build discovered device tile
  Widget _buildDiscoveredDeviceTile(
    ContactDiscovery device,
    NetworkStateProvider networkProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.device_unknown),
        ),
        title: Text(device.deviceName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.deviceInfo ?? 'Unknown device'),
            Text(
              'Discovered: ${_formatDiscoveryTime(device.discoveredAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _connectToDevice(device, networkProvider),
          child: const Text('Connect'),
        ),
        isThreeLine: true,
      ),
    );
  }
  
  /// Handle contact action
  void _handleContactAction(
    String action,
    Contact contact,
    NetworkStateProvider networkProvider,
  ) {
    switch (action) {
      case 'info':
        _showContactInfo(contact);
        break;
      case 'disconnect':
        _confirmDisconnect(contact, networkProvider);
        break;
    }
  }
  
  /// Connect to discovered device
  Future<void> _connectToDevice(
    ContactDiscovery device,
    NetworkStateProvider networkProvider,
  ) async {
    try {
      await networkProvider.connectToDevice(device);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.deviceName}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Switch to connected tab
        _tabController.animateTo(0);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Show contact information
  void _showContactInfo(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contact.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device ID: ${contact.id}'),
            Text('Status: ${contact.statusText}'),
            if (contact.deviceInfo != null)
              Text('Device: ${contact.deviceInfo}'),
            if (contact.lastSeen != null)
              Text('Last seen: ${contact.lastSeen}'),
            Text('Messages: ${contact.messageCount}'),
          ],
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
  
  /// Confirm disconnect from contact
  void _confirmDisconnect(
    Contact contact,
    NetworkStateProvider networkProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect'),
        content: Text(
          'Are you sure you want to disconnect from ${contact.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              networkProvider.disconnectFromDevice(contact.id);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Disconnected from ${contact.displayName}'),
                ),
              );
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
  
  /// Format discovery time
  String _formatDiscoveryTime(DateTime discoveryTime) {
    final now = DateTime.now();
    final difference = now.difference(discoveryTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}