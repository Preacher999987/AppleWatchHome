import Foundation

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
    let filePath: String?
    
    enum CodingKeys: String, CodingKey {
        case url, nudity, insensitive, filePath
    }
    
    init(url: String = "", nudity: Bool = false, insensitive: Bool = false, filePath: String = "") {
        self.url = url
        self.nudity = nudity
        self.insensitive = insensitive
        self.filePath = filePath
    }
}

struct CollectibleAttributes: Codable, Hashable {
    var images: Images
    let name: String
    var estimatedValue: String? // New property
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
        case estimatedValue = "estimated_value"
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
        estimatedValue = try container.decodeIfPresent(String.self, forKey: .estimatedValue)
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
             estimatedValue: String? = nil,
             estimatedValueRange: [String?]? = nil,
             relatedSubjects: [RelatedSubject]? = nil,
             dateFrom: String? = nil,
             productionStatus: [String]? = nil,
             refNumber: String? = nil) {
            self.images = images
            self.name = name
            self.estimatedValue = estimatedValue
            self.estimatedValueRange = estimatedValueRange
            self.relatedSubjects = relatedSubjects
            self.dateFrom = dateFrom
            self.productionStatus = productionStatus
            self.refNumber = refNumber
        }
}

struct CustomAttributes: Codable, Hashable {
    var pricePaid: Float?
    var userPhotos: [ImageData]?
    var searchQuery: String?
    
    enum CodingKeys: String, CodingKey {
        case pricePaid = "price_paid"
        case userPhotos = "user_photos"
        case searchQuery = "search_query"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pricePaid = try container.decodeIfPresent(Float.self, forKey: .pricePaid)
        userPhotos = try container.decodeIfPresent([ImageData].self, forKey: .userPhotos)
        searchQuery = try container.decodeIfPresent(String.self, forKey: .searchQuery)
    }
    
    init(pricePaid: Float? = nil,
         userPhotos: [ImageData]? = nil,
         searchQuery: String? = nil) {
        self.pricePaid = pricePaid
        self.userPhotos = userPhotos
        self.searchQuery = searchQuery
    }
}

struct Collectible: Codable, Hashable {
    let id: String
    var attributes: CollectibleAttributes
    var customAttributes: CustomAttributes?
    var inCollection: Bool = true
    
    // Computed variables
    var searchImageUrl: String { attributes.images.search?.url ?? "" }
    var searchImageNoBgUrl: String { attributes.images.searchNoBg?.url ?? "" }
    var mainImageUrl: String { attributes.images.main?.url ?? "" }
    var gallery: [ImageData] { attributes.images.gallery ?? [] }
    
    // MARK: Computed Properties
    
    var pricePaid: Float? {
        didSet {
            if customAttributes == nil {
                customAttributes = CustomAttributes()
            }
            
                customAttributes?.pricePaid = pricePaid
        }
    }
    
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
    
    var estimatedValueFloat: Float? {
        // First try to get the average of estimatedValueRange if available
        if let range = attributes.estimatedValueRange?.compactMap({ $0 }).compactMap({ Float($0) }), !range.isEmpty {
            let sum = range.reduce(0, +)
            return sum / Float(range.count)
        }
        
        // Fall back to estimatedValue if available
        if let value = attributes.estimatedValue {
            let cleanedValue = value.replacingOccurrences(of: "$", with: "")
            return Float(cleanedValue)
        }
        
        return nil
    }
    
    var estimatedValueDisplay: String? {
        // First try to use estimatedValueRange if valid
        if let range = attributes.estimatedValueRange?.compactMap({ $0 }), !range.isEmpty {
            let cleanValues = range.map { $0.components(separatedBy: ".").first ?? $0 }
            
            switch cleanValues.count {
            case 2:
                return "$\(cleanValues[0]) - $\(cleanValues[1])"
            case 1:
                return "$\(cleanValues[0])"
            default:
                break // Fall through to estimatedValue check
            }
        }
        
        // Fall back to estimatedValue if available
        if let value = attributes.estimatedValue {
            return value.hasPrefix("$") ? value : "$\(value)"
        }
        
        return nil
    }
    
    var returnValue: Float? {
        // Extract the base value (from estimatedValue or first non-nil estimatedValueRange item)
        let baseValue: Float
        if let estimatedValue = attributes.estimatedValue.flatMap({ Float($0) }) {
            baseValue = estimatedValue
        } else if let firstValidRangeValue = attributes.estimatedValueRange?.compactMap({ $0 }).first.flatMap({ Float($0) }) {
            baseValue = firstValidRangeValue
        } else {
            return nil  // No valid base value found
        }
        
        // Calculate return value if pricePaid exists
        if let pricePaid = customAttributes?.pricePaid, pricePaid > 0 {
            return baseValue - pricePaid
        }
        
        return nil
    }
    
    var returnValueDisplay: String {
        formatDisplayPriceValue(returnValue)
    }
    
    var pricePaidDisplay: String {
        guard let pricePaid = customAttributes?.pricePaid, pricePaid > 0 else { return "-" }
           
        return formatDisplayPriceValue(pricePaid)
    }
    
    var searchQuery: String? {
        customAttributes?.searchQuery
    }
    
    // MARK: Methods
    
    private func formatDisplayPriceValue(_ value: Float?) -> String {
        guard let value = value else { return "-" }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: value)) ?? "-"
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "inCollection": inCollection,
            "custom_attributes": [
                "price_paid": customAttributes?.pricePaid as Any,
                "user_photos": customAttributes?.userPhotos?.map { $0.url } as Any,
                "search_query": customAttributes?.searchQuery as Any
            ],
            "attributes": [
                "name": attributes.name,
                "estimated_value": attributes.estimatedValue as Any,
                "estimated_value_range": attributes.estimatedValueRange as Any,
                "date_from": attributes.dateFrom as Any,
                "production_status": attributes.productionStatus as Any,
                "ref_number": attributes.refNumber as Any,
                "images": [
                    "main": attributes.images.main?.url as Any,
                    "search": attributes.images.search?.url as Any,
                    "search_no_bg": attributes.images.searchNoBg?.url as Any,
                    "gallery": attributes.images.gallery?.map { $0.url } as Any
                ],
                "related_subjects": attributes.relatedSubjects?.map { [
                    "url": $0.url as Any,
                    "name": $0.name as Any,
                    "type": $0.type?.rawValue as Any
                ]} as Any
            ]
        ]
        
        // Remove nil values to keep the dictionary clean
        dict = dict.compactMapValues { $0 }
        if var attributesDict = dict["attributes"] as? [String: Any] {
            attributesDict = attributesDict.compactMapValues { $0 }
            if var imagesDict = attributesDict["images"] as? [String: Any] {
                imagesDict = imagesDict.compactMapValues { $0 }
                attributesDict["images"] = imagesDict
            }
            dict["attributes"] = attributesDict
        }
        
        return dict
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        attributes = try container.decode(CollectibleAttributes.self, forKey: .attributes)
        customAttributes = try? container.decode(CustomAttributes.self, forKey: .customAttributes)
        inCollection = (try? container.decode(Bool.self, forKey: .inCollection)) ?? true
    }
    
    init(id: String, attributes: CollectibleAttributes, customAttributes: CustomAttributes, inCollection: Bool) {
        self.id = id
        self.attributes = attributes
        self.customAttributes = customAttributes
        self.inCollection = inCollection
    }
    
    enum CodingKeys: String, CodingKey {
        case id, attributes, customAttributes = "custom_attributes", inCollection
    }
}
