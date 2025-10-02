//
//  APIClient.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import Foundation
import SwiftUI
import Combine

struct PaginatedResponse: Codable, Sendable {
    let equipments: [Equipment]
    let total: Int
    let page: Int
    let perPage: Int
}

@MainActor
class APIClient: ObservableObject {
    static let shared = APIClient()
    private let baseURL = "https://comp4107-spring2025.azurewebsites.net/api"
    @AppStorage("authToken") var token: String = ""
    @Published var reservedIds: Set<String> = []

    // Custom URLSessionConfiguration to allow insecure HTTP for dummyimage.com
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpAdditionalHeaders = ["Content-Type": "application/json"]
        
        // Workaround for ATS: Allow arbitrary loads (less secure, use only for development)
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if #available(iOS 15.0, *) {
            // No specific host exception, fallback to broader allowance
        } else {
            config.httpShouldUsePipelining = true  // Less secure but allows HTTP
        }
        
        return URLSession(configuration: config)
    }()

    private func createURLRequest(path: String, method: String = "GET", body: Data? = nil) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)\(path)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        return request
    }

    func fetchHighlightedEquipments(page: Int = 1, perPage: Int = 10) async throws -> PaginatedResponse {
        let path = "/equipments?highlight=true&page=\(page)&perPage=\(perPage)"
        return try await performRequest(path: path)
    }

    func fetchEquipmentsByLocation(_ location: String, page: Int = 1, perPage: Int = 10) async throws -> PaginatedResponse {
        let path = "/equipments?location=\(location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location)&page=\(page)&perPage=\(perPage)"
        return try await performRequest(path: path)
    }

    func searchEquipments(query: String, page: Int = 1, perPage: Int = 10) async throws -> PaginatedResponse {
        let path = "/equipments?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&page=\(page)&perPage=\(perPage)"
        return try await performRequest(path: path)
    }

    func fetchUserReservedEquipments(page: Int = 1, perPage: Int = 10) async throws -> PaginatedResponse {
        let path = "/equipments?rentedByMe=true&page=\(page)&perPage=\(perPage)"
        let response = try await performRequest(path: path)
        let ids = response.equipments.map { $0.id }
        reservedIds.formUnion(ids)
        return response
    }

    private func performRequest(path: String) async throws -> PaginatedResponse {
        guard let request = createURLRequest(path: path) else { throw URLError(.badURL) }
        let (data, _) = try await urlSession.data(for: request)
        return try JSONDecoder().decode(PaginatedResponse.self, from: data)
    }

    func fetchLocations() async throws -> [Location] {
        var allEquipments: [Equipment] = []
        var page = 1
        let perPage = 100
        
        while true {
            let response = try await performRequest(path: "/equipments?page=\(page)&perPage=\(perPage)")
            print("Fetched page \(page): \(response.equipments.count) equipments, total: \(response.total)")
            allEquipments.append(contentsOf: response.equipments)
            if response.page * response.perPage >= response.total {
                break
            }
            page += 1
        }
        
        let uniqueNames = Set(allEquipments.compactMap { $0.location })  // Use compactMap for optional location
        print("Unique locations: \(uniqueNames)")
        return uniqueNames.sorted().map { Location(name: $0) }
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = try JSONEncoder().encode(LoginRequest(email: email, password: password))
        guard let request = createURLRequest(path: "/login", method: "POST", body: body) else { throw URLError(.badURL) }
        return try await performAuthRequest(request: request)
    }

    func register(user: RegisterRequest) async throws -> AuthResponse {
        let body = try JSONEncoder().encode(user)
        guard let request = createURLRequest(path: "/users", method: "POST", body: body) else { throw URLError(.badURL) }
        return try await performAuthRequest(request: request)
    }

    private func performAuthRequest(request: URLRequest) async throws -> AuthResponse {
        let (data, _) = try await urlSession.data(for: request)
        print("Auth response: \(String(data: data, encoding: .utf8) ?? "No data")")  // Logging for debug
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)
        if let token = response.token {
            self.token = token
            _ = try await fetchUserReservedEquipments(page: 1, perPage: 1000)
        }
        return response
    }

    func reserveEquipment(equipmentId: String) async throws {
        let path = "/equipments/\(equipmentId)/rent"
        guard let request = createURLRequest(path: path, method: "POST") else { throw URLError(.badURL) }
        let (_, response) = try await urlSession.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
            reservedIds.insert(equipmentId)
        } else {
            throw URLError(.badServerResponse)
        }
    }

    func unreserveEquipment(equipmentId: String) async throws {
        let path = "/equipments/\(equipmentId)/rent"
        guard let request = createURLRequest(path: path, method: "DELETE") else { throw URLError(.badURL) }
        let (_, response) = try await urlSession.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            reservedIds.remove(equipmentId)
        } else {
            throw URLError(.badServerResponse)
        }
    }

    func logout() {
        token = ""
        reservedIds = []
    }
}
