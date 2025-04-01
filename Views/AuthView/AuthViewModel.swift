//
//  AuthViewModel.swift
//  Fun Kollector
//
//  Created by Home on 01.04.2025.
//

import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var fullName: String = ""
    @Published var isSignIn: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let baseUrl = "http://192.168.1.17:3001"
    private var cancellables = Set<AnyCancellable>()
    
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
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                if httpResponse.statusCode == 401 {
                    throw AuthError.invalidCredentials
                } else if !(200...299).contains(httpResponse.statusCode) {
                    throw AuthError.serverError
                }
                
                return data
            }
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
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
            } receiveValue: { authResponse in
                // Save token to Keychain or UserDefaults
                KeychainHelper.save(token: authResponse.jwtToken)
                completion(.success(true))
            }
            .store(in: &cancellables)
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
            "fullName": fullName
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
                    throw AuthError.serverError
                }
                
                return data
            }
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
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
            } receiveValue: { authResponse in
                // Save token to Keychain or UserDefaults
//                KeychainHelper.save(token: authResponse.token, for: "auth-token")
                KeychainHelper.save(token: authResponse.jwtToken)
                completion(.success(true))
            }
            .store(in: &cancellables)
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
                    throw AuthError.serverError
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
    
    // MARK: - Helper Models
    
    struct AuthResponse: Codable {
        let jwtToken: String
        let uid: String
        let username: String?
        let referralCode: String
    }
    
    struct SimpleResponse: Codable {
        let message: String
    }
    
    enum AuthError: Error {
        case invalidCredentials
        case serverError
        
        var localizedDescription: String {
            switch self {
            case .invalidCredentials:
                return "Invalid email or password"
            case .serverError:
                return "Server error occurred"
            }
        }
    }
}
