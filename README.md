# BatteryBridge

BatteryBridge consists of two Swift apps:
- **BatteryBridge** (macOS)
- **BatteryBridge IOS** (iOS)

The iOS app broadcasts the current battery level using Bonjour on port 54321. The macOS app listens for that broadcast and shows the iOS device's battery level in the macOS menu bar. iOS typically reports battery level in 5% increments and the app reflects that limitation.

## Prerequisites
- Xcode 15 or later
- macOS deployment target: 15.4
- iOS deployment target: 18.4

## Building and Running
1. Open `BatteryBridge.xcodeproj` in Xcode.
2. To run the macOS menu bar app:
   - Select the **BatteryBridge** scheme.
   - Build and run (⌘R). The battery level from your paired iOS device will appear in the menu bar once detected.
3. To run the iOS broadcaster:
   - Select the **BatteryBridge IOS** scheme.
   - Choose a connected iOS device or simulator.
   - Build and run (⌘R). Leave the app in the foreground so it can broadcast the battery level.

Run the iOS app first. It will advertise a Bonjour service named `BatteryBridge` on port `54321`. After launching the macOS app, it will automatically discover the service on your local network and display the reported battery percentage in the menu bar.

## License
This project is licensed under the [MIT License](LICENSE).
