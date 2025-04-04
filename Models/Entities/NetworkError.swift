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
                comment: "Error when server error occured")
        case .noRelatedPopsFound(let query):
            return NSLocalizedString(
                "Hmm, nothing here",
                comment: "Hmm, no pops found for \"\(query)\"")
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
                comment: "Server Error")
        case .noRelatedPopsFound(let query):
            return NSLocalizedString(
                "Hmm, nothing here",
                comment: "Hmm, no pops found for \"\(query)\". Try searching another subject if known!")
        }
    }
}

enum AuthError: Error {
    case invalidCredentials
    case jwtTokenNotFound
    
    var localizedDescription: String {
        switch self {
        case .invalidCredentials:
            return "The email or password you entered is incorrect. Please try again."
        case .jwtTokenNotFound:
            return "Your session has expired. Please sign in again."
        }
    }
}
