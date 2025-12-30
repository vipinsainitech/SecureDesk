//
//  APIEndpoint.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Protocol defining an API endpoint configuration
protocol APIEndpoint: Sendable {
    /// HTTP method for the request
    var method: HTTPMethod { get }
    
    /// Path component (appended to base URL)
    var path: String { get }
    
    /// Optional query parameters
    var queryItems: [URLQueryItem]? { get }
    
    /// Optional custom headers
    var headers: [String: String]? { get }
    
    /// Optional request body (must be Encodable)
    var body: (any Encodable & Sendable)? { get }
    
    /// Request timeout in seconds
    var timeout: TimeInterval { get }
}

// MARK: - Default Implementations

extension APIEndpoint {
    var queryItems: [URLQueryItem]? { nil }
    var headers: [String: String]? { nil }
    var body: (any Encodable & Sendable)? { nil }
    var timeout: TimeInterval { 30.0 }
}

// MARK: - HTTP Method

/// HTTP methods supported by the API
enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Auth Endpoints

/// Authentication-related API endpoints
enum AuthEndpoint: APIEndpoint {
    case login(email: String, password: String)
    case logout
    case refreshToken(refreshToken: String)
    case forgotPassword(email: String)
    case resetPassword(token: String, newPassword: String)
    
    var method: HTTPMethod {
        switch self {
        case .login, .refreshToken, .forgotPassword, .resetPassword:
            return .post
        case .logout:
            return .post
        }
    }
    
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .logout:
            return "/auth/logout"
        case .refreshToken:
            return "/auth/refresh"
        case .forgotPassword:
            return "/auth/forgot-password"
        case .resetPassword:
            return "/auth/reset-password"
        }
    }
    
    var body: (any Encodable & Sendable)? {
        switch self {
        case .login(let email, let password):
            return LoginRequest(email: email, password: password)
        case .refreshToken(let refreshToken):
            return RefreshTokenRequest(refreshToken: refreshToken)
        case .forgotPassword(let email):
            return ["email": email]
        case .resetPassword(let token, let newPassword):
            return ["token": token, "password": newPassword]
        case .logout:
            return nil
        }
    }
}

// MARK: - User Endpoints

/// User-related API endpoints
enum UserEndpoint: APIEndpoint {
    case getCurrentUser
    case getUser(id: String)
    case updateProfile(user: User)
    case searchUsers(query: String)
    
    var method: HTTPMethod {
        switch self {
        case .getCurrentUser, .getUser, .searchUsers:
            return .get
        case .updateProfile:
            return .put
        }
    }
    
    var path: String {
        switch self {
        case .getCurrentUser:
            return "/users/me"
        case .getUser(let id):
            return "/users/\(id)"
        case .updateProfile:
            return "/users/me"
        case .searchUsers:
            return "/users/search"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .searchUsers(let query):
            return [URLQueryItem(name: "q", value: query)]
        default:
            return nil
        }
    }
    
    var body: (any Encodable & Sendable)? {
        switch self {
        case .updateProfile(let user):
            return user
        default:
            return nil
        }
    }
}

// MARK: - Item Endpoints

/// Item-related API endpoints
enum ItemEndpoint: APIEndpoint {
    case list(filter: ItemFilter?)
    case get(id: String)
    case create(item: Item)
    case update(item: Item)
    case delete(id: String)
    case updateStatus(id: String, status: ItemStatus)
    
    var method: HTTPMethod {
        switch self {
        case .list, .get:
            return .get
        case .create:
            return .post
        case .update:
            return .put
        case .delete:
            return .delete
        case .updateStatus:
            return .patch
        }
    }
    
    var path: String {
        switch self {
        case .list:
            return "/items"
        case .get(let id):
            return "/items/\(id)"
        case .create:
            return "/items"
        case .update(let item):
            return "/items/\(item.id)"
        case .delete(let id):
            return "/items/\(id)"
        case .updateStatus(let id, _):
            return "/items/\(id)/status"
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .list(let filter):
            guard let filter = filter else { return nil }
            var items: [URLQueryItem] = []
            
            if let status = filter.status {
                items.append(URLQueryItem(name: "status", value: status.rawValue))
            }
            if let priority = filter.priority {
                items.append(URLQueryItem(name: "priority", value: priority.rawValue))
            }
            if let query = filter.searchQuery {
                items.append(URLQueryItem(name: "q", value: query))
            }
            
            return items.isEmpty ? nil : items
        default:
            return nil
        }
    }
    
    var body: (any Encodable & Sendable)? {
        switch self {
        case .create(let item), .update(let item):
            return item
        case .updateStatus(_, let status):
            return ["status": status.rawValue]
        default:
            return nil
        }
    }
}
