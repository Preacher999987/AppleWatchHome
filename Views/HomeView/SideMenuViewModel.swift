import Foundation

class SideMenuViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let userProfileRepository: UserProfileRepositoryProtocol
    
    init(userProfileRepository: UserProfileRepositoryProtocol = UserProfileRepository.shared) {
        self.userProfileRepository = userProfileRepository
        loadUserProfile()
    }
    
    func loadUserProfile() {
        isLoading = true
        do {
            userProfile = try userProfileRepository.getCurrentUserProfile()
            error = nil
        } catch {
            self.error = error
            userProfile = nil
        }
        isLoading = false
    }
    
    func logout() {
        KeychainHelper.logout()
        // Additional cleanup if needed
    }
}

// Protocol for testability
protocol UserProfileRepositoryProtocol {
    static func getCurrentUserProfile() throws -> UserProfile?
}

// Make the actual repository conform to the protocol
extension UserProfileRepository: UserProfileRepositoryProtocol {}