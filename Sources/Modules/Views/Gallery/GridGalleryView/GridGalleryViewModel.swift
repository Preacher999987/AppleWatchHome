//
//  GridGalleryViewModel.swift
//  FunkoCollector
//
//  Created by Home on 25.03.2025.
//

import SwiftUI
import Foundation

class GridGalleryViewModel: ObservableObject {
    @Published var showLoadingIndicator = false
    @Published var errorMessage: String?
    @Published var showSuccessCheckmark: Bool = false
    @Published var selectedItems: [Collectible] = []
    @Published private var refreshTrigger = false
    
    var selectedItemsCount: Int { selectedItems.count }
    
    private let userRepository: UserProfileRepositoryProtocol
    private let collectibleRepository: CollectibleRepositoryProtocol
    private let apiClient: APIClientProtocol
    
    init(userRepository: UserProfileRepositoryProtocol = UserProfileRepository(),
         collectibleRepository: CollectibleRepositoryProtocol = CollectibleRepository(),
         apiClient: APIClientProtocol = APIClient.shared) {
        self.userRepository = userRepository
        self.collectibleRepository = collectibleRepository
        self.apiClient = apiClient
    }
    
    // MARK: - Selection Management
    
    func cancelSearchResultsSelectionButtonTapped() {
        selectedItems.removeAll()
    }
    
    func toggleItemSelection(_ item: Collectible) {
        if let index = selectedItems.firstIndex(where: { $0.id == item.id }) {
            selectedItems.remove(at: index)
        } else {
            selectedItems.append(item)
        }
    }
    
    func isItemSelected(_ id: String) -> Bool {
        selectedItems.contains(where: { $0.id == id })
    }
    
    // MARK: - Collection Management
    
    func addToCollectionConfirmed(_ completion: @escaping (Result<Bool, Error>) -> Void) {
        let itemIds = selectedItems.map { $0.id }
        manageCollection(itemIds: itemIds, method: .add) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.addToCollection(self.selectedItems)
                completion(result)
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func loadMyCollection() async -> [Collectible] {
        (try? await collectibleRepository.getCollectibles()) ?? []
    }
    
    private func addToCollection(_ items: [Collectible]) {
        try? collectibleRepository.addItems(items)
    }
    
    func deleteItem(for id: String) {
        try? collectibleRepository.deleteItem(for: id)
    }
    
    func updateItem(_ item: Collectible) {
        try? collectibleRepository.updateItem(item)
    }
    
    func updateGallery(by itemId: String, galleryImages: [ImageData]) throws {
        try collectibleRepository.updateGallery(by: itemId, galleryImages: galleryImages)
    }
    
    func customAttributeUpdated(for item: Collectible) {
        try? collectibleRepository.updateItem(item)
        manageCollection(itemIds: [item.id], method: .update, collectible: item) { _ in }
    }
    
    // MARK: - Network Operations
    
    func getGridItemUrl(from item: Collectible) -> URL? {
        // TODO: Post-release feature
        //        let stringUrl = !item.searchImageNoBgUrl.isEmpty
        //        ? baseUrl + item.searchImageNoBgUrl
        //        : item.searchImageUrl
        let stringUrl = item.searchImageUrl
        return URL(string: stringUrl)
    }
    
    func showAcquisitionDetails(for collectibleId: String) -> Bool {
        return (try? collectibleRepository.item(by: collectibleId) ?? nil) != nil
    }
    
    func showSaleDetails(for collectibleId: String) -> Bool {
        (try? collectibleRepository.item(by: collectibleId))?.customAttributes?.sales?.sold ?? false
    }
    
    func getRelated(for itemId: String, completion: @escaping ([Collectible]) -> Void) {
        showLoadingIndicator = true
        
        guard let querySubject = try? collectibleRepository.item(by: itemId)?.querySubject else {
            showLoadingIndicator = false
            errorMessage = NetworkError.invalidQuery.userFacingMessage
            return
        }
        
        Task {
            do {
                let items: [Collectible] = try await apiClient.get(
                    path: .relatedItems,
                    queryItems: [URLQueryItem(name: "query", value: querySubject.urlSafeEncoded)]
                )
                
                await MainActor.run {
                    showLoadingIndicator = false
                    completion(items)
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func getGalleryImages(for id: String, completion: @escaping (Result<[ImageData], Error>) -> Void) {
        Task {
            do {
                let images: [ImageData] = try await apiClient.get(
                    path: .galleryImages.with(id),
                    queryItems: nil
                )
                await MainActor.run {
                    completion(.success(images))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func manageCollection(itemIds: [String],
                          method: ManageCollectionMethod,
                          collectible: Collectible? = nil,
                          completion: @escaping (Result<Bool, Error>) -> Void) {
        showLoadingIndicator = true
        
        let uid = (try? userRepository.getCurrentUserProfile()?.uid) ?? ""
        var request = ManageCollectionRequest(
            method: method,
            itemIds: itemIds,
            uid: uid
        )
        
        if method == .update, let collectible = collectible {
            request.itemToUpdate = collectible
        }
        
        Task {
            do {
                let _: ManageCollectionResponse = try await apiClient.post(path: .manageCollection, body: request)
                await MainActor.run {
                    showLoadingIndicator = false
                    completion(.success(true))
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    func uploadCollectibleUserPhotos(collectibleId: String,
                                     photos: [Data],
                                     completion: @escaping (Collectible) -> Void) {
        showLoadingIndicator = true
        let uid = (try? userRepository.getCurrentUserProfile()?.uid) ?? ""
        
        Task {
            do {
                let response: PhotoUploadResponse = try await apiClient.upload(
                    path: APIPath.userPhotos.with(uid),
                    files: photos.enumerated().map { index, data in
                        MultipartFile(
                            data: data,
                            fieldName: "photos",
                            fileName: "photo_\(index).jpg",
                            mimeType: "image/jpeg"
                        )
                    },
                    formFields: ["collectibleId": collectibleId]
                )
                
                let updatedItem = try updateItemUserPhotos(with: response.photos, collectibleId)
                
                await MainActor.run {
                    showLoadingIndicator = false
                    showSuccessCheckmark = true
                    completion(updatedItem)
                }
            } catch {
                await MainActor.run {
                    showLoadingIndicator = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateItemUserPhotos(with photoFilePaths: [String], _ collectibleId: String) throws -> Collectible {
        guard var itemToUpdate = try collectibleRepository.item(by: collectibleId) else {
            throw NSError(domain: "No collectible found for id: \(collectibleId)", code: 0)
        }
        
        if itemToUpdate.customAttributes == nil {
            itemToUpdate.customAttributes = CustomAttributes()
        }
        
        if itemToUpdate.customAttributes?.userPhotos == nil {
            itemToUpdate.customAttributes?.userPhotos = []
        }
        
        let userPhotos = photoFilePaths.map { ImageData(filePath: $0) }
        itemToUpdate.customAttributes?.userPhotos?.append(contentsOf: userPhotos)
        try collectibleRepository.updateItem(itemToUpdate)
        
        return itemToUpdate
    }
    
    func combinedGalleryImages(for item: Collectible) -> [ImageData] {
        let galleryImages = item.attributes.images.gallery ?? []
        let userPhotos = item.customAttributes?.userPhotos ?? []
        return galleryImages + userPhotos
    }
    
    func imageURL(from imageData: ImageData) -> URL? {
        apiClient.imageURL(from: imageData)
    }
}

// MARK: - Supporting Types

struct ManageCollectionRequest: Encodable {
    let method: ManageCollectionMethod
    let itemIds: [String]
    let uid: String
    var itemToUpdate: Collectible?
    
    enum CodingKeys: String, CodingKey {
        case method, itemIds, uid, itemToUpdate
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(method.rawValue, forKey: .method)
        try container.encode(itemIds, forKey: .itemIds)
        try container.encode(uid, forKey: .uid)
        if let itemToUpdate = itemToUpdate {
            // Convert the Collectible to a dictionary
            let dict = itemToUpdate.toDictionary()
            
            // Create a new encoder for the dictionary
            var nestedContainer = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .itemToUpdate)
            
            // Encode each key-value pair from the dictionary
            for (key, value) in dict {
                let codingKey = DynamicCodingKey(stringValue: key)!
                try nestedContainer.encode(AnyEncodable(value), forKey: codingKey)
            }
        }
    }
}

// Helper types to handle dynamic dictionary encoding
private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

private struct AnyEncodable: Encodable {
    private let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        if let encodable = value as? Encodable {
            try encodable.encode(to: encoder)
        } else {
            var container = encoder.singleValueContainer()
            if let array = value as? [Any] {
                try container.encode(array.map { AnyEncodable($0) })
            } else if let dict = value as? [String: Any] {
                try container.encode(dict.mapValues { AnyEncodable($0) })
            } else {
                try container.encodeNil()
            }
        }
    }
}
