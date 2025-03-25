//
//  AnalysisResult.swift
//  FunkoCollector
//
//  Created by Home on 24.03.2025.
//


// AnalysisResult.swift
import Foundation

struct Collectible: Codable, Hashable {
    let href: String
    let itemName: String
    let imageUrl: String
    let ev: String
    let subject: String
    
    // Computed property to extract just the dollar value
    var estimatedValue: String? {
        return ev.components(separatedBy: "$").last.map { "$\($0)" }
    }
}
