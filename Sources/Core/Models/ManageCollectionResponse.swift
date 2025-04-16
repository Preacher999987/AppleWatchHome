//
//  PhotoUploadResponse 2.swift
//  FunKollector
//
//  Created by Home on 16.04.2025.
//


// Response model
struct ManageCollectionResponse: Codable {
    let success: Bool
    let error: String?
    let details: String?
    let addedCount: Int?
    let totalItems: Int?
}
