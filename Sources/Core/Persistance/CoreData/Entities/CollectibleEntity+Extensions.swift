//
//  CollectibleEntity+Extensions.swift
//  FunKollector
//
//  Created by Home on 10.04.2025.
//

import Foundation

extension CollectibleEntity {
    func update(with collectible: Collectible) {
        self.id = collectible.id
        self.inCollection = collectible.inCollection
        
        // Attributes
        self.attrName = collectible.attributes.name
        self.attrEstimatedValue = collectible.attributes.estimatedValue
        self.attrDateFrom = collectible.attributes.dateFrom
        self.attrRefNumber = collectible.attributes.refNumber
        
        // Images
        if let mainImage = collectible.attributes.images.main {
            self.mainImageUrl = mainImage.url
            self.mainImageNudity = mainImage.nudity
            self.mainImageInsensitive = mainImage.insensitive
        }
        
        if let searchImage = collectible.attributes.images.search {
            self.searchImageUrl = searchImage.url
            self.searchImageNudity = searchImage.nudity
            self.searchImageInsensitive = searchImage.insensitive
        }
        
        if let searchNoBgImage = collectible.attributes.images.searchNoBg {
            self.searchNoBgImageUrl = searchNoBgImage.url
            self.searchNoBgImageNudity = searchNoBgImage.nudity
            self.searchNoBgImageInsensitive = searchNoBgImage.insensitive
        }
        
        // Custom Attributes
        if let pricePaid = collectible.customAttributes?.pricePaid {
            self.pricePaid = pricePaid
        }
        
        if let purchaseDate = collectible.customAttributes?.purchaseDate {
            self.purchaseDate = purchaseDate
        }
        
        if let searchQuery = collectible.customAttributes?.searchQuery {
            self.searchQuery = searchQuery
        }
        
        // Handle Sales data
        if let soldPrice = collectible.soldPrice {
            self.soldPrice = soldPrice
        }
        
        if let soldDate = collectible.soldDate {
            self.soldDate = soldDate
        }
        
        if let soldPlatform = collectible.soldPlatform {
            self.soldPlatform = soldPlatform
        }
        
        self.sold = collectible.sold
        
        // Handle array-type attributes
        self.galleryImages = collectible.attributes.images.gallery.flatMap { try? JSONEncoder().encode($0) }
        self.estimatedValueRange = collectible.attributes.estimatedValueRange.flatMap { try? JSONEncoder().encode($0) }
        self.productionStatus = collectible.attributes.productionStatus.flatMap { try? JSONEncoder().encode($0) }
        self.relatedSubjects = collectible.attributes.relatedSubjects.flatMap { try? JSONEncoder().encode($0) }
        
        // Handle array-type customAttributes
        self.userPhotos = collectible.customAttributes?.userPhotos.flatMap { try? JSONEncoder().encode($0) }
    }
    
    func updateGallery(with gallery: [ImageData]) {
        self.galleryImages = try? JSONEncoder().encode(gallery)
    }
    
    func toCollectible() -> Collectible? {
        guard let id = self.id else { return nil }
        
        // Images
        var mainImage: ImageData?
        if let url = mainImageUrl {
            mainImage = ImageData(
                url: url,
                nudity: mainImageNudity,
                insensitive: mainImageInsensitive
            )
        }
        
        var searchImage: ImageData?
        if let url = searchImageUrl {
            searchImage = ImageData(
                url: url,
                nudity: searchImageNudity,
                insensitive: searchImageInsensitive
            )
        }
        
        var searchNoBgImage: ImageData?
        if let url = searchNoBgImageUrl {
            searchNoBgImage = ImageData(
                url: url,
                nudity: searchNoBgImageNudity,
                insensitive: searchNoBgImageInsensitive
            )
        }
        
        /// Decode array-type attributes
        let gallery = self.galleryImages.flatMap { try? JSONDecoder().decode([ImageData].self, from: $0) }
        let estimatedValueRange = self.estimatedValueRange.flatMap { try? JSONDecoder().decode([String?].self, from: $0) }
        let productionStatus = self.productionStatus.flatMap { try? JSONDecoder().decode([String].self, from: $0) }
        let relatedSubjects = self.relatedSubjects.flatMap { try? JSONDecoder().decode([RelatedSubject].self, from: $0) }
        
        let images = CollectibleAttributes.Images(
            main: mainImage,
            search: searchImage,
            searchNoBg: searchNoBgImage,
            gallery: gallery
        )
        
        let attributes = CollectibleAttributes(
            images: images,
            name: attrName ?? "",
            estimatedValue: attrEstimatedValue,
            estimatedValueRange: estimatedValueRange,
            relatedSubjects: relatedSubjects,
            dateFrom: attrDateFrom,
            productionStatus: productionStatus,
            refNumber: attrRefNumber
        )
        
        /// Decode array-type attributes
        
        // Custom Attributes with Sales
        let userPhotos = self.userPhotos.flatMap { try? JSONDecoder().decode([ImageData].self, from: $0) }
        
        let sale = Sale(
            soldPrice: self.soldPrice,
            soldDate: self.soldDate,
            platform: self.soldPlatform,
            sold: self.sold
        )
        
        let customAttributes = CustomAttributes(
            pricePaid: pricePaid,
            purchaseDate: purchaseDate,
            userPhotos: userPhotos,
            searchQuery: searchQuery,
            sales: sale
        )
        
        return Collectible(
            id: id,
            attributes: attributes,
            customAttributes: customAttributes,
            inCollection: inCollection
        )
    }
}
