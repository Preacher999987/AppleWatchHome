//
//  Collectible+Extensions.swift
//  FunKollector
//
//  Created by Home on 06.04.2025.
//

import SwiftUI

extension Collectible {
    static func mock() -> Collectible {
        // Create mock ImageData
        let mainImage = ImageData(
            url: "https://example.com/images/main.jpg",
            nudity: false,
            insensitive: false,
            filePath: "images/main.jpg"
        )
        
        let searchImage = ImageData(
            url: "https://example.com/images/search.jpg",
            nudity: false,
            insensitive: false,
            filePath: "images/search.jpg"
        )
        
        let searchNoBgImage = ImageData(
            url: "https://example.com/images/search_no_bg.png",
            nudity: false,
            insensitive: false,
            filePath: "images/search_no_bg.png"
        )
        
        let galleryImages = [
            ImageData(url: "https://example.com/images/gallery1.jpg", nudity: false, insensitive: false),
            ImageData(url: "https://example.com/images/gallery2.jpg", nudity: false, insensitive: false)
        ]
        
        // Create mock RelatedSubjects
        let relatedSubjects = [
            RelatedSubject(
                url: "https://example.com/subjects/1",
                name: "Artificial Intelligence Art",
                type: .aiClassified
            ),
            RelatedSubject(
                url: "https://example.com/subjects/2",
                name: "Digital Collectibles",
                type: .userSelectionPrimary
            )
        ]
        
        // Create mock CollectibleAttributes
        let attributes = CollectibleAttributes(
            images: CollectibleAttributes.Images(
                main: mainImage,
                search: searchImage,
                searchNoBg: searchNoBgImage,
                gallery: galleryImages
            ),
            name: "Rare Digital Artwork #42",
            estimatedValue: "1250.00",
            estimatedValueRange: ["1000.00", "1500.00"],
            relatedSubjects: relatedSubjects,
            dateFrom: "2023-05-15",
            productionStatus: ["Limited Edition", "Artist Signed"],
            refNumber: "DA-2023-0042"
        )
        
        // Create mock CustomAttributes
        let customAttributes = CustomAttributes(
            pricePaid: 899.99,
            userPhotos: [
                ImageData(url: "https://example.com/user/photo1.jpg", nudity: false, insensitive: false),
                ImageData(url: "https://example.com/user/photo2.jpg", nudity: false, insensitive: false)
            ]
        )
        
        // Create and return the Collectible
        return Collectible(
            id: "collectible_12345",
            attributes: attributes,
            customAttributes: customAttributes,
            inCollection: true
        )
    }
}
