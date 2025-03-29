import Foundation

struct Details: Codable, Hashable {
    var gallery: [String] = []
}

enum SubjectType: String, Codable, Hashable {
    case aiClassified = "ai_classified"
}

struct RelatedSubject: Codable, Hashable {
    let url: String?
    let name: String?
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
    var _estimatedValue: String? // New property
    var estimatedValueRange: [String?]? // Updated to handle nulls
    let relatedSubjects: [RelatedSubject]?
    
    struct Images: Codable, Hashable {
        let main: ImageData?
        let search: ImageData?
        let searchNoBg: ImageData?
        var gallery: [ImageData]?
        
        enum CodingKeys: String, CodingKey {
            case main, search, gallery
            case searchNoBg = "search_no_bg"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case images, name
        case _estimatedValue = "estimated_value"
        case estimatedValueRange = "estimated_value_range"
        case relatedSubjects = "related_subjects"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        images = try container.decode(Images.self, forKey: .images)
        name = try container.decode(String.self, forKey: .name)
        _estimatedValue = try container.decodeIfPresent(String.self, forKey: ._estimatedValue)
        relatedSubjects = try container.decodeIfPresent([RelatedSubject].self, forKey: .relatedSubjects)
        
        // Handle null values in estimatedValueRange
        if var rangeContainer = try? container.nestedUnkeyedContainer(forKey: .estimatedValueRange) {
            var decodedRange = [String?]()
            while !rangeContainer.isAtEnd {
                if try rangeContainer.decodeNil() {
                    decodedRange.append(nil)
                } else {
                    let value = try rangeContainer.decode(String.self)
                    decodedRange.append(value)
                }
            }
            estimatedValueRange = decodedRange.isEmpty ? nil : decodedRange
        } else {
            estimatedValueRange = nil
        }
    }
}

struct Collectible: Codable, Hashable {
    let id: String
    var attributes: CollectibleAttributes
    var inCollection: Bool = true
    
    // Computed variables
    var searchImageUrl: String { attributes.images.search?.url ?? "" }
    var searchImageNoBgUrl: String { attributes.images.searchNoBg?.url ?? "" }
    var mainImageUrl: String { attributes.images.main?.url ?? "" }
    var gallery: [ImageData] { attributes.images.gallery ?? [] }
    
    var subject: String {
        attributes.relatedSubjects?.first(where: { $0.type == .aiClassified })?.name ?? ""
    }
    
    var estimatedValue: String? {
        // First try to use estimatedValueRange if valid
        if let range = attributes.estimatedValueRange?.compactMap({ $0 }), !range.isEmpty {
            let cleanValues = range.map { $0.components(separatedBy: ".").first ?? $0 }
            
            switch cleanValues.count {
            case 2:
                return "$\(cleanValues[0]) - $\(cleanValues[1])"
            case 1:
                return "$\(cleanValues[0])"
            default:
                break // Fall through to _estimatedValue check
            }
        }
        
        // Fall back to _estimatedValue if available
        if let value = attributes._estimatedValue {
            return value.hasPrefix("$") ? value : "$\(value)"
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
