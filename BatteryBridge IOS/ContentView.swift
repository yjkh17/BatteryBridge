import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var broadcaster = BatteryBroadcaster()
    @State private var actualBatteryLevel: Float = 0.0
    @State private var batteryObserver: NSObjectProtocol?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: batterySystemImage)
                        .imageScale(.large)
                        .font(.system(size: 64))
                        .foregroundColor(batteryColor)
                        .symbolEffect(.bounce, value: actualBatteryLevel)
                }
                
                Text("\(Int(actualBatteryLevel * 100))%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(batteryColor)
                
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(broadcaster.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(broadcaster.isConnected ? "Connected to Mac" : "Not connected")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("Keep app in foreground")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("Battery Bridge")
            .onAppear {
                startMonitoring()
            }
            .onDisappear {
                stopMonitoring()
            }
        }
    }

    private func startMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        updateBatteryLevel()
        broadcaster.startBroadcasting()

        // Set up battery monitoring
        batteryObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            updateBatteryLevel()
        }
    }

    private func stopMonitoring() {
        if let observer = batteryObserver {
            NotificationCenter.default.removeObserver(observer)
            batteryObserver = nil
        }
    }
    
    private func updateBatteryLevel() {
        let level = UIDevice.current.batteryLevel
        actualBatteryLevel = level < 0 ? 1.0 : level
    }
    
    private var batterySystemImage: String {
        let level = actualBatteryLevel
        switch level {
        case 0..<0.25: return "battery.25"
        case 0.25..<0.50: return "battery.50"
        case 0.50..<0.75: return "battery.75"
        default: return "battery.100"
        }
    }
    
    private var batteryColor: Color {
        let level = actualBatteryLevel
        switch level {
        case 0..<0.15: return .red
        case 0.15..<0.25: return .orange
        default: return .green
        }
    }
}
