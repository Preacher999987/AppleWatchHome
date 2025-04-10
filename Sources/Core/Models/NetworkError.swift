//
//  NetworkError.swift
//  FunKollector
//
//  Created by Home on 03.04.2025.
//

import Foundation

enum NetworkError: Error {
    case invalidQuery
    case invalidURL
    case noData
    case decodingFailed(Error)
    case requestFailed(Error)
    case unauthorized
    case serverError
    case noRelatedPopsFound(String)
    case noSearchResults(String)  // New case
    
    var localizedDescription: String {
        switch self {
        case .invalidQuery:
            return NSLocalizedString(
                "Invalid query provided",
                comment: "Error when input validation fails"
            )
        case .invalidURL:
            return NSLocalizedString(
                "Invalid request URL",
                comment: "Error when URL construction fails"
            )
        case .noData:
            return NSLocalizedString(
                "No data received from server",
                comment: "Error when response contains no data"
            )
        case .decodingFailed(let error):
            return String(
                format: NSLocalizedString(
                    "Data format error: %@",
                    comment: "Error when JSON decoding fails (shows underlying error)"
                ),
                error.localizedDescription
            )
        case .requestFailed(let error):
            return String(
                format: NSLocalizedString(
                    "Network request failed: %@",
                    comment: "Error when network call fails (shows underlying error)"
                ),
                error.localizedDescription
            )
        case .unauthorized:
            return NSLocalizedString(
                "Authentication required",
                comment: "Error when missing valid credentials"
            )
        case .serverError:
            return NSLocalizedString(
                "Server Error",
                comment: "Error when server error occurred"
            )
        case .noRelatedPopsFound(let query):
            return NSLocalizedString(
                "Hmm, nothing here",
                comment: "Hmm, no pops found for \"\(query)\""
            )
        case .noSearchResults(let query):
            return String(
                format: NSLocalizedString(
                    "No results found for '%@'",
                    comment: "Error when search returns empty results"
                ),
                query
            )
        }
    }
    
    // Optional: More user-friendly versions that hide technical details
    var userFacingMessage: String {
        switch self {
        case .invalidQuery, .invalidURL:
            return NSLocalizedString(
                "We encountered a problem with your request. Please try again.",
                comment: "Generic input error message"
            )
        case .noData:
            return NSLocalizedString(
                "The server returned an empty response. Please try again later.",
                comment: "Empty response error"
            )
        case .decodingFailed:
            return NSLocalizedString(
                "We couldn't understand the server response. Please contact support.",
                comment: "Data parsing error"
            )
        case .requestFailed:
            return NSLocalizedString(
                "We're having trouble connecting to our servers. Please check your internet connection.",
                comment: "Network failure message"
            )
        case .unauthorized:
            return NSLocalizedString(
                "Your session has expired. Please sign in again.",
                comment: "Authentication error"
            )
        case .serverError:
            return NSLocalizedString(
                "We're experiencing server issues. Please try again later.",
                comment: "Server Error"
            )
        case .noRelatedPopsFound(let query):
            return NSLocalizedString(
                "Hmm, nothing here",
                comment: "Hmm, no pops found for \"\(query)\""
            )
        case .noSearchResults:
            return NSLocalizedString(
                "No items matched your search. Try different keywords or check back later.",
                comment: "User message when search returns no results"
            )
        }
    }
}

enum AuthError: Error {
    case invalidCredentials
    case jwtTokenNotFound
    case userNotAuthenticated
    case sessionExpired
    case permissionDenied
    case accountLocked
    case verificationRequired
    
    var localizedDescription: String {
        switch self {
        case .invalidCredentials:
            return "The email or password you entered is incorrect. Please try again."
        case .jwtTokenNotFound:
            return "Your session has expired. Please sign in again."
        case .userNotAuthenticated:
            return "You need to be logged in to access this content. Please sign in."
        case .sessionExpired:
            return "Your session has timed out. Please sign in again."
        case .permissionDenied:
            return "You don't have permission to access this resource."
        case .accountLocked:
            return "Your account has been temporarily locked. Please try again later or contact support."
        case .verificationRequired:
            return "Please verify your email address before continuing."
        }
    }
    
    // Optional: User-facing messages that might hide technical details
    var userFacingMessage: String {
        switch self {
        case .invalidCredentials, .jwtTokenNotFound, .sessionExpired:
            return "We couldn't authenticate your request. Please sign in again."
        case .userNotAuthenticated:
            return "Please sign in to continue."
        case .permissionDenied:
            return "Access to this content is restricted."
        case .accountLocked:
            return "Account access temporarily unavailable."
        case .verificationRequired:
            return "Account verification needed."
        }
    }
}
