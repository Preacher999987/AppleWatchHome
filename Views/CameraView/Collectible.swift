//
//  Collectible.swift
//  FunkoCollector
//
//  Created by Home on 24.03.2025.
//


// Collectible.swift
import Foundation

struct Details: Codable, Hashable {
    var gallery: [String] = []
}

enum SubjectType: String, Codable, Hashable {
    case aiClassified = "ai_classified"
}

struct RelatedSubject: Codable, Hashable {
    let url: String?
    let name: String
    let type: SubjectType?
}

struct ImageData: Codable, Hashable {
    let url: String
    let nudity: Bool
    let insensitive: Bool
    
    enum CodingKeys: String, CodingKey {
        case url, nudity, insensitive
    }
}

struct CollectibleAttributes: Codable, Hashable {
    var images: Images
    let name: String
    let estimatedValueRange: [String]?
    let relatedSubjects: [RelatedSubject]?
    
    struct Images: Codable, Hashable {
        let main: ImageData?
        let search: ImageData?
        var gallery: [ImageData]?
        
        enum CodingKeys: String, CodingKey {
            case main, search, gallery
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case images, name
        case estimatedValueRange = "estimated_value_range"
        case relatedSubjects = "related_subjects"
    }
}

struct Collectible: Codable, Hashable {
    let id: String
    var attributes: CollectibleAttributes
    var inCollection: Bool = true
    
    // Computed variables
    var searchImageUrl: String { attributes.images.search?.url ?? "" }
    var mainImageUrl: String { attributes.images.main?.url ?? "" }
    var gallery: [ImageData] { attributes.images.gallery ?? [] }
        
    var ev: String {
        attributes.estimatedValueRange?.joined(separator: " - ") ?? ""
    }
    
    var subject: String {
        attributes.relatedSubjects?.first(where: { $0.type == .aiClassified })?.name ?? ""
    }
    
    var estimatedValue: String? {
        guard let range = attributes.estimatedValueRange else { return nil }
        if range.count == 2 {
            let low = range[0].components(separatedBy: ".").first ?? range[0]
            let high = range[1].components(separatedBy: ".").first ?? range[1]
            return "$\(low) - $\(high)"
        }
        else if let firstValue = range.first {
            let value = firstValue.components(separatedBy: ".").first ?? firstValue
            return "$\(value)"
        }
        return nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        attributes = try container.decode(CollectibleAttributes.self, forKey: .attributes)
        inCollection = (try? container.decode(Bool.self, forKey: .inCollection)) ?? true
    }
    
    enum CodingKeys: String, CodingKey {
        case id, attributes, inCollection
    }
}
