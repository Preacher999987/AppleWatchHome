struct UserProfile: Codable {
        let jwtToken: String
        let uid: String
        let username: String?
        let referralCode: String
    }