import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/network_state_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../config/theme.dart';

/// Widget displaying current network status
class NetworkStatusWidget extends StatelessWidget {
  const NetworkStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkStateProvider>(
      builder: (context, networkProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      networkProvider.isNetworkActive 
                          ? Icons.wifi 
                          : Icons.wifi_off,
                      color: AppTheme.getConnectionStatusColor(
                        networkProvider.isNetworkActive,
                        networkProvider.isDiscovering || networkProvider.isAdvertising,
                      ),
                      size: 32,
                    ),
                    const SizedBox(width: AppConstants.defaultPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Network Status',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            _getStatusText(networkProvider),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.getConnectionStatusColor(
                                networkProvider.isNetworkActive,
                                networkProvider.isDiscovering || networkProvider.isAdvertising,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.defaultPadding),
                
                // Network statistics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      'Connected',
                      networkProvider.activeConnections.toString(),
                      Icons.devices,
                    ),
                    _buildStatItem(
                      context,
                      'Discovered',
                      networkProvider.discoveredDevices.length.toString(),
                      Icons.search,
                    ),
                    _buildStatItem(
                      context,
                      'Routes',
                      networkProvider.routingTable.length.toString(),
                      Icons.route,
                    ),
                  ],
                ),
                
                // Error message if any
                if (networkProvider.hasError) ...[
                  const SizedBox(height: AppConstants.smallPadding),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.smallPadding),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius / 2),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 16,
                        ),
                        const SizedBox(width: AppConstants.smallPadding),
                        Expanded(
                          child: Text(
                            networkProvider.lastError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: networkProvider.clearError,
                          icon: const Icon(Icons.close, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Action buttons
                const SizedBox(height: AppConstants.defaultPadding),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: networkProvider.isDiscovering
                            ? networkProvider.stopDiscovery
                            : networkProvider.startDiscovery,
                        icon: Icon(
                          networkProvider.isDiscovering 
                              ? Icons.stop 
                              : Icons.search,
                        ),
                        label: Text(
                          networkProvider.isDiscovering 
                              ? 'Stop Discovery' 
                              : 'Start Discovery',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: networkProvider.isAdvertising
                            ? networkProvider.stopAdvertising
                            : networkProvider.startAdvertising,
                        icon: Icon(
                          networkProvider.isAdvertising 
                              ? Icons.visibility_off 
                              : Icons.visibility,
                        ),
                        label: Text(
                          networkProvider.isAdvertising 
                              ? 'Stop Advertising' 
                              : 'Start Advertising',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Get status text based on network state
  String _getStatusText(NetworkStateProvider provider) {
    if (provider.hasError) {
      return 'Network Error';
    }
    
    if (provider.activeConnections > 0) {
      return 'Connected to ${provider.activeConnections} device${provider.activeConnections == 1 ? '' : 's'}';
    }
    
    if (provider.isDiscovering || provider.isAdvertising) {
      final actions = <String>[];
      if (provider.isDiscovering) actions.add('discovering');
      if (provider.isAdvertising) actions.add('advertising');
      return 'Network ${actions.join(' and ')}...';
    }
    
    return 'Network inactive';
  }
  
  /// Build statistic item
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppConstants.smallPadding / 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}