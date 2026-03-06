# Bluetooth Service - Testing & Troubleshooting Guide

## 🧪 Quick Testing Steps

### Step 1: Build & Run on Android Device
```bash
flutter clean
flutter pub get
flutter run
```

### Step 2: Check Permissions
When app starts, you should see logs like:
```
I  Permission bluetooth: granted
I  Permission bluetoothScan: granted
I  Permission bluetoothConnect: granted
I  Permission bluetoothAdvertise: granted
I  Permission locationWhenInUse: granted
I  Permission nearbyWifiDevices: granted
```

If location permission is denied, the app will retry once automatically.

### Step 3: Test Device Discovery
1. Open app on Device A
2. Tap Home → press network icon or click "Discover" in Contacts
3. Wait ~5 seconds
4. Device B should appear in discovered devices list
5. Tap Device B to connect

**Expected Logs**:
```
N  Starting Nearby Connections discovery
N  Found Nearby endpoint: OffGrid_Bold_Wolf_456 (abc123def)
N  Updated discovered devices: 1
N  Requesting connection to: OffGrid_Bold_Wolf_456
N  Connection initiated with: OffGrid_Bold_Wolf_456
N  Connected successfully to: abc123def
```

### Step 4: Test Message Sending
1. Both devices connected
2. Open chat with connected device
3. Type message, tap send
4. Watch logs for retry attempts:
```
N  Sending message (attempt 1/3) to: endpoint123
→ Success: I  Successfully sent message to: endpoint123

OR if it fails:
W  Send attempt 1 failed for endpoint123: timeout error
→ INFO Retrying in 1000ms...
→ (retries with 2s, then 4s delays)
```

### Step 5: Test App Pause/Resume
1. During active discovery/messaging
2. Press system Home button (app pauses)
3. Check logs for `App paused` message
4. Bring app back (hit Recent/recents)
5. Check logs for `App resumed` message
6. Verify Bluetooth still working

---

## 🔍 Troubleshooting Guide

### Issue: "Required permissions not granted"

**Symptoms**:
```
E  Required permissions not granted
E  Location permission required for Nearby Connections
```

**Solutions**:
1. Go to Settings → Apps → OffGrid Messenger → Permissions
2. Grant all permissions:
   - Location (required for Nearby Connections)
   - Nearby WiFi devices (Android 12+)
   - Bluetooth (connect, scan, advertise)
3. If still failing on first launch:
   - Restart phone
   - Uninstall app completely
   - Reinstall and grant permissions when prompted

**Why**: Android 12+ requires explicit permission handling. Location is needed even for Bluetooth on some devices due to SSID discovery implications.

---

### Issue: "No Nearby Connections discovery available"

**Symptoms**:
```
N  Found 0 devices
(stays at 0 even with nearby devices)
```

**Solutions**:
1. Verify both devices have:
   - Bluetooth enabled in system settings
   - Location enabled (required for Nearby Connections)
   - Wi-Fi enabled OR Bluetooth enabled for nearby detection
   
2. Check device is advertising:
   - Look for logs: `I  Starting Nearby Connections advertising`
   - If not there, app might not have initialized

3. Verify service ID matches:
   - In `bluetooth_service.dart`, check `_serviceId = 'com.example.offgrid_messenger'`
   - Both devices must use same service ID to discover each other

---

### Issue: "Connection timeout - device too far or unavailable"

**Symptoms**:
```
W  Send attempt 1 failed for endpoint_XYZ: Connection timeout
W  Send attempt 2 failed for endpoint_XYZ: Connection timeout
W  Send attempt 3 failed for endpoint_XYZ: Connection timeout
E  Failed to send message after 3 attempts
```

**Solutions**:
1. Physical proximity:
   - Bring devices closer (within 10-50 meters)
   - Remove obstacles between devices
   - Avoid metal/water barriers

2. Signal strength:
   - Move to open area
   - Check Bluetooth signal not overloaded (move away from WiFi router interference)

3. Device responsiveness:
   - Check target device isn't in sleep mode
   - Ensure app still running in background
   - Press home button to keep app active

---

### Issue: "Max connections reached, rejecting"

**Symptoms**:
```
W  Max connections (8) reached, rejecting: new_device_123
```

**Solutions**:
1. This is normal and expected
2. Disconnect a device first:
   - Go to Contacts → Connected → swipe/tap disconnect
   - Wait 1-2 seconds

3. Then try connecting new device

**Why**: P2P_CLUSTER strategy only supports 8 simultaneous connections. This is a Nearby Connections library limitation.

---

### Issue: "Invalid empty device name, rejecting"

**Symptoms**:
```
W  Invalid device name, rejecting: endpoint_XYZ
```

**Solutions**:
1. Device name might be empty (unlikely)
2. Check in DeviceUtils that name generation is working:
   ```
   Device Name: OffGrid_Swift_Eagle_123
   ```

3. If still failing, add debug log to see actual name:
   - Edit `bluetooth_service.dart` line ~180
   - Change rejection to log the actual name first

---

### Issue: Messages not being received

**Symptoms**:
- Send message: ✓ Sent successfully
- Recipient: ✗ Message doesn't appear
- Check logs: No "Received message" on recipient side

**Solutions**:

1. **Check connection state**:
   ```dart
   // In app, print Bluetooth status
   print(BluetoothService().getConnectionStatus());
   ```
   
2. **Verify message handler**:
   - Check `NetworkStateProvider` initialization
   - Should have stream listeners active
   - Look for logs: `I  Received message from: endpoint_XYZ`

3. **Check MessageProvider**:
   - Might not be connected to Bluetooth service yet
   - Need to wire up message reception callback

4. **Temporary workaround**:
   - For now, messages only work in memory/UI
   - Full network transmission comes after routing is implemented

---

### Issue: App crashes at startup

**Symptoms**:
```
E  Flutter Error: [exception details]
```

**Solutions**:
1. Check logcat for full error:
   ```bash
   flutter logs
   ```

2. Most common causes:
   - Missing import in bluetooth_service.dart
   - Widget binding issue in main.dart
   - Context issue in providers

3. If widget binding error:
   - Verify `WidgetsFlutterBinding.ensureInitialized()` is first in main()
   - Check `BiographyObserver` mixin spelling

---

## 📊 Performance Monitoring

### Key Metrics to Monitor

1. **Connection Success Rate**:
   ```
   Successful connections / Total connection attempts = ?%
   Target: >95%
   ```

2. **Message Delivery**:
   ```
   (Sent - Failed) / Sent = ?%
   Target: >99% (with retries)
   ```

3. **Discovery Time**:
   - Time from "Start Discovery" to first device found
   - Target: <5 seconds

4. **Connection Time**:
   - Time from connection request to connected state
   - Target: <10 seconds

### Enable Detailed Logging

In `core/utils/logger.dart`, enable all log levels:
```dart
// For verbose debugging
developer.log(message, level: 300); // Fine-grained debug
```

---

## 🔧 Advanced Debugging

### Enable Nearby Connections Debug Logging
```dart
// In BluetoothService.initialize()
// Nearby Connections might have native logging
// Check Android logcat for additional details:
adb logcat | grep Nearby
```

### Monitor Bluetooth State
```bash
# In terminal, check Bluetooth state
adb shell dumpsys bluetooth_manager

# Check Nearby Connections service
adb shell dumpsys activity services com.google.android.gms
```

### Simulate Network Issues
1. Airplane mode: Turns off all wireless
2. Move devices apart: Tests range limitations
3. Heavy WiFi usage: Can interfere with Bluetooth
4. Other Bluetooth devices: Causes congestion

---

## 📋 Pre-Release Checklist

Before declaring Bluetooth service production-ready:

- [ ] Tested on Android 11 device
- [ ] Tested on Android 12 device  
- [ ] Tested on Android 13 device
- [ ] Tested 2-device connection
- [ ] Tested 4-device connection
- [ ] Tested 8-device connection (max)
- [ ] Tested 9-device rejection
- [ ] Tested message send with poor signal
- [ ] Tested app pause/resume cycle
- [ ] Tested device discovery timeout
- [ ] Tested connection timeout
- [ ] Tested disconnection handling
- [ ] Verified no memory leaks (kill app, restart)
- [ ] Checked battery impact (leave running 30 min)
- [ ] Permission request retry works
- [ ] Error messages are user-friendly

---

## 📞 Getting Help

If you encounter issues not covered here:

1. **Check the logs**: Enable verbose logging and look for exact error message
2. **Verify devices**: Both phones have same app version
3. **Test hardware**: Try different device pairs
4. **Check environment**: Clear space, no obstructions
5. **Restart everything**: Apps, Bluetooth, phones

---

*Last Updated: March 3, 2026*
