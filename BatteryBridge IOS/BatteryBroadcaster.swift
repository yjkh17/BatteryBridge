import Network
import UIKit
import os.log

class BatteryBroadcaster: ObservableObject {
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var broadcastTimer: Timer?
    @Published var isConnected = false
    @Published var lastError: String?
    private let logger = Logger(subsystem: "com.motherofbrand.BatteryBridge", category: "Broadcaster")
    private let broadcastInterval: TimeInterval = 1.0 // Interval between broadcasts for quick edits
    
    func startBroadcasting() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        setupListener()
        setupBroadcastTimer()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(batteryLevelDidChange),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        
        logger.info("Starting broadcaster with service: \(BatteryBridgeConstants.serviceType)")
    }
    
    private func setupListener() {
        let parameters = NWParameters.tcp
        parameters.includePeerToPeer = true
        parameters.allowLocalEndpointReuse = true
        
        do {
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: BatteryBridgeConstants.port))
            
            listener?.service = NWListener.Service(
                name: BatteryBridgeConstants.serviceName,
                type: BatteryBridgeConstants.serviceType,
                domain: BatteryBridgeConstants.domain,
                txtRecord: nil
            )
            
            listener?.stateUpdateHandler = { [weak self] state in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self.logger.info("✅ Listener is ready")
                        self.lastError = nil
                    case .failed(let error):
                        self.logger.error("❌ Listener failed: \(error.localizedDescription)")
                        self.lastError = error.localizedDescription
                        self.isConnected = false
                        self.retryListener()
                    case .cancelled:
                        self.logger.info("🛑 Listener cancelled")
                        self.isConnected = false
                    case .waiting(let error):
                        self.logger.warning("⏳ Listener waiting: \(error.localizedDescription)")
                        self.lastError = "Waiting: \(error.localizedDescription)"
                    default:
                        break
                    }
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            listener?.start(queue: .main)
            logger.info("🚀 Started advertising on port \(BatteryBridgeConstants.port)")
            
        } catch {
            logger.error("❌ Failed to create listener: \(error.localizedDescription)")
            lastError = error.localizedDescription
            retryListener()
        }
    }
    
    private func setupBroadcastTimer() {
        // Broadcast battery level every broadcastInterval seconds
        broadcastTimer?.invalidate()
        broadcastTimer = Timer.scheduledTimer(withTimeInterval: broadcastInterval, repeats: true) { [weak self] _ in
            self?.broadcastBatteryLevel()
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        logger.info("📥 New Mac connection attempt")
        
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self.logger.info("✅ Mac connection established")
                    self.connections.append(connection)
                    self.isConnected = true
                    self.broadcastBatteryLevel() // Send immediate update
                case .failed(let error):
                    self.logger.error("❌ Connection failed: \(error.localizedDescription)")
                    self.removeConnection(connection)
                case .cancelled:
                    self.logger.info("🛑 Connection cancelled")
                    self.removeConnection(connection)
                default:
                    break
                }
            }
        }
        
        connection.start(queue: .main)
    }
    
    private func removeConnection(_ connection: NWConnection) {
        if let index = connections.firstIndex(where: { $0 === connection }) {
            connections.remove(at: index)
            DispatchQueue.main.async {
                self.isConnected = !self.connections.isEmpty
            }
        }
    }
    
    private func retryListener() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.logger.info("🔄 Retrying listener setup...")
            self?.setupListener()
        }
    }
    
    @objc private func batteryLevelDidChange() {
        broadcastBatteryLevel()
    }
    
    private func broadcastBatteryLevel() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = Int(UIDevice.current.batteryLevel * 100)
        guard level >= 0 else { return }
        
        guard let data = "\(level)".data(using: .utf8) else { return }
        
        connections.forEach { connection in
            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                if let error = error {
                    self?.logger.error("❌ Failed to send battery level: \(error.localizedDescription)")
                } else {
                    self?.logger.debug("📤 Sent battery level: \(level)%")
                }
            })
        }
    }
    
    deinit {
        broadcastTimer?.invalidate()
        listener?.cancel()
        connections.forEach { $0.cancel() }
        NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
    }
}
