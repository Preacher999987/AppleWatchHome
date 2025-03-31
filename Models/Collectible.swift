import Foundation

struct Details: Codable, Hashable {
    var gallery: [String] = []
}

enum SubjectType: String, Codable, Hashable {
    case aiClassified = "ai_classified"
    case userSelectionPrimary = "user_selection_primary"
}

struct RelatedSubject: Codable, Hashable {
    var url: String?
    var name: String?
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
    var relatedSubjects: [RelatedSubject]?
    var dateFrom: String?
    var productionStatus: [String]?
    var refNumber: String?
    
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
        case dateFrom = "date_from"
        case productionStatus = "production_status"
        case refNumber = "ref_number"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        images = try container.decode(Images.self, forKey: .images)
        name = try container.decode(String.self, forKey: .name)
        _estimatedValue = try container.decodeIfPresent(String.self, forKey: ._estimatedValue)
        relatedSubjects = try container.decodeIfPresent([RelatedSubject].self, forKey: .relatedSubjects)
        dateFrom = try container.decodeIfPresent(String.self, forKey: .dateFrom)
        productionStatus = try container.decodeIfPresent([String].self, forKey: .productionStatus)
        refNumber = try container.decodeIfPresent(String.self, forKey: .refNumber)
        
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
    
    init(images: Images,
             name: String,
             _estimatedValue: String? = nil,
             estimatedValueRange: [String?]? = nil,
             relatedSubjects: [RelatedSubject]? = nil,
             dateFrom: String? = nil,
             productionStatus: [String]? = nil,
             refNumber: String? = nil) {
            self.images = images
            self.name = name
            self._estimatedValue = _estimatedValue
            self.estimatedValueRange = estimatedValueRange
            self.relatedSubjects = relatedSubjects
            self.dateFrom = dateFrom
            self.productionStatus = productionStatus
            self.refNumber = refNumber
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
        attributes.relatedSubjects?
            .first(where:
                    { $0.type == .aiClassified })?
            .name ?? ""
    }
    
    var querySubject: String? {
        if (!subject.isEmpty) { return subject }
        
        return attributes.relatedSubjects?
            .first(where:
                    { $0.type == .userSelectionPrimary })?
            .name ?? nil
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
    
    init(id: String, attributes: CollectibleAttributes, inCollection: Bool) {
        self.id = id
        self.attributes = attributes
        self.inCollection = inCollection
    }
    
    enum CodingKeys: String, CodingKey {
        case id, attributes, inCollection
    }
}
