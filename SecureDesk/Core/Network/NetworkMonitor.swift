//
//  NetworkMonitor.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation
import Network
import Combine

/// Monitors network connectivity status
/// Uses NWPathMonitor for real-time updates
@MainActor
@Observable
final class NetworkMonitor {
    
    // MARK: - Singleton
    
    static let shared = NetworkMonitor()
    
    // MARK: - Properties
    
    /// Whether the device has network connectivity
    private(set) var isConnected: Bool = true
    
    /// Current connection type
    private(set) var connectionType: ConnectionType = .unknown
    
    /// Whether the connection is expensive (cellular)
    private(set) var isExpensive: Bool = false
    
    /// Whether the connection is constrained (Low Data Mode)
    private(set) var isConstrained: Bool = false
    
    /// Last time connectivity changed
    private(set) var lastStatusChange: Date = Date()
    
    // MARK: - Private Properties
    
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var isMonitoring = false
    
    // MARK: - Initialization
    
    init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "com.securedesk.networkmonitor", qos: .utility)
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring network status
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handlePathUpdate(path)
            }
        }
        
        monitor.start(queue: queue)
        logStatus("Started monitoring")
    }
    
    /// Stop monitoring network status
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        monitor.cancel()
        logStatus("Stopped monitoring")
    }
    
    /// Get a one-time connectivity check
    func checkConnectivity() async -> Bool {
        return isConnected
    }
    
    /// Wait for connectivity (with timeout)
    func waitForConnectivity(timeout: TimeInterval = 30) async -> Bool {
        if isConnected { return true }
        
        // Poll for connectivity
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            try? await Task.sleep(for: .milliseconds(500))
            if isConnected { return true }
        }
        
        return false
    }
    
    // MARK: - Private Methods
    
    private func handlePathUpdate(_ path: NWPath) {
        let wasConnected = isConnected
        
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        connectionType = determineConnectionType(path)
        
        if wasConnected != isConnected {
            lastStatusChange = Date()
            postNotification()
            logStatus(isConnected ? "Connected" : "Disconnected")
        }
    }
    
    private func determineConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.status == .satisfied {
            return .other
        } else {
            return .none
        }
    }
    
    private func postNotification() {
        NotificationCenter.default.post(
            name: .networkStatusDidChange,
            object: self,
            userInfo: ["isConnected": isConnected]
        )
    }
    
    private func logStatus(_ message: String) {
        #if DEBUG
        if FeatureFlagManager.shared.isVerboseLoggingEnabled {
            print("[Network] \(message) - Type: \(connectionType.displayName)")
        }
        #endif
    }
}

// MARK: - Connection Type

enum ConnectionType: String, Sendable {
    case wifi
    case cellular
    case ethernet
    case other
    case none
    case unknown
    
    var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .other: return "Other"
        case .none: return "No Connection"
        case .unknown: return "Unknown"
        }
    }
    
    var icon: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .ethernet: return "cable.connector"
        case .other: return "network"
        case .none: return "wifi.slash"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkStatusDidChange = Notification.Name("networkStatusDidChange")
}

// MARK: - SwiftUI Environment

import SwiftUI

private struct NetworkMonitorKey: EnvironmentKey {
    @MainActor static let defaultValue = NetworkMonitor.shared
}

extension EnvironmentValues {
    var networkMonitor: NetworkMonitor {
        get { self[NetworkMonitorKey.self] }
        set { self[NetworkMonitorKey.self] = newValue }
    }
}
