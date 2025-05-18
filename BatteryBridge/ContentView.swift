import SwiftUI
import Network

struct ContentView: View {
    @EnvironmentObject var browser: BatteryBrowser
    
    var body: some View {
        VStack(spacing: 16) {
            if browser.isConnected {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: batteryIcon)
                            .imageScale(.large)
                            .font(.system(size: 24))
                            .foregroundColor(batteryColor)
                            .symbolEffect(.bounce, value: browser.batteryLevel)
                        
                        Text("\(browser.batteryLevel)%")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(batteryColor)
                    }
                    
                    Text("iPhone Connected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Searching for iPhone...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 200)
        .padding()
        .onAppear {
            browser.startBrowsing()
        }
    }
    
    private var batteryIcon: String {
        let level = browser.batteryLevel
        switch level {
        case 0..<25: return "battery.25"
        case 25..<50: return "battery.50"
        case 50..<75: return "battery.75"
        default: return "battery.100"
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
