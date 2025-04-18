import Foundation
import Combine
import GoogleSignIn
import AuthenticationServices

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var username: String = ""
    @Published var isSignIn: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let repository: UserProfileRepositoryProtocol
    private let apiClient: APIClientProtocol
    
    init(
        repository: UserProfileRepositoryProtocol = UserProfileRepository(),
        apiClient: APIClientProtocol = APIClient.shared
    ) {
        self.repository = repository
        self.apiClient = apiClient
    }
    
    // MARK: - API Calls
    
    func signIn(completion: @escaping (Result<Bool, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let request = AuthRequest(
            email: email,
            password: password
        )
        
        Task {
            do {
                let authResponse: AuthResponse = try await apiClient.post(
                    path: .authLogin,
                    body: request
                )
                await MainActor.run {
                    processAuthResponse(authResponse, completion)
                }
            } catch {
                await handleError(error, completion: completion)
            }
        }
    }
    
    func signUp(completion: @escaping (Result<Bool, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let request = RegisterRequest(
            email: email,
            password: password,
            username: username
        )
        
        Task {
            do {
                let authResponse: AuthResponse = try await apiClient.post(
                    path: .authRegister,
                    body: request
                )
                await MainActor.run {
                    processAuthResponse(authResponse, completion)
                }
            } catch {
                await handleError(error, completion: completion)
            }
        }
    }
    
    func resetPassword(completion: @escaping (Result<Bool, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let request = ResetPasswordRequest(email: email)
        
        Task {
            do {
                let _: SimpleResponse = try await apiClient.post(
                    path: .resetPassword,
                    body: request
                )
                await MainActor.run {
                    completion(.success(true))
                    isLoading = false
                }
            } catch {
                await handleError(error, completion: completion)
            }
        }
    }
    
    // MARK: - Social Auth
    
    func googleSignInButtonTapped(
        _ signInResult: GIDSignInResult?,
        _ error: (any Error)?,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard error == nil, let signInResult = signInResult else {
            completion(.failure(error ?? AuthError.unknown))
            return
        }
        
        signInResult.user.refreshTokensIfNeeded { user, error in
            guard error == nil, let idToken = user?.idToken?.tokenString else {
                completion(.failure(error ?? AuthError.unknown))
                return
            }
            
            self.socialSignIn(
                idToken: idToken,
                authMethod: "google",
                email: user?.profile?.email,
                name: PersonNameComponents(givenName: user?.profile?.givenName,
                                           familyName: user?.profile?.familyName),
                completion: completion
            )
        }
    }
//    user?.profile?.email,
//    name: user?.profile?.givenName,
//    lastName: user?.profile?.familyName,
//    fullName: user?.profile?.name,
    func appleSignInButtonTapped(
        _ result: Result<ASAuthorization, any Error>,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                completion(.failure(AuthError.invalidCredentials))
                return
            }
            
            self.socialSignIn(
                userIdentifier: credential.user,
                idToken: identityToken,
                authMethod: "apple",
                email: credential.email,
                name: credential.fullName,
                completion: completion
            )
            
        case .failure(let error):
            completion(.failure(error))
        }
    }
    
    private func socialSignIn(
        userIdentifier: String? = nil,
        idToken: String,
        authMethod: String,
        email: String?,
        name: PersonNameComponents? = nil,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        isLoading = true
        errorMessage = nil
        
        let nameFormatter = PersonNameComponentsFormatter()
        let request = SocialAuthRequest(
            userIdentifier: userIdentifier,
            idToken: idToken,
            authMethod: authMethod,
            email: email ?? "",
            firstName: name?.givenName ?? "",
            lastName: name?.familyName ?? "",
            fullName: nameFormatter.string(from: name ?? PersonNameComponents())
        )
        
        Task {
            do {
                let authResponse: AuthResponse = try await apiClient.post(
                    path: .tokenSignIn,
                    body: request
                )
                await MainActor.run {
                    processAuthResponse(authResponse, completion)
                }
            } catch {
                await handleError(error, completion: completion)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func processAuthResponse(
        _ authResponse: AuthResponse,
        _ completion: (Result<Bool, Error>) -> Void
    ) {
        // Save token to Keychain
        KeychainHelper.save(token: authResponse.jwtToken)
        
        // Save profile
        let profile = UserProfile(
            uid: authResponse.uid,
            username: authResponse.username,
            email: authResponse.email,
            referralCode: authResponse.referralCode,
            profileImageData: nil,
            profilePicture: authResponse.profilePicture
        )
        
        do {
            try repository.saveUserProfile(profile)
            completion(.success(true))
        } catch {
            errorMessage = "Failed to save user profile"
            completion(.failure(error))
        }
        
        isLoading = false
    }
    
    @MainActor
    private func handleError(_ error: Error, completion: @escaping (Result<Bool, Error>) -> Void) {
        errorMessage = error.localizedDescription
        isLoading = false
        completion(.failure(error))
    }
}

// MARK: - Request Models

struct AuthRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let username: String
}

struct ResetPasswordRequest: Codable {
    let email: String
}

struct SocialAuthRequest: Codable {
    let userIdentifier: String?
    let idToken: String
    let authMethod: String
    let email: String
    let firstName: String
    let lastName: String
    let fullName: String
}
