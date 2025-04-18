//
//  APIClientProtocol.swift
//  FunKollector
//
//  Created by Home on 15.04.2025.
//

import Foundation

protocol APIClientProtocol {
    func isUserPhoto(_ imageData: ImageData) -> Bool
    func imageURL(from imageData: ImageData) -> URL?
    func upload<T: Decodable>(path: APIPath,
                              files: [MultipartFile],
                              formFields: [String: String]) async throws -> T
    func get<T: Decodable>(path: APIPath, queryItems: [URLQueryItem]?) async throws -> T
    func post<T: Decodable, U: Encodable>(path: APIPath, body: U) async throws -> T
}
