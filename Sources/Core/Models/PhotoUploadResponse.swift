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

struct MultipartFile {
    let data: Data
    let fieldName: String
    let fileName: String
    let mimeType: String
    
    init(data: Data, fieldName: String, fileName: String, mimeType: String) {
        self.data = data
        self.fieldName = fieldName
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
