//
//  UserDefault.swift
//  Fun Kollector
//
//  Created by Home on 30.03.2025.
//

import SwiftUI
import CommonCrypto

class AppState: ObservableObject {
    static let defaultGridViewColumnCount = UIDevice.isIpad ? 4 : 2
    
    @Published var openMyCollection = false
    @Published var openRelated = false {
        didSet {
            if openRelated {
                resetGridViewSortAndFilter()
            }
        }
    }
    
    // Toolbar's navigationBar items visibility settings
    @Published var showBackButton = true
    @Published var showAddToCollectionButton = false {
        didSet {
            if showAddToCollectionButton {
                resetGridViewSortAndFilter()
                gridViewShowSections = true
            }
        }
    }
    @Published var showPlusButton = false
    @Published var showEllipsisButton = false
    
    @Published var showHomeView = false
    
    @Published var showAuthView = false
    
    @Published var showProfileInfo = false
    
    @Published var gridViewSortOption: SortOption = .series
    @Published var gridViewFilter: String? = nil
    @Published var gridViewColumnCount: Int = AppState.defaultGridViewColumnCount
    @Published var gridViewShowSections: Bool = false
    
    @AppStorage("showSearchResultsInteractiveTutorial")
    var showSearchResultsInteractiveTutorial: Bool = true
    
    func resetGridViewSortAndFilter() {
        gridViewSortOption = .series
        gridViewFilter = nil
        gridViewColumnCount = Self.defaultGridViewColumnCount
        gridViewShowSections = false
    }
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
    static let appPrimary = Color(hex: "ffc559")
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
    
    // MARK: - eBay URL Construction
    static func ebayAffiliateSearchURL(for item: Collectible) -> URL? {
        // TODO: Add eBay affiliation 
        let rawQuery = "\(item.attributes.name) \(item.attributes.refNumber ?? "") funko pop"
        let encodedQuery = rawQuery.urlSafeEncoded
        let urlString = "https://www.ebay.com/sch/i.html?_nkw=\(encodedQuery)"
        return URL(string: urlString)
    }
}

extension String {
    // MARK: - URL Encoding Utilities

    /// Encodes a string for eBay search URLs, handling special cases
    var urlSafeEncoded: String {
        // Replace problematic characters that eBay interprets specially
        let sanitized = self
            .replacingOccurrences(of: "&", with: " ")
            .replacingOccurrences(of: "?", with: " ")
        
        // Standard URL encoding while preserving spaces as %20
        return sanitized
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .replacingOccurrences(of: "+", with: "%20") ?? ""
    }
    
    var currencyColor: Color {
        // Create a number formatter that understands both decimal styles
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US") // Force dot decimal for parsing
        
        // Clean the string (handle both comma and dot decimals)
        let cleaned = self
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: ".") // Convert EU comma to dot
            .trimmingCharacters(in: .whitespaces)
        
        // Parse the number
        guard let number = formatter.number(from: cleaned) else {
            return .white // Default for invalid numbers
        }
        
        let value = number.floatValue
        if value == 0 {
            return .white
        } else if value > 0 {
            return .green
        } else {
            return .red
        }
    }
}

enum Rarity {
    case common, uncommon, rare, epic, legendary
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    var iconName: String {
        switch self {
        case .common: return "circle.fill"
        case .uncommon: return "diamond.fill"
        case .rare: return "seal.fill"
        case .epic: return "burst.fill"
        case .legendary: return "star.fill"
        }
    }
}

enum DateFormatUtility {
    // For display in UI
    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    // For API serialization (ISO 8601 format)
    static let apiFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    // For parsing various input formats
    static let inputFormatters: [DateFormatter] = {
        let formats = [
            "yyyy-MM-dd",       // 2025-04-10
            "MM/dd/yyyy",      // 04/10/2025
            "dd.MM.yyyy",      // 10.04.2025
            "MMM d, yyyy",    // Apr 10, 2025
            "d MMM yyyy",     // 10 Apr 2025
            "yyyyMMdd",       // 20250410
            "MMMM d, yyyy"     // April 10, 2025
        ]
        
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }
    }()
    
    // For UI display
    static func string(from date: Date) -> String {
        return displayFormatter.string(from: date)
    }
    
    // For API requests
    static func apiString(from date: Date) -> String {
        return apiFormatter.string(from: date)
    }
    
    // For parsing input
    static func date(from string: String) -> Date? {
        for formatter in inputFormatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }
}

class CurrencyFormatUtility {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter
    }()
    
    static let none = "-"
    
    static func displayPrice(_ value: Float?) -> String {
        guard let value = value else { return "-"}
        
        
        return formatter.string(from: NSNumber(value: value)) ?? "-"
    }
    
    static var zero: String {
        displayPrice(0.0)
    }
}

extension Decimal {
    func rounded(toPlaces places: Int) -> Decimal {
        var rounded = Decimal()
        var localCopy = self
        NSDecimalRound(&rounded, &localCopy, places, .plain)
        return rounded
    }
}
