//
//  UserProfile.swift
//  Fun Kollector
//
//  Created by Home on 02.04.2025.
//

import UIKit

struct UserProfile: Codable {
    let uid: String
    let username: String?
    let email: String?
    let referralCode: String
    let profileImageData: Data?
    let profilePicture: String?
    let backgroundImageData: Data?
    
    var profileImage: UIImage? {
        if let data = profileImageData {
            return UIImage(data: data)
        }
        
        if let urlString = profilePicture,
           let url = URL(string: urlString),
           let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        
        return nil
    }
}
