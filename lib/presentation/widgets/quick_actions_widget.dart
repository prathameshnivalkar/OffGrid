import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/network_state_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../config/routes.dart';

/// Widget providing quick action buttons
class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.person_add,
                    label: 'Find Contacts',
                    onPressed: () => AppRoutes.navigateToContacts(context),
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.network_cell,
                    label: 'Network Map',
                    onPressed: () => AppRoutes.navigateToNetworkMap(context),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppConstants.smallPadding),
            
            Row(
              children: [
                Expanded(
                  child: Consumer<NetworkStateProvider>(
                    builder: (context, networkProvider, child) {
                      return _buildActionButton(
                        context,
                        icon: networkProvider.isDiscovering 
                            ? Icons.stop 
                            : Icons.search,
                        label: networkProvider.isDiscovering 
                            ? 'Stop Discovery' 
                            : 'Start Discovery',
                        onPressed: networkProvider.isDiscovering
                            ? networkProvider.stopDiscovery
                            : networkProvider.startDiscovery,
                        color: networkProvider.isDiscovering 
                            ? Colors.orange 
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.settings,
                    label: 'Settings',
                    onPressed: () => _showSettingsDialog(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build action button
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.defaultPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: AppConstants.smallPadding / 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  /// Show settings dialog (placeholder)
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text('Dark Mode'),
              trailing: Switch(
                value: false,
                onChanged: null, // TODO: Implement theme switching
              ),
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              trailing: Switch(
                value: true,
                onChanged: null, // TODO: Implement notification settings
              ),
            ),
            ListTile(
              leading: Icon(Icons.battery_saver),
              title: Text('Battery Optimization'),
              trailing: Switch(
                value: false,
                onChanged: null, // TODO: Implement battery optimization
              ),
            ),
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