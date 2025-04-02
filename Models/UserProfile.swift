//
//  UserProfile.swift
//  Fun Kollector
//
//  Created by Home on 02.04.2025.
//

import Foundation

struct UserProfile: Codable {
        let jwtToken: String
        let uid: String
        let username: String?
        let referralCode: String
    }
