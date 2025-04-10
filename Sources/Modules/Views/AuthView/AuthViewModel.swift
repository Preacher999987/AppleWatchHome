//
//  AuthViewModel.swift
//  Fun Kollector
//
//  Created by Home on 01.04.2025.
//

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
    
    private let baseUrl = "http://192.168.1.17:3001"
    private var cancellables = Set<AnyCancellable>()
    
    private let repository: UserProfileRepositoryProtocol
    
    init(repository: UserProfileRepositoryProtocol = UserProfileRepository()) {
        self.repository = repository
    }
    
    // MARK: - API Calls
    
    func signIn(completion: @escaping (Result<Bool, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseUrl)/auth/login") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            errorMessage = "Error creating request"
            isLoading = false
            return
        }
        
        sendRequest(request, body: body, completion: completion)
    }
    
    private func sendRequest(_ request: URLRequest, body: [String: Any], completion: @escaping (Result<Bool, Error>) -> Void) {
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    let error = URLError(.badServerResponse)
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    
                    return data
                }
                
                if httpResponse.statusCode == 401 {
                    let error = AuthError.invalidCredentials
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else if !(200...299).contains(httpResponse.statusCode) {
                    let error = NetworkError.serverError
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
                
                return data
            }
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { result in
                self.isLoading = false
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            } receiveValue: { [weak self] authResponse in
                self?.processAuthResponse(authResponse, completion)
            }
            .store(in: &cancellables)
    }
    
    private func processAuthResponse(_ authResponse: AuthResponse,
                                         _ completion: (Result<Bool, Error>) -> Void) {
        // Save token to Keychain or UserDefaults
        KeychainHelper.save(token: authResponse.jwtToken)
        // Save profile
        let profile = UserProfile(
            uid: authResponse.uid,
            username: authResponse.username,
            email: authResponse.email,
            referralCode: authResponse.referralCode,
            // TODO: convert URL to Data
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
    }
    
    func signUp(completion: @escaping (Result<Bool, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseUrl)/auth/register") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "username": username
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            errorMessage = "Error creating request"
            isLoading = false
            return
        }
        
        sendRequest(request, body: body, completion: completion)
    }
    
    func resetPassword(completion: @escaping (Result<Bool, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseUrl)/auth/reset-password") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            errorMessage = "Error creating request"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    throw NetworkError.serverError
                }
                
                return data
            }
            .decode(type: SimpleResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.isLoading = false
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            } receiveValue: { _ in
                completion(.success(true))
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Google SignIn
    
    func googleSignInButtonTapped(_ signInResult: GIDSignInResult?,
                                  _ error: (any Error)?,
                                  completion: @escaping (Result<Bool, Error>) -> Void) {
        guard error == nil else { return }
        guard let signInResult = signInResult else { return }
        
        signInResult.user.refreshTokensIfNeeded { user, error in
            guard error == nil else { return }
            guard let idToken = user?.idToken?.tokenString else { return }
            
            // Send ID token to backend
            self.googleTokenSignIn(idToken: idToken, completion: completion)
        }
    }
    
    func googleTokenSignIn(idToken: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseUrl)/auth/token-signin") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "idToken": idToken,
            "authMethod": "google"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            errorMessage = "Error creating request"
            isLoading = false
            return
        }
        
        sendRequest(request, body: body, completion: completion)
    }
    
    // MARK: - Apple SignIn
    
    func appleSignInButtonTapped(_ result: Result<ASAuthorization, any Error>, completion: @escaping (Result<Bool, Error>) -> Void) {
        
        switch result {
        case .success(let authorization):
            print("Authorization successful: \(authorization)")
            // 1. Handle credential
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                completion(.failure(NetworkError.serverError))
                return
            }
            
            // 2. Get user data
            let userIdentifier = credential.user
            let fullName = credential.fullName
            let email = credential.email
            
            // 3. Create or authenticate user on your backend
            appleTokenSignIn(
                id: userIdentifier,
                email: email,
                name: fullName,
                completion: completion
            )
        case .failure(let error):
            print("Authorization failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            completion(.failure(error))
        }
    }
    
    private func appleTokenSignIn(id: String,
                                    email: String?,
                                    name: PersonNameComponents?,
                                    completion: @escaping (Result<Bool, Error>) -> Void) {
        // 1. Prepare request to your backend
        let url = URL(string: "\(baseUrl)/auth/tokensignin")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 2. Create request body
        let nameFormatter = PersonNameComponentsFormatter()
        let body: [String: Any] = [
            "idToken": id,
            "authMethod": "apple",
            "email": email ?? "",
            "firstName": name?.givenName ?? "",
            "lastName": name?.familyName ?? "",
            "fullName": nameFormatter.string(from: name ?? PersonNameComponents())
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            errorMessage = "Error creating request"
            isLoading = false
            return
        }
        
        sendRequest(request, body: body, completion: completion)
    }
}
