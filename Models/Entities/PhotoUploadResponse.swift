//
//  PhotoUploadResponse.swift
//  FunKollector
//
//  Created by Home on 05.04.2025.
//

import Foundation

// Response model
struct PhotoUploadResponse: Codable {
    let message: String
    let photos: [String]
    let count: Int
}

// Error response model
struct ErrorResponse: Codable {
    let error: String
    let details: String?
}
