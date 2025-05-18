import Network
import UIKit

class BatteryBroadcaster: ObservableObject {
    private var listener: NWListener?
    
    func startBroadcasting() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        do {
            listener = try NWListener(using: parameters, on: BatteryBridgeConstants.port)
            listener?.service = NWListener.Service(type: BatteryBridgeConstants.serviceType)
            
            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    print("Listener ready")
                case .failed(let error):
                    print("Listener failed: \(error)")
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                connection.stateUpdateHandler = { state in
                    if state == .ready {
                        self?.sendBatteryLevel(connection: connection)
                    }
                }
                connection.start(queue: .main)
            }
            
            listener?.start(queue: .main)
        } catch {
            print("Failed to create listener: \(error)")
        }
    }
    
    private func sendBatteryLevel(connection: NWConnection) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = Int(UIDevice.current.batteryLevel * 100)
        guard let data = "\(level)".data(using: .utf8) else { return }
        
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Failed to send battery level: \(error)")
            }
        })
    }
}