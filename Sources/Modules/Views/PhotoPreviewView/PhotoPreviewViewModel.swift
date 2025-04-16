//
//  PhotoPreviewViewModel.swift
//  FunkoCollector
//
//  Created by Home on 24.03.2025.
//

import SwiftUI

class PhotoPreviewViewModel: ObservableObject {
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    func analyzePhoto(image: UIImage, type: String) async throws -> [Collectible] {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            throw ImageError.failedToCompress
        }
        
        let file = MultipartFile(
            data: imageData,
            fieldName: "photo",
            fileName: "photo.jpg",
            mimeType: "image/jpeg"
        )
        
        let formFields = ["type": type]
        
        return try await apiClient.upload(
            path: .photoAnalysis,
            files: [file],
            formFields: formFields
        )
    }
}

enum ImageError: Error {
    case failedToCompress
}
