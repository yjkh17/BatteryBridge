import Network
import SwiftUI
import Combine

class BatteryBrowser: ObservableObject {
    @Published var batteryLevel: Int = 0
    @Published var isConnected: Bool = false
    private var browser: NWBrowser?
    private var connection: NWConnection?
    
    func startBrowsing() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        browser = NWBrowser(for: .bonjour(type: BatteryBridgeConstants.serviceType, domain: nil), using: parameters)
        
        browser?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Browser ready")
            case .failed(let error):
                print("Browser failed: \(error)")
                self.isConnected = false
            default:
                break
            }
        }
        
        browser?.browseResultsChangedHandler = { results, _ in
            guard let endpoint = results.first?.endpoint else { return }
            self.connect(to: endpoint)
        }
        
        browser?.start(queue: .main)
    }
    
    private func connect(to endpoint: NWEndpoint) {
        connection = NWConnection(to: endpoint, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Connection ready")
                self?.isConnected = true
                self?.receiveData()
            case .failed:
                self?.isConnected = false
            default:
                break
            }
        }
        
        connection?.start(queue: .main)
    }
    
    private func receiveData() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 100) { [weak self] content, _, _, error in
            if let data = content,
               let string = String(data: data, encoding: .utf8),
               let level = Int(string) {
                DispatchQueue.main.async {
                    self?.batteryLevel = level
                }
            }
            
            if error == nil {
                self?.receiveData()
            }
        }
    }
}
