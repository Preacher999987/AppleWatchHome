//
//  ProfileInfoDestination.swift
//  FunKollector
//
//  Created by Home on 17.04.2025.
//

import Foundation

enum SafariViewDestination {
    case changePassword
    case terms
    case shareApp
    case instagram
    case contactUs
    
    var url: URL? {
        switch self {
        case .changePassword:
            // TODO: Add your URL if needed
            nil
        case .terms:
            URL(string: "https://funkollector.swipeless.co.uk/policies")
        case .shareApp:
            URL(string: "https://funkollector.swipeless.co.uk")
        case .instagram:
            URL(string: "https://instagram.com/funkollector.ai")
        case .contactUs:
            URL(string: "mailto:support@swipeless.co.uk")
        }
    }
}
// Making ProfileInfoDestination identifiable for sheet presentation
extension SafariViewDestination: Identifiable {
    var id: Self { self }
}
