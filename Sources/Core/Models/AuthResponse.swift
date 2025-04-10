//
//  AuthResponse.swift
//  FunKollector
//
//  Created by Home on 03.04.2025.
//


struct AuthResponse: Codable {
    let jwtToken: String
    let uid: String
    let username: String?
    let referralCode: String
    let email: String?
    let profilePicture: String?
}

struct SimpleResponse: Codable {
    let message: String
}
