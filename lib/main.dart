import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'core/constants/app_constants.dart';
import 'core/utils/logger.dart';
import 'core/utils/device_utils.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'services/bluetooth_service.dart';
import 'presentation/providers/app_state_provider.dart';
import 'presentation/providers/network_state_provider.dart';
import 'presentation/providers/message_provider.dart';
import 'presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize logging
  Logger.info('Starting ${AppConstants.appName} v${AppConstants.appVersion}');

  // Initialize device information
  final deviceId = await DeviceUtils.getDeviceId();
  final deviceName = await DeviceUtils.getDeviceName();
  final isFirstLaunch = await DeviceUtils.isFirstLaunch();

  Logger.info('Device ID: $deviceId');
  Logger.info('Device Name: $deviceName');
  Logger.info('First Launch: $isFirstLaunch');

  if (isFirstLaunch) {
    await DeviceUtils.markFirstLaunchComplete();
    Logger.info('First launch setup completed');
  }

  runApp(
    OffGridMessengerApp(
      deviceId: deviceId,
      deviceName: deviceName,
      isFirstLaunch: isFirstLaunch,
    ),
  );
}

class OffGridMessengerApp extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final bool isFirstLaunch;

  const OffGridMessengerApp({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.isFirstLaunch,
  });

  @override
  State<OffGridMessengerApp> createState() => _OffGridMessengerAppState();
}

class _OffGridMessengerAppState extends State<OffGridMessengerApp>
    with WidgetsBindingObserver {
  final BluetoothService _bluetoothService = BluetoothService();

  @override
  void initState() {
    super.initState();
    // Observe app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Stop observing and dispose resources
    WidgetsBinding.instance.removeObserver(this);
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        Logger.info('App paused');
        _bluetoothService.handleAppPause();
        break;
      case AppLifecycleState.resumed:
        Logger.info('App resumed');
        _bluetoothService.handleAppResume();
        break;
      case AppLifecycleState.inactive:
        Logger.info('App inactive');
        break;
      case AppLifecycleState.detached:
        Logger.info('App detached');
        break;
      case AppLifecycleState.hidden:
        Logger.info('App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(
            deviceId: widget.deviceId,
            deviceName: widget.deviceName,
            isFirstLaunch: widget.isFirstLaunch,
          ),
        ),
        ChangeNotifierProvider(create: (_) => NetworkStateProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,
            onGenerateRoute: AppRoutes.generateRoute,
            home: const HomeScreen(),
            builder: (context, child) {
              // Handle global error boundary
              ErrorWidget.builder = (FlutterErrorDetails details) {
                Logger.error(
                  'Flutter Error: ${details.exception}',
                  details.exception,
                  details.stack,
                );

                return Material(
                  child: Container(
                    color: Theme.of(context).colorScheme.error,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.onError,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Something went wrong',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onError,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please restart the app',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onError,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              };

              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
