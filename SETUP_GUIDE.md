# OffGrid Messenger - Android Setup Guide

## Quick Start (Recommended Method)

### Option 1: Using VS Code (Easiest)
1. **Install VS Code** from https://code.visualstudio.com/
2. **Install Flutter Extension**:
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "Flutter" by Dart Code
   - Install it (this also installs Dart extension)

3. **Open Project**:
   - File → Open Folder
   - Select the `offgrid_messenger` folder

4. **Run the App**:
   - Make sure Android emulator is running
   - Press `F5` or go to Run → Start Debugging
   - Select your Android emulator when prompted

### Option 2: Command Line
```bash
cd offgrid_messenger
flutter run
```

## Prerequisites

### 1. Flutter SDK
- Download from https://flutter.dev/docs/get-started/install
- Add to PATH environment variable
- Verify with: `flutter doctor`

### 2. Android Studio & Emulator
- Install Android Studio
- Create an Android Virtual Device (AVD):
  - Tools → AVD Manager → Create Virtual Device
  - Choose Pixel 7 or similar (API 34 recommended)
  - Download system image
  - Start the emulator

### 3. Check Flutter Setup
```bash
flutter doctor
```
Should show:
- ✓ Flutter
- ✓ Android toolchain
- ✓ Connected device (your Android emulator)

## Android-Only Configuration

This project is optimized for **Android only**:
- ✅ Removed iOS, macOS, Linux, Windows, Web platforms
- ✅ Android-specific permissions for Bluetooth and WiFi
- ✅ Optimized build configuration
- ✅ Minimum SDK: Android 5.0 (API 21)
- ✅ Target SDK: Latest Android version

## Project Structure

```
offgrid_messenger/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── config/                   # App configuration
│   ├── core/                     # Core utilities
│   ├── data/                     # Data models
│   ├── domain/                   # Business logic
│   ├── presentation/             # UI screens & widgets
│   └── services/                 # Background services
├── android/                      # Android-specific code
├── ios/                         # iOS-specific code
├── assets/                      # Images, icons
└── pubspec.yaml                 # Dependencies
```

## Key Features Implemented

### ✅ Working Features
- **Home Screen** with network status
- **Chat Interface** with message history
- **Contacts Management** 
- **Network Discovery** simulation
- **Clean Architecture** (data/domain/presentation layers)
- **State Management** with Provider pattern
- **Material Design 3** theming
- **Error Handling** and logging

### 🚧 Mock Implementations
- Network discovery (simulated)
- Message routing (local only)
- Encryption (placeholder)
- Background services (disabled for stability)

## Running the App

### Step 1: Start Emulator
- Open Android Studio
- Tools → AVD Manager
- Click ▶️ next to your virtual device
- Wait for "Hello Android" screen

### Step 2: Install Dependencies
```bash
cd offgrid_messenger
flutter pub get
```

### Step 3: Run App
```bash
flutter run
```

Or use VS Code with F5.

## Troubleshooting

### Common Issues

#### 1. "No connected devices"
```bash
flutter devices
```
Should show your emulator. If not:
- Restart emulator
- Run `adb devices` to check connection

#### 2. Build Errors on Windows
If you see Kotlin compilation errors:
- **Solution**: Use VS Code instead of Android Studio
- **Alternative**: Move project to path without spaces

#### 3. "FlutterRunConfigurationType" Error
This is an Android Studio plugin issue:
- Use VS Code instead
- Or reinstall Flutter plugin in Android Studio

#### 4. Gradle Build Failed
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Performance Tips
- Use Release mode for better performance:
  ```bash
  flutter run --release
  ```
- Hot reload during development: Press `r` in terminal

## App Navigation

### Home Screen
- **Network Status**: Shows connection state
- **Quick Actions**: New message, contacts
- **Recent Conversations**: Message history

### Bottom Navigation
- **Home**: Dashboard and network status
- **Messages**: All conversations
- **Network**: Connected devices and discovery

### Key Screens
- **Chat Screen**: Send/receive messages
- **Contacts Screen**: Manage contacts
- **Network Map**: View mesh network topology

## Development Notes

### State Management
- Uses Provider pattern
- Three main providers:
  - `AppStateProvider`: App initialization
  - `NetworkStateProvider`: Network connections
  - `MessageProvider`: Message handling

### Data Models
- `Message`: Chat messages with routing info
- `Contact`: User contacts with device info
- `Route`: Network routing paths

### Architecture
```
Presentation Layer (UI)
    ↓
Domain Layer (Business Logic)
    ↓
Data Layer (Storage & Network)
```

## Next Steps for Development

### Priority Features
1. **Real Bluetooth/WiFi Direct** integration
2. **Message Encryption** implementation
3. **Background Services** for offline messaging
4. **File Sharing** capabilities
5. **Group Messaging** support

### Technical Debt
- Replace mock implementations with real networking
- Add comprehensive error handling
- Implement proper database schema
- Add unit and integration tests

## Contact

If you encounter issues:
1. Check this guide first
2. Run `flutter doctor` to verify setup
3. Try VS Code if Android Studio has issues
4. Check emulator is running with `flutter devices`

## Quick Commands Reference

```bash
# Check Flutter setup
flutter doctor

# List connected devices
flutter devices

# Install dependencies
flutter pub get

# Clean build
flutter clean

# Run app
flutter run

# Run in release mode
flutter run --release

# Hot reload (during development)
# Press 'r' in terminal

# Hot restart
# Press 'R' in terminal
```

---

**Happy Coding! 🚀**

The app is ready to run and all core UI components are working. Focus on the networking implementation next for real mesh functionality.