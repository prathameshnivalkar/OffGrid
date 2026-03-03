import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';

/// Global application state provider
class AppStateProvider extends ChangeNotifier {
  final String deviceId;
  final String deviceName;
  final bool isFirstLaunch;
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;
  String? _errorMessage;
  
  AppStateProvider({
    required this.deviceId,
    required this.deviceName,
    required this.isFirstLaunch,
  }) {
    _initialize();
  }
  
  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  
  /// Initialize the application state
  Future<void> _initialize() async {
    try {
      Logger.info('Initializing app state for device: $deviceName ($deviceId)');
      
      // Simulate initialization delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _isInitialized = true;
      _errorMessage = null;
      
      Logger.info('App state initialized successfully');
      notifyListeners();
    } catch (error, stackTrace) {
      Logger.error('Failed to initialize app state', error, stackTrace);
      _errorMessage = 'Failed to initialize application: $error';
      notifyListeners();
    }
  }
  
  /// Set theme mode
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      Logger.info('Theme mode changed to: ${mode.name}');
      notifyListeners();
    }
  }
  
  /// Toggle between light and dark theme
  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.light:
        setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        setThemeMode(ThemeMode.light);
        break;
    }
  }
  
  /// Clear error message
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
  
  /// Set error message
  void setError(String message) {
    _errorMessage = message;
    Logger.error('App state error: $message');
    notifyListeners();
  }
  
  /// Retry initialization
  Future<void> retryInitialization() async {
    _isInitialized = false;
    _errorMessage = null;
    notifyListeners();
    
    await _initialize();
  }
  
  @override
  void dispose() {
    Logger.info('App state provider disposed');
    super.dispose();
  }
}