import Foundation

enum BatteryBridgeConstants {
    // Use a simpler service type without dots at the end
    static let serviceType = "_batterybridge._tcp"
    static let serviceName = "BatteryBridge"
    static let domain = "local."
    // Use a port in the dynamic range that's less likely to be in use
    static let port: UInt16 = 54321
}
