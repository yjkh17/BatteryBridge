import SwiftUI

@main
struct BatteryBridgeApp: App {
    @StateObject private var browser: BatteryBrowser

    init() {
        let batteryBrowser = BatteryBrowser()
        _browser = StateObject(wrappedValue: batteryBrowser)
        batteryBrowser.startBrowsing()
    }
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(browser)
        } label: {
            if browser.isConnected {
                HStack(spacing: 4) {
                    Image(systemName: "iphone")
                        .imageScale(.medium)
                        .foregroundColor(batteryColor)
                        .symbolEffect(.bounce, value: browser.batteryLevel)
                    Text("\(browser.batteryLevel)%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(batteryColor)
                }
            } else {
                Image(systemName: "iphone.slash")
                    .imageScale(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .menuBarExtraStyle(.window)
    }
    
    private var batteryIcon: String {
        let level = browser.batteryLevel
        switch level {
        case 0..<25: return "battery.25"
        case 25..<50: return "battery.50"
        case 50..<75: return "battery.75"
        default: return browser.batteryLevel >= 95 ? "battery.100.bolt" : "battery.100"
        }
    }
    
    private var batteryColor: Color {
        let level = browser.batteryLevel
        switch level {
        case 0..<15: return .red
        case 15..<25: return .orange
        default: return .green
        }
    }
}
