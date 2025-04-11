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
    var selectedType: String?
    
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
        case selectedType = "selected_type"
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
        selectedType = try container.decodeIfPresent(String.self, forKey: .selectedType)
        
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
         refNumber: String? = nil,
         selectedType: String? = nil) {
        self.images = images
        self.name = name
        self.estimatedValue = estimatedValue
        self.estimatedValueRange = estimatedValueRange
        self.relatedSubjects = relatedSubjects
        self.dateFrom = dateFrom
        self.productionStatus = productionStatus
        self.refNumber = refNumber
        self.selectedType = selectedType
    }
}

struct CustomAttributes: Codable, Hashable {
    var pricePaid: Float?
    var purchaseDate: Date?
    var userPhotos: [ImageData]?
    var searchQuery: String?
    var sales: Sale?  // Changed to singular since it represents one sale
    
    enum CodingKeys: String, CodingKey {
        case pricePaid = "price_paid"
        case purchaseDate = "purchase_date"
        case userPhotos = "user_photos"
        case searchQuery = "search_query"
        case sales
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pricePaid = try container.decodeIfPresent(Float.self, forKey: .pricePaid)
        purchaseDate = try container.decodeIfPresent(Date.self, forKey: .purchaseDate)
        userPhotos = try container.decodeIfPresent([ImageData].self, forKey: .userPhotos)
        searchQuery = try container.decodeIfPresent(String.self, forKey: .searchQuery)
        sales = try container.decodeIfPresent(Sale.self, forKey: .sales)
    }
    
    init(pricePaid: Float? = nil,
         purchaseDate: Date? = nil,
         userPhotos: [ImageData]? = nil,
         searchQuery: String? = nil,
         sales: Sale? = nil) {
        self.pricePaid = pricePaid
        self.purchaseDate = purchaseDate
        self.userPhotos = userPhotos
        self.searchQuery = searchQuery
        self.sales = sales
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(pricePaid, forKey: .pricePaid)
        
        if let date = purchaseDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            try container.encode(formatter.string(from: date), forKey: .purchaseDate)
        }
        
        try container.encodeIfPresent(userPhotos, forKey: .userPhotos)
        try container.encodeIfPresent(searchQuery, forKey: .searchQuery)
        try container.encodeIfPresent(sales, forKey: .sales)
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
    
    // MARK: Methods
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "inCollection": inCollection,
            "custom_attributes": [
                "price_paid": customAttributes?.pricePaid as Any,
                "purchase_date": customAttributes?.purchaseDate.flatMap {
                    DateFormatUtility.apiString(from: $0)
                } as Any,
                "user_photos": customAttributes?.userPhotos?.map { $0.url } as Any,
                "search_query": customAttributes?.searchQuery as Any,
                "sales": [
                    "sold_price": customAttributes?.sales?.soldPrice as Any,
                    "sold_date": customAttributes?.sales?.soldDate.flatMap {
                        DateFormatUtility.apiString(from: $0)
                    } as Any,
                    "sold_platform": customAttributes?.sales?.soldPlatform as Any
                ] as Any
            ],
            "attributes": [
                "name": attributes.name,
                "estimated_value": attributes.estimatedValue as Any,
                "estimated_value_range": attributes.estimatedValueRange as Any,
                "date_from": attributes.dateFrom as Any,
                "production_status": attributes.productionStatus as Any,
                "ref_number": attributes.refNumber as Any,
                "selected_type": attributes.selectedType as Any,
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
        
        // Clean custom_attributes
        if var customAttrs = dict["custom_attributes"] as? [String: Any] {
            customAttrs = customAttrs.compactMapValues { $0 }
            
            // Clean sales if it exists
            if var sales = customAttrs["sales"] as? [String: Any] {
                sales = sales.compactMapValues { $0 }
                if sales.isEmpty {
                    customAttrs["sales"] = nil
                } else {
                    customAttrs["sales"] = sales
                }
            }
            
            dict["custom_attributes"] = customAttrs.isEmpty ? nil : customAttrs
        }
        
        // Clean attributes
        if var attributesDict = dict["attributes"] as? [String: Any] {
            attributesDict = attributesDict.compactMapValues { $0 }
            
            // Clean images
            if var imagesDict = attributesDict["images"] as? [String: Any] {
                imagesDict = imagesDict.compactMapValues { $0 }
                attributesDict["images"] = imagesDict.isEmpty ? nil : imagesDict
            }
            
            // Clean related_subjects
            if let relatedSubjects = attributesDict["related_subjects"] as? [[String: Any?]] {
                let cleanedSubjects = relatedSubjects.map { subject in
                    subject.compactMapValues { $0 }
                }.filter { !$0.isEmpty }
                attributesDict["related_subjects"] = cleanedSubjects.isEmpty ? nil : cleanedSubjects
            }
            
            dict["attributes"] = attributesDict.isEmpty ? nil : attributesDict
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
