//
//  ChaosManager.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

#if DEBUG

import Foundation
import SwiftUI

/// Manages chaos testing - simulating failures for hardening app logic
/// Only available in DEBUG builds
@MainActor
@Observable
final class ChaosManager {
    
    // MARK: - Singleton
    
    static let shared = ChaosManager()
    
    // MARK: - Chaos Toggles
    
    /// Simulate network failures
    var simulateNetworkFailure: Bool = false
    
    /// Simulate slow network (adds artificial delay)
    var simulateSlowNetwork: Bool = false
    
    /// Delay to add when simulating slow network (in seconds)
    var slowNetworkDelay: TimeInterval = 3.0
    
    /// Simulate corrupted/invalid data responses
    var simulateCorruptData: Bool = false
    
    /// Simulate expired authentication token
    var simulateExpiredToken: Bool = false
    
    /// Simulate random failures (throws errors randomly)
    var simulateRandomFailures: Bool = false
    
    /// Probability of random failure (0.0 - 1.0)
    var randomFailureProbability: Double = 0.3
    
    /// Simulate storage being full
    var simulateStorageFull: Bool = false
    
    // MARK: - Properties
    
    /// Whether any chaos mode is active
    var isChaosActive: Bool {
        simulateNetworkFailure ||
        simulateSlowNetwork ||
        simulateCorruptData ||
        simulateExpiredToken ||
        simulateRandomFailures ||
        simulateStorageFull
    }
    
    /// Number of active chaos modes
    var activeChaosCount: Int {
        var count = 0
        if simulateNetworkFailure { count += 1 }
        if simulateSlowNetwork { count += 1 }
        if simulateCorruptData { count += 1 }
        if simulateExpiredToken { count += 1 }
        if simulateRandomFailures { count += 1 }
        if simulateStorageFull { count += 1 }
        return count
    }
    
    // MARK: - Initialization
    
    private init() {
        // Only enable chaos features if flag is on
        if !FeatureFlagManager.shared.isEnabled(.enableChaosMode) {
            resetAll()
        }
    }
    
    // MARK: - Public Methods
    
    /// Apply network chaos (call before network operations)
    func applyNetworkChaos() async throws {
        guard FeatureFlagManager.shared.isEnabled(.enableChaosMode) else { return }
        
        // Check for network failure
        if simulateNetworkFailure {
            logChaos("Network failure triggered")
            throw ChaosError.networkFailure
        }
        
        // Check for random failure
        if simulateRandomFailures && shouldRandomlyFail() {
            logChaos("Random network failure triggered")
            throw ChaosError.randomFailure
        }
        
        // Apply slow network delay
        if simulateSlowNetwork {
            logChaos("Slow network delay: \(slowNetworkDelay)s")
            try await Task.sleep(for: .seconds(slowNetworkDelay))
        }
    }
    
    /// Apply auth chaos (call during authentication)
    func applyAuthChaos() throws {
        guard FeatureFlagManager.shared.isEnabled(.enableChaosMode) else { return }
        
        if simulateExpiredToken {
            logChaos("Token expiration triggered")
            throw ChaosError.expiredToken
        }
    }
    
    /// Apply data chaos (call when decoding data)
    func applyDataChaos<T: Decodable>(_ data: Data) throws -> T {
        guard FeatureFlagManager.shared.isEnabled(.enableChaosMode) else {
            return try JSONDecoder().decode(T.self, from: data)
        }
        
        if simulateCorruptData {
            logChaos("Corrupt data triggered")
            throw ChaosError.corruptData
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    /// Apply storage chaos (call during persistence operations)
    func applyStorageChaos() throws {
        guard FeatureFlagManager.shared.isEnabled(.enableChaosMode) else { return }
        
        if simulateStorageFull {
            logChaos("Storage full triggered")
            throw ChaosError.storageFull
        }
        
        if simulateRandomFailures && shouldRandomlyFail() {
            logChaos("Random storage failure triggered")
            throw ChaosError.randomFailure
        }
    }
    
    /// Reset all chaos modes
    func resetAll() {
        simulateNetworkFailure = false
        simulateSlowNetwork = false
        simulateCorruptData = false
        simulateExpiredToken = false
        simulateRandomFailures = false
        simulateStorageFull = false
        logChaos("All chaos modes disabled")
    }
    
    /// Enable all chaos modes (for stress testing)
    func enableAll() {
        simulateSlowNetwork = true
        simulateRandomFailures = true
        logChaos("Multiple chaos modes enabled")
    }
    
    // MARK: - Private Methods
    
    private func shouldRandomlyFail() -> Bool {
        Double.random(in: 0...1) < randomFailureProbability
    }
    
    private func logChaos(_ message: String) {
        print("[Chaos] ⚡️ \(message)")
    }
}

// MARK: - Chaos Errors

enum ChaosError: LocalizedError {
    case networkFailure
    case expiredToken
    case corruptData
    case storageFull
    case randomFailure
    
    var errorDescription: String? {
        switch self {
        case .networkFailure:
            return "[CHAOS] Simulated network failure"
        case .expiredToken:
            return "[CHAOS] Simulated token expiration"
        case .corruptData:
            return "[CHAOS] Simulated data corruption"
        case .storageFull:
            return "[CHAOS] Simulated storage full"
        case .randomFailure:
            return "[CHAOS] Simulated random failure"
        }
    }
}

// MARK: - Chaos Banner View

/// Warning banner when chaos mode is active
struct ChaosBanner: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let chaosManager = ChaosManager.shared
    
    var body: some View {
        if chaosManager.isChaosActive {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.yellow)
                
                Text("Chaos Mode Active (\(chaosManager.activeChaosCount) modes)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Disable") {
                    chaosManager.resetAll()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.purple.opacity(0.9))
            .foregroundStyle(.white)
        }
    }
}

#endif
