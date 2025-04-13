//
//  Collectible+Extensions.swift
//  FunKollector
//
//  Created by Home on 10.04.2025.
//

import Foundation

extension Collectible {
    //MARK: Sales-related computed properties
    var soldPrice: Float? {
        get { customAttributes?.sales?.soldPrice }
        set {
            if customAttributes == nil {
                customAttributes = CustomAttributes()
            }
            if customAttributes?.sales == nil {
                customAttributes?.sales = Sale()
            }
            customAttributes?.sales?.soldPrice = newValue
        }
    }
    
    var soldDate: Date? {
        get { customAttributes?.sales?.soldDate }
        set {
            if customAttributes == nil {
                customAttributes = CustomAttributes()
            }
            if customAttributes?.sales == nil {
                customAttributes?.sales = Sale()
            }
            customAttributes?.sales?.soldDate = newValue
        }
    }
    
    var soldPlatform: String? {
        get { customAttributes?.sales?.soldPlatform }
        set {
            if customAttributes == nil {
                customAttributes = CustomAttributes()
            }
            if customAttributes?.sales == nil {
                customAttributes?.sales = Sale()
            }
            customAttributes?.sales?.soldPlatform = newValue
        }
    }
    
    var sold: Bool {
        get { customAttributes?.sales?.sold ?? false }
        set {
            if customAttributes == nil {
                customAttributes = CustomAttributes()
            }
            if customAttributes?.sales == nil  {
                customAttributes?.sales = Sale()
            }
            customAttributes?.sales?.sold = newValue
        }
    }
    
    var soldDateDisplay: String {
        customAttributes?.sales?.soldDate.flatMap { DateFormatUtility.string(from: $0) } ?? "-"
    }
    
    var soldPriceDisplay: String {
        guard let price = soldPrice,
              // Explicitly check for zero as CoreData does not store Optional Numeric values else {
                price > 0 else {
            return CurrencyFormatUtility.none
        }
        return CurrencyFormatUtility.displayPrice(price)
    }
    
    var isSold: Bool {
        customAttributes?.sales?.soldPrice != nil
    }
    
    // MARK: Other CustomAttributes computed properties
    
    var pricePaid: Float? {
        get { customAttributes?.pricePaid }
        set {
            if customAttributes == nil {
                customAttributes = CustomAttributes()
            }
            
            customAttributes?.pricePaid = newValue
        }
    }
    
    var subject: String {
        attributes.relatedSubjects?
            .first(where:
                    { $0.type == .aiClassified })?
            .name ?? ""
    }
    
    var querySubject: String? {
        attributes.relatedSubjects?
            .first(where:
                    { $0.type == .userSelectionPrimary })?
            .name
        ?? ((!subject.isEmpty) ? subject :  nil)
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
        CurrencyFormatUtility.displayPrice(returnValue)
    }
    
    var pricePaidDisplay: String {
        guard let pricePaid = customAttributes?.pricePaid, pricePaid > 0 else { return "-" }
           
        return CurrencyFormatUtility.displayPrice(pricePaid)
    }
    
    var purchaseDate: Date? {
        get {
            customAttributes?.purchaseDate
        }
        
        set {
            if customAttributes == nil {
                customAttributes = CustomAttributes()
            }
            
            customAttributes?.purchaseDate = newValue
        }
    }
    
    var purchaseDateDisplay: String {
        customAttributes?.purchaseDate.flatMap { DateFormatUtility.string(from: $0) } ?? "-"
    }
    
    var searchQuery: String? {
        customAttributes?.searchQuery
    }
}
