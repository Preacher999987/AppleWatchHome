//
//  UserDefault.swift
//  Fun Kollector
//
//  Created by Home on 30.03.2025.
//

import SwiftUI
import SwiftUI

class AppState: ObservableObject {
    @Published var openMyCollection = false
    @Published var openRelated = false
    
    // Toolbar's navigationBar items visibility settings
    @Published var showCollectionButton = false
    @Published var showBackButton = true
    @Published var showAddToCollectionButton = false
    @Published var showPlusButton = false
    @Published var showEllipsisButton = false
    
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

