//
//  APIClient.swift
//  FunKollector
//
//  Created by Home on 15.04.2025.
//

import Foundation

class APIClient: APIClientProtocol {
    static let shared = APIClient()
    let baseURL = Config.baseURL(for: AppEnvironment.current)
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func imageURL(from imageData: ImageData) -> URL? {
        // 1. Try complete URL validation
        if let fullUrl = validateURL(imageData.url) {
            return fullUrl
        }
        
        // 2. Try constructing from base path
        if let filePath = imageData.filePath {
            let cleanedPath = filePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return url(for: .userPhotosBase, additionalPath: cleanedPath)
        }
        
        // 3. Return nil if no valid options
        return nil
    }
    
    func get<T: Decodable>(path: APIPath, queryItems: [URLQueryItem]? = nil) async throws -> T {
        try await request(method: "GET", path: path, queryItems: queryItems)
    }
    
    private func request<T: Decodable>(
        method: String,
        path: APIPath,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        // Construct URL
        guard var urlComponents = URLComponents(string: baseURL + path.path) else {
            throw NetworkError.invalidURL
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Add authorization header
        try request.addAuthorizationHeader()
        
        // Perform request
        let (data, response) = try await session.data(for: request)
        
        // Check response status
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 401, 403:
                throw AuthError.invalidCredentials
            case 500...599:
                throw NetworkError.serverError
            case 200...299:
                break // Success
            default:
                throw NetworkError.serverError
            }
        }
        
        // Decode response
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    func post<T: Decodable, U: Encodable>(
        path: APIPath,
        body: U
    ) async throws -> T {
        guard let url = URL(string: baseURL + path.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if needed
        try? request.addAuthorizationHeader()
        
        // Encode the request body
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        // Check response status
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 401, 403:
                throw AuthError.invalidCredentials
            case 500...599:
                throw NetworkError.serverError
            case 200...299:
                break // Success
            default:
                throw NetworkError.serverError
            }
        }
        
        // Decode response
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    func upload<T: Decodable>(
            path: APIPath,
            files: [MultipartFile],
            formFields: [String: String]
        ) async throws -> T {
            let boundary = "Boundary-\(UUID().uuidString)"
            let url = try makeURL(for: path)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            try? request.addAuthorizationHeader()
            
            request.httpBody = createMultipartBody(
                boundary: boundary,
                files: files,
                formFields: formFields
            )
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.serverError
            }
            
            return try JSONDecoder().decode(T.self, from: data)
        }
        
        private func createMultipartBody(
            boundary: String,
            files: [MultipartFile],
            formFields: [String: String]
        ) -> Data {
            var body = Data()
            let boundaryPrefix = "--\(boundary)\r\n"
            
            // Add form fields
            for (key, value) in formFields {
                body.append(boundaryPrefix.data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
            
            // Add files
            for file in files {
                body.append(boundaryPrefix.data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: .utf8)!)
                body.append(file.data)
                body.append("\r\n".data(using: .utf8)!)
            }
            
            // Add closing boundary
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            return body
        }
        
        private func makeURL(for path: APIPath) throws -> URL {
            let urlString = Config.baseURL(for: .current) + path.path
            guard let url = URL(string: urlString) else {
                throw NetworkError.invalidURL
            }
            return url
        }
    
    private func url(for path: APIPath, additionalPath: String? = nil) -> URL? {
        var urlString = Config.baseURL(for: .current) + path.path
        
        if let additionalPath = additionalPath {
            urlString += "/" + additionalPath
        }
        
        return URL(string: urlString)
    }
    
    private func validateURL(_ string: String) -> URL? {
        // Only accept strings that are valid URLs with a host
        if let url = URL(string: string), url.host != nil {
            return url
        }
        return nil
    }
}
