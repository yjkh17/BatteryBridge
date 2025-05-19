import Network
import SwiftUI
import os.log

class BatteryBrowser: ObservableObject {
    @Published var batteryLevel: Int = 0
    @Published var isConnected: Bool = false
    
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private let logger = Logger(subsystem: "com.motherofbrand.BatteryBridge", category: "Browser")
    
    func startBrowsing() {
        logger.info("Starting to browse for iPhone...")
        setupBrowser()
    }
    
    private func setupBrowser() {
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        
        browser = NWBrowser(
            for: .bonjour(type: BatteryBridgeConstants.serviceType, domain: nil),
            using: parameters
        )
        
        browser?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.logger.info("Browser ready")
            case .waiting(let error):
                self?.logger.warning("Browser waiting: \(error.localizedDescription)")
            case .failed(let error):
                self?.logger.error("Browser failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
                self?.browser?.cancel()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.logger.info("Retrying browser...")
                    self?.setupBrowser()
                }
            default:
                break
            }
        }
        
        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            guard let endpoint = results.first?.endpoint else { return }
            self?.connect(to: endpoint)
        }
        
        browser?.start(queue: .main)
    }
    
    private func connect(to endpoint: NWEndpoint) {
        connection = NWConnection(to: endpoint, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self.isConnected = true
                    self.receiveData()
                case .waiting(let error):
                    self.logger.warning("Connection waiting: \(error.localizedDescription)")
                    self.isConnected = false
                    self.connection?.cancel()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        self?.logger.info("Retrying connection...")
                        self?.connect(to: endpoint)
                    }
                case .failed:
                    self.isConnected = false
                case .cancelled:
                    self.isConnected = false
                default:
                    break
                }
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
            } else {
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
            }
        }
    }
    
    deinit {
        browser?.cancel()
        connection?.cancel()
    }
}
