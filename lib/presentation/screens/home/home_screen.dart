import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/network_state_provider.dart';
import '../../providers/message_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../config/routes.dart';
import '../../widgets/network_status_widget.dart';
import '../../widgets/recent_conversations_widget.dart';
import '../../widgets/quick_actions_widget.dart';

/// Main home screen of the application
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // Initialize networking after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNetworking();
    });
  }
  
  /// Initialize networking on app start
  Future<void> _initializeNetworking() async {
    final networkProvider = context.read<NetworkStateProvider>();
    
    // Start advertising and discovery
    await networkProvider.startAdvertising();
    await networkProvider.startDiscovery();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  
  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(AppConstants.appName),
      actions: [
        Consumer<NetworkStateProvider>(
          builder: (context, networkProvider, child) {
            return IconButton(
              icon: Icon(
                networkProvider.isNetworkActive 
                    ? Icons.wifi 
                    : Icons.wifi_off,
                color: networkProvider.isNetworkActive 
                    ? Colors.green 
                    : Colors.red,
              ),
              onPressed: () => _showNetworkStatus(context),
            );
          },
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'about',
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// Build main body content
  Widget _buildBody() {
    return Consumer<AppStateProvider>(
      builder: (context, appProvider, child) {
        if (!appProvider.isInitialized) {
          return _buildLoadingScreen();
        }
        
        if (appProvider.hasError) {
          return _buildErrorScreen(appProvider.errorMessage!);
        }
        
        return _buildMainContent();
      },
    );
  }
  
  /// Build loading screen
  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppConstants.defaultPadding),
          Text('Initializing OffGrid Messenger...'),
        ],
      ),
    );
  }
  
  /// Build error screen
  Widget _buildErrorScreen(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            const Text(
              'Initialization Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: AppConstants.largePadding),
            ElevatedButton(
              onPressed: () {
                context.read<AppStateProvider>().retryInitialization();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build main content based on selected tab
  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildMessagesTab();
      case 2:
        return _buildNetworkTab();
      default:
        return _buildHomeTab();
    }
  }
  
  /// Build home tab content
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Network status card
          const NetworkStatusWidget(),
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Quick actions
          const QuickActionsWidget(),
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Recent conversations
          const Text(
            'Recent Conversations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          const RecentConversationsWidget(),
        ],
      ),
    );
  }
  
  /// Build messages tab content
  Widget _buildMessagesTab() {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, child) {
        return Column(
          children: [
            // Messages summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMessageStat(
                        'Total',
                        messageProvider.totalMessages.toString(),
                        Icons.message,
                      ),
                      _buildMessageStat(
                        'Pending',
                        messageProvider.pendingMessages.toString(),
                        Icons.schedule,
                      ),
                      _buildMessageStat(
                        'Delivered',
                        messageProvider.deliveredMessages.toString(),
                        Icons.check_circle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Recent conversations
            const Expanded(
              child: RecentConversationsWidget(showAll: true),
            ),
          ],
        );
      },
    );
  }
  
  /// Build network tab content
  Widget _buildNetworkTab() {
    return Consumer<NetworkStateProvider>(
      builder: (context, networkProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Network controls
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Network Controls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: networkProvider.isDiscovering
                                  ? networkProvider.stopDiscovery
                                  : networkProvider.startDiscovery,
                              icon: Icon(networkProvider.isDiscovering
                                  ? Icons.stop
                                  : Icons.search),
                              label: Text(networkProvider.isDiscovering
                                  ? 'Stop Discovery'
                                  : 'Start Discovery'),
                            ),
                          ),
                          const SizedBox(width: AppConstants.smallPadding),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: networkProvider.isAdvertising
                                  ? networkProvider.stopAdvertising
                                  : networkProvider.startAdvertising,
                              icon: Icon(networkProvider.isAdvertising
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              label: Text(networkProvider.isAdvertising
                                  ? 'Stop Advertising'
                                  : 'Start Advertising'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Connected devices
              const Text(
                'Connected Devices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              
              if (networkProvider.connectedContacts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.defaultPadding),
                    child: Center(
                      child: Text('No connected devices'),
                    ),
                  ),
                )
              else
                ...networkProvider.connectedContacts.map(
                  (contact) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(contact.initials),
                      ),
                      title: Text(contact.displayName),
                      subtitle: Text(contact.statusText),
                      trailing: IconButton(
                        icon: const Icon(Icons.message),
                        onPressed: () => AppRoutes.navigateToChat(
                          context,
                          contactId: contact.id,
                          contactName: contact.displayName,
                        ),
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Discovered devices
              const Text(
                'Discovered Devices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              
              if (networkProvider.discoveredDevices.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.defaultPadding),
                    child: Center(
                      child: Text('No devices discovered'),
                    ),
                  ),
                )
              else
                ...networkProvider.discoveredDevices.map(
                  (device) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.device_unknown),
                      ),
                      title: Text(device.deviceName),
                      subtitle: Text(device.deviceInfo ?? 'Unknown device'),
                      trailing: ElevatedButton(
                        onPressed: () => networkProvider.connectToDevice(device),
                        child: const Text('Connect'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  /// Build message statistic widget
  Widget _buildMessageStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }
  
  /// Build bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.network_cell),
          label: 'Network',
        ),
      ],
    );
  }
  
  /// Build floating action button
  Widget? _buildFloatingActionButton() {
    if (_selectedIndex == 1) {
      return FloatingActionButton(
        onPressed: () => AppRoutes.navigateToContacts(context),
        child: const Icon(Icons.add),
      );
    }
    return null;
  }
  
  /// Show network status dialog
  void _showNetworkStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Status'),
        content: Consumer<NetworkStateProvider>(
          builder: (context, networkProvider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Discovery: ${networkProvider.isDiscovering ? 'Active' : 'Inactive'}'),
                Text('Advertising: ${networkProvider.isAdvertising ? 'Active' : 'Inactive'}'),
                Text('Connected Devices: ${networkProvider.activeConnections}'),
                Text('Messages Routed: ${networkProvider.totalMessagesRouted}'),
                if (networkProvider.lastNetworkActivity != null)
                  Text('Last Activity: ${networkProvider.lastNetworkActivity}'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  /// Handle menu selection
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'settings':
        // TODO: Navigate to settings
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings coming soon')),
        );
        break;
      case 'about':
        _showAboutDialog();
        break;
    }
  }
  
  /// Show about dialog
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationLegalese: '© 2026 OffGrid Messenger Team',
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(AppConstants.appDescription),
        ),
      ],
    );
  }
}