//
//  NetworkClient.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Generic async/await networking client for API requests
final class NetworkClient: Sendable {
    
    // MARK: - Properties
    
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // MARK: - Initialization
    
    init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder? = nil,
        encoder: JSONEncoder? = nil
    ) {
        self.baseURL = baseURL
        self.session = session
        
        // Configure decoder
        let jsonDecoder = decoder ?? JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        jsonDecoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = jsonDecoder
        
        // Configure encoder
        let jsonEncoder = encoder ?? JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonEncoder.keyEncodingStrategy = .useDefaultKeys
        self.encoder = jsonEncoder
    }
    
    // MARK: - Public Methods
    
    /// Execute a request and decode the response
    /// - Parameters:
    ///   - endpoint: API endpoint configuration
    ///   - token: Optional authentication token
    /// - Returns: Decoded response object
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        token: AuthToken? = nil
    ) async throws -> T {
        let request = try buildRequest(for: endpoint, token: token)
        
        if FeatureFlags.logNetworkRequests {
            logRequest(request)
        }
        
        let (data, response) = try await session.data(for: request)
        
        if FeatureFlags.logNetworkRequests {
            logResponse(response, data: data)
        }
        
        try validateResponse(response)
        
        return try decoder.decode(T.self, from: data)
    }
    
    /// Execute a request without expecting a response body
    /// - Parameters:
    ///   - endpoint: API endpoint configuration
    ///   - token: Optional authentication token
    func requestVoid(
        _ endpoint: APIEndpoint,
        token: AuthToken? = nil
    ) async throws {
        let request = try buildRequest(for: endpoint, token: token)
        
        if FeatureFlags.logNetworkRequests {
            logRequest(request)
        }
        
        let (_, response) = try await session.data(for: request)
        
        if FeatureFlags.logNetworkRequests {
            logResponse(response, data: nil)
        }
        
        try validateResponse(response)
    }
    
    /// Upload data (e.g., files)
    /// - Parameters:
    ///   - endpoint: API endpoint configuration
    ///   - data: Data to upload
    ///   - token: Optional authentication token
    /// - Returns: Decoded response object
    func upload<T: Decodable>(
        _ endpoint: APIEndpoint,
        data uploadData: Data,
        token: AuthToken? = nil
    ) async throws -> T {
        var request = try buildRequest(for: endpoint, token: token)
        request.httpBody = uploadData
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Private Methods
    
    private func buildRequest(
        for endpoint: APIEndpoint,
        token: AuthToken?
    ) throws -> URLRequest {
        // Build URL with path and query parameters
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
        
        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            urlComponents?.queryItems = queryItems
        }
        
        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeout
        
        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Custom headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Authentication
        if let token = token {
            request.setValue(token.authorizationHeader, forHTTPHeaderField: "Authorization")
        }
        
        // Body
        if let body = endpoint.body {
            request.httpBody = try encoder.encode(body)
        }
        
        return request
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 422:
            throw NetworkError.validationError
        case 429:
            throw NetworkError.rateLimited
        case 500...599:
            throw NetworkError.serverError(httpResponse.statusCode)
        default:
            throw NetworkError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }
    
    private func logRequest(_ request: URLRequest) {
        print("➡️ \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("   Body: \(bodyString.prefix(500))")
        }
    }
    
    private func logResponse(_ response: URLResponse, data: Data?) {
        if let httpResponse = response as? HTTPURLResponse {
            let emoji = (200...299).contains(httpResponse.statusCode) ? "✅" : "❌"
            print("\(emoji) \(httpResponse.statusCode) \(response.url?.absoluteString ?? "")")
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("   Response: \(responseString.prefix(500))")
            }
        }
    }
}

// MARK: - Network Errors

/// Errors that can occur during network operations
enum NetworkError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case validationError
    case rateLimited
    case serverError(Int)
    case unexpectedStatusCode(Int)
    case decodingError(String)
    case encodingError
    case noConnection
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Authentication required"
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .validationError:
            return "Validation error"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serverError(let code):
            return "Server error (\(code))"
        case .unexpectedStatusCode(let code):
            return "Unexpected response (\(code))"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .encodingError:
            return "Failed to encode request"
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        }
    }
}
