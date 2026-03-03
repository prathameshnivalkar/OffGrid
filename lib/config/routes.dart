import 'package:flutter/material.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/chat/chat_screen.dart';
import '../presentation/screens/contacts/contacts_screen.dart';
import '../presentation/screens/network/network_map_screen.dart';

/// Application route configuration
class AppRoutes {
  // Route names
  static const String home = '/';
  static const String chat = '/chat';
  static const String contacts = '/contacts';
  static const String networkMap = '/network';
  static const String settings = '/settings';
  
  /// Generate routes based on route settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
        
      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        final contactId = args?['contactId'] as String?;
        final contactName = args?['contactName'] as String?;
        
        if (contactId == null) {
          return _errorRoute('Contact ID is required for chat');
        }
        
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            contactId: contactId,
            contactName: contactName ?? 'Unknown',
          ),
          settings: settings,
        );
        
      case contacts:
        return MaterialPageRoute(
          builder: (_) => const ContactsScreen(),
          settings: settings,
        );
        
      case networkMap:
        return MaterialPageRoute(
          builder: (_) => const NetworkMapScreen(),
          settings: settings,
        );
        
      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }
  
  /// Create error route for unknown routes
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Navigation Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed(home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Navigate to chat screen
  static Future<void> navigateToChat(
    BuildContext context, {
    required String contactId,
    required String contactName,
  }) {
    return Navigator.pushNamed(
      context,
      chat,
      arguments: {
        'contactId': contactId,
        'contactName': contactName,
      },
    );
  }
  
  /// Navigate to contacts screen
  static Future<void> navigateToContacts(BuildContext context) {
    return Navigator.pushNamed(context, contacts);
  }
  
  /// Navigate to network map screen
  static Future<void> navigateToNetworkMap(BuildContext context) {
    return Navigator.pushNamed(context, networkMap);
  }
  
  /// Navigate back to home screen
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      home,
      (route) => false,
    );
  }
}