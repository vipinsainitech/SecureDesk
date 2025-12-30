//
//  AppError.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Unified error type for the application
/// Provides user-friendly messages and retry suggestions
enum AppError: LocalizedError, Equatable {
    
    // MARK: - Network Errors
    
    case networkUnavailable
    case networkTimeout
    case networkError(String)
    
    // MARK: - Authentication Errors
    
    case invalidCredentials
    case sessionExpired
    case unauthorized
    case authenticationRequired
    
    // MARK: - Data Errors
    
    case dataNotFound
    case dataCorrupted
    case decodingFailed
    case encodingFailed
    
    // MARK: - Persistence Errors
    
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case storageFull
    
    // MARK: - Validation Errors
    
    case validationFailed(String)
    case invalidInput(field: String, reason: String)
    
    // MARK: - Server Errors
    
    case serverError(Int, String?)
    case serviceUnavailable
    case rateLimited
    
    // MARK: - Unknown
    
    case unknown(String)
    
    // MARK: - LocalizedError
    
    var errorDescription: String? { userMessage }
    
    // MARK: - Properties
    
    /// User-friendly message
    var userMessage: String {
        switch self {
        case .networkUnavailable:
            return "No internet connection available."
        case .networkTimeout:
            return "The request timed out. Please try again."
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidCredentials:
            return "Invalid email or password."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .unauthorized:
            return "You don't have permission to perform this action."
        case .authenticationRequired:
            return "Please sign in to continue."
        case .dataNotFound:
            return "The requested data was not found."
        case .dataCorrupted:
            return "The data appears to be corrupted."
        case .decodingFailed:
            return "Unable to process the response."
        case .encodingFailed:
            return "Unable to send the request."
        case .saveFailed(let detail):
            return "Failed to save: \(detail)"
        case .loadFailed(let detail):
            return "Failed to load: \(detail)"
        case .deleteFailed(let detail):
            return "Failed to delete: \(detail)"
        case .storageFull:
            return "Storage is full. Please free up space."
        case .validationFailed(let message):
            return message
        case .invalidInput(let field, let reason):
            return "\(field): \(reason)"
        case .serverError(let code, let message):
            return message ?? "Server error (\(code))"
        case .serviceUnavailable:
            return "The service is temporarily unavailable."
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .unknown(let message):
            return message
        }
    }
    
    /// Whether the operation can be retried
    var canRetry: Bool {
        switch self {
        case .networkUnavailable, .networkTimeout, .networkError,
             .serviceUnavailable, .rateLimited, .serverError:
            return true
        case .invalidCredentials, .unauthorized, .validationFailed, .invalidInput:
            return false
        default:
            return true
        }
    }
    
    /// Suggested action for the user
    var suggestedAction: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection"
        case .sessionExpired, .authenticationRequired:
            return "Sign in again"
        case .storageFull:
            return "Free up storage space"
        case .rateLimited:
            return "Wait a few moments before trying again"
        case .invalidInput:
            return "Correct the input and try again"
        default:
            return canRetry ? "Try again" : nil
        }
    }
    
    /// Error category for grouping
    var category: ErrorCategory {
        switch self {
        case .networkUnavailable, .networkTimeout, .networkError:
            return .network
        case .invalidCredentials, .sessionExpired, .unauthorized, .authenticationRequired:
            return .authentication
        case .dataNotFound, .dataCorrupted, .decodingFailed, .encodingFailed:
            return .data
        case .saveFailed, .loadFailed, .deleteFailed, .storageFull:
            return .persistence
        case .validationFailed, .invalidInput:
            return .validation
        case .serverError, .serviceUnavailable, .rateLimited:
            return .server
        case .unknown:
            return .unknown
        }
    }
    
    /// Debug information (only in DEBUG builds)
    var debugInfo: String {
        #if DEBUG
        return "\(category.rawValue): \(String(describing: self))"
        #else
        return ""
        #endif
    }
}

// MARK: - Error Category

enum ErrorCategory: String, CaseIterable {
    case network = "Network"
    case authentication = "Authentication"
    case data = "Data"
    case persistence = "Storage"
    case validation = "Validation"
    case server = "Server"
    case unknown = "Unknown"
    
    var icon: String {
        switch self {
        case .network: return "wifi.slash"
        case .authentication: return "lock"
        case .data: return "doc.badge.ellipsis"
        case .persistence: return "externaldrive.badge.xmark"
        case .validation: return "exclamationmark.circle"
        case .server: return "server.rack"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Error Mapping

extension AppError {
    
    /// Convert from NetworkError
    static func from(_ error: NetworkError) -> AppError {
        switch error {
        case .invalidURL, .invalidResponse:
            return .networkError(error.localizedDescription ?? "Invalid request")
        case .unauthorized:
            return .unauthorized
        case .forbidden:
            return .unauthorized
        case .notFound:
            return .dataNotFound
        case .validationError:
            return .validationFailed("Validation failed")
        case .rateLimited:
            return .rateLimited
        case .serverError(let code):
            return .serverError(code, nil)
        case .unexpectedStatusCode(let code):
            return .serverError(code, nil)
        case .decodingError(let message):
            return .decodingFailed
        case .encodingError:
            return .encodingFailed
        case .noConnection:
            return .networkUnavailable
        case .timeout:
            return .networkTimeout
        }
    }
    
    /// Convert from AuthError
    static func from(_ error: AuthError) -> AppError {
        switch error {
        case .invalidCredentials:
            return .invalidCredentials
        case .tokenExpired:
            return .sessionExpired
        case .noToken:
            return .authenticationRequired
        case .networkError(let message):
            return .networkError(message)
        case .serverError(let message):
            return .serverError(500, message)
        case .unknown:
            return .unknown("Authentication error")
        }
    }
    
    /// Convert from PersistenceError
    static func from(_ error: PersistenceError) -> AppError {
        switch error {
        case .encodingFailed:
            return .encodingFailed
        case .decodingFailed:
            return .decodingFailed
        case .writeFailed(let message):
            return .saveFailed(message)
        case .readFailed(let message):
            return .loadFailed(message)
        case .deleteFailed(let message):
            return .deleteFailed(message)
        case .notFound:
            return .dataNotFound
        case .invalidKey:
            return .validationFailed("Invalid key")
        case .storageFull:
            return .storageFull
        case .versionMismatch:
            return .dataCorrupted
        }
    }
}
