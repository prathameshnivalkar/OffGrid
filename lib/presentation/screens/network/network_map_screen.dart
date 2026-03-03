import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/network_state_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/route.dart';

/// Screen displaying network topology and routing information
class NetworkMapScreen extends StatefulWidget {
  const NetworkMapScreen({super.key});

  @override
  State<NetworkMapScreen> createState() => _NetworkMapScreenState();
}

class _NetworkMapScreenState extends State<NetworkMapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          _buildNetworkMapTab(),
          _buildRoutingTableTab(),
        ],
      ),
    );
  }
  
  /// Build app bar with tabs
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Network Map'),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.hub),
            text: 'Network',
          ),
          Tab(
            icon: Icon(Icons.route),
            text: 'Routes',
          ),
        ],
      ),
    );
  }
  
  /// Build network map tab
  Widget _buildNetworkMapTab() {
    return Consumer<NetworkStateProvider>(
      builder: (context, networkProvider, child) {
        final networkNodes = networkProvider.networkNodes;
        
        if (networkNodes.isEmpty) {
          return _buildEmptyNetworkState();
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Network statistics
              _buildNetworkStats(networkProvider),
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Network nodes
              Text(
                'Network Nodes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              
              ...networkNodes.map((node) => _buildNetworkNodeTile(node)),
            ],
          ),
        );
      },
    );
  }
  
  /// Build routing table tab
  Widget _buildRoutingTableTab() {
    return Consumer<NetworkStateProvider>(
      builder: (context, networkProvider, child) {
        final routes = networkProvider.routingTable;
        
        if (routes.isEmpty) {
          return _buildEmptyRoutingState();
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final route = routes[index];
            return _buildRouteTile(route);
          },
        );
      },
    );
  }
  
  /// Build empty network state
  Widget _buildEmptyNetworkState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hub_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'No network nodes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Connect to other devices to see the network topology',
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
  
  /// Build empty routing state
  Widget _buildEmptyRoutingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'No routes available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Routes will appear as the mesh network discovers paths to other devices',
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
  
  /// Build network statistics card
  Widget _buildNetworkStats(NetworkStateProvider networkProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Connected Devices',
                  networkProvider.activeConnections.toString(),
                  Icons.devices,
                  Colors.green,
                ),
                _buildStatItem(
                  'Network Nodes',
                  networkProvider.networkNodes.length.toString(),
                  Icons.hub,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Active Routes',
                  networkProvider.routingTable.where((r) => r.isValid).length.toString(),
                  Icons.route,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build statistic item
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: AppConstants.smallPadding / 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  /// Build network node tile
  Widget _buildNetworkNodeTile(NetworkNode node) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Color(node.connectionQuality.colorValue),
              child: Text(
                node.displayName.isNotEmpty 
                    ? node.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (node.isOnline)
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
          node.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hops: ${node.hopCount}'),
            Text('Quality: ${node.connectionQuality.displayName}'),
            if (node.nextHop != null)
              Text('Next hop: ${node.nextHop!.substring(0, 8)}...'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              node.isOnline ? Icons.online_prediction : Icons.offline_bolt,
              color: node.isOnline ? Colors.green : Colors.grey,
            ),
            Text(
              node.isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 10,
                color: node.isOnline ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
  
  /// Build route tile
  Widget _buildRouteTile(RouteEntry route) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: route.isValid ? Colors.green : Colors.red,
          child: Text(
            route.hopCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'To: ${route.destinationId.substring(0, 8)}...',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Next hop: ${route.nextHop.substring(0, 8)}...'),
            Text('Sequence: ${route.sequenceNumber}'),
            Text('Age: ${_formatRouteAge(route.ageMs)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              route.isValid ? Icons.check_circle : Icons.error,
              color: route.isValid ? Colors.green : Colors.red,
            ),
            Text(
              route.isValid ? 'Active' : 'Expired',
              style: TextStyle(
                fontSize: 10,
                color: route.isValid ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () => _showRouteDetails(route),
      ),
    );
  }
  
  /// Format route age
  String _formatRouteAge(int ageMs) {
    final age = Duration(milliseconds: ageMs);
    
    if (age.inMinutes < 1) {
      return '${age.inSeconds}s';
    } else if (age.inHours < 1) {
      return '${age.inMinutes}m';
    } else {
      return '${age.inHours}h';
    }
  }
  
  /// Show route details
  void _showRouteDetails(RouteEntry route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Destination: ${route.destinationId}'),
            Text('Next Hop: ${route.nextHop}'),
            Text('Hop Count: ${route.hopCount}'),
            Text('Sequence Number: ${route.sequenceNumber}'),
            Text('Status: ${route.isValid ? 'Active' : 'Expired'}'),
            Text('Last Updated: ${route.lastUpdated}'),
            if (route.expiryTime != null)
              Text('Expires: ${route.expiryTime}'),
            if (route.precursors.isNotEmpty)
              Text('Precursors: ${route.precursors.join(', ')}'),
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
}