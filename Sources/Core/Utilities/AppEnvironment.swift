//
//  Environment.swift
//  FunKollector
//
//  Created by Home on 15.04.2025.
//

import Foundation

enum AppEnvironment {
    case development
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}

enum APIPath {
    // MARK: - Authentication
    case authLogin
    case authRegister
    case resetPassword
    case tokenSignIn
    
    // MARK: - Collection Management
    case manageCollection
    case userPhotos
    case userCollection
    case lookup
    
    // MARK: - Gallery
    case galleryImages
    case relatedItems
    
    // MARK: - Images
    case userPhotosBase
    case photoAnalysis
    
    // MARK: - Parameterized Paths
    case galleryImagesWithId(String)
    case userPhotosWithId(String)
    case relatedItemsWithQuery(String)
    
    // MARK: - Path Construction
    func with(_ parameter: String) -> APIPath {
        switch self {
        case .galleryImages:
            return .galleryImagesWithId(parameter)
        case .userPhotos:
            return .userPhotosWithId(parameter)
        case .relatedItems:
            return .relatedItemsWithQuery(parameter)
        default:
            return self
        }
    }
    
    // MARK: - Path Resolution
    var path: String {
        switch self {
        // Authentication
        case .authLogin:
            return "/auth/login"
        case .authRegister:
            return "/auth/register"
        case .resetPassword:
            return "/auth/reset-password"
        case .tokenSignIn:
            return "/auth/token-signin"
            
        // Collection Management
        case .manageCollection:
            return "/api/manage-collection"
        case .userPhotos:
            return "/api/add-user-photos"
        case .userPhotosWithId(let uid):
            return "/api/add-user-photos/\(uid)"
            
        // Gallery
        case .galleryImages:
            return "/api/gallery"
        case .galleryImagesWithId(let id):
            return "/api/gallery/\(id)"
        case .relatedItems:
            return "/api/related"
        case .relatedItemsWithQuery(let query):
            return "/api/related/\(query)"
            
        // Images
        case .userPhotosBase:
            return "/api/collectibles/user-photos"
        case .userCollection:
            return "/api/user-collection"
        case .lookup:
            return "/api/lookup"
        case .photoAnalysis:
            return "/api/analyse"
        }
    }
    
    // MARK: - Query Item Support
    func with(queryItems: [URLQueryItem]) -> (path: APIPath, queryItems: [URLQueryItem]) {
        return (self, queryItems)
    }
}

struct Config {
    static func baseURL(for environment: AppEnvironment) -> String {
        guard let dict = Bundle.main.infoDictionary?["APIEndpoints"] as? [String: String],
              let url = dict[environment == .development ? "Development" : "Production"] else {
            fatalError("Missing API base URL in Info.plist")
        }
        return url
    }
}
