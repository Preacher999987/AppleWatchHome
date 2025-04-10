//
//  Sale.swift
//  FunKollector
//
//  Created by Home on 10.04.2025.
//

import Foundation

struct Sale: Codable, Hashable {
    var soldPrice: Float?
    var soldDate: Date?  // Better name than saleDate as it's more specific
    var soldPlatform: String?
    var sold: Bool
    
    enum CodingKeys: String, CodingKey {
        case soldPrice = "sold_price"
        case soldDate = "sold_date"
        case soldPlatform = "sold_platform"
        case sold
    }
    
    init(soldPrice: Float? = nil, soldDate: Date? = nil, platform: String? = nil, sold: Bool = false) {
        self.soldPrice = soldPrice
        self.soldDate = soldDate
        self.soldPlatform = platform
        self.sold = sold
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        soldPrice = try container.decodeIfPresent(Float.self, forKey: .soldPrice)
        soldDate = try container.decodeIfPresent(Date.self, forKey: .soldDate)
        soldPlatform = try container.decodeIfPresent(String.self, forKey: .soldPlatform)
        sold = try container.decodeIfPresent(Bool.self, forKey: .sold) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(soldPrice, forKey: .soldPrice)
        
        if let date = soldDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            try container.encode(formatter.string(from: date), forKey: .soldDate)
        }
        
        try container.encodeIfPresent(soldPlatform, forKey: .soldPlatform)
        try container.encodeIfPresent(sold, forKey: .sold)
    }
}
