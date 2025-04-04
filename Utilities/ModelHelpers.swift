//
//  UserDefault.swift
//  Fun Kollector
//
//  Created by Home on 30.03.2025.
//

import SwiftUI
import CommonCrypto

class AppState: ObservableObject {
    @Published var openMyCollection = false 
    @Published var openRelated = false
    
    // Toolbar's navigationBar items visibility settings
    @Published var showCollectionButton = false
    @Published var showBackButton = true
    @Published var showAddToCollectionButton = false
    @Published var showPlusButton = false
    @Published var showEllipsisButton = false
    
    @Published var showHomeView = false
    
    @Published var showAuthView = false
    
    @Published var showProfileInfo = false
    
    @AppStorage("showSearchResultsInteractiveTutorial")
    var showSearchResultsInteractiveTutorial: Bool = true
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Primary app color (gold)
    static let appPrimary = Color(hex: "d3a754")
}

enum AddNewItemAction {
    case camera, manually, barcode, photoPicker
}

enum ManageCollectionMethod: String {
    case add, update, delete
}

// MARK: - Security Helpers
class CryptoUtils {
    static func hashPassword(_ password: String) -> String? {
        // 1. Prepare salt (in production, use unique salt per user)
        let salt = "your_client_salt".data(using: .utf8)!
        let passwordData = password.data(using: .utf8)!
        
        // 2. Convert Data to [UInt8] for CommonCrypto
        let saltBytes = [UInt8](salt)
        let passwordBytes = [UInt8](passwordData)
        
        // 3. Prepare output buffer
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        
        // 4. Perform key derivation
        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            String(password),          // Convert to C string
            passwordBytes.count,
            saltBytes,                // Pass the byte array
            saltBytes.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            100_000,                  // Iteration count
            &hash,
            hash.count
        )
        
        guard status == kCCSuccess else { return nil }
        return Data(hash).base64EncodedString()
    }
    
    static func generateNonce() -> String {
        // Generate a random string for each request
        let nonce = UUID().uuidString
//        KeychainHelper.save(nonce, for: "lastAuthNonce")
        return nonce
    }
    
    static func loadSSLPins() -> [Data]? {
        // Implement certificate pinning in production
        return nil
    }
}

extension URLRequest {
    mutating func addAuthorizationHeader() throws {
        if let jwtToken = KeychainHelper.jwtToken {
            self.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        } else {
            throw AuthError.jwtTokenNotFound
        }
    }
}
