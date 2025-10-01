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
        let path = "/equipments?location=\(location)&page=\(page)&perPage=\(perPage)"
        return try await performRequest(path: path)
    }

    func searchEquipments(query: String, page: Int = 1, perPage: Int = 10) async throws -> PaginatedResponse {
        let path = "/equipments?q=\(query)&page=\(page)&perPage=\(perPage)"
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
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(PaginatedResponse.self, from: data)
    }

    func fetchLocations() async throws -> [Location] {
        let path = "/equipments?page=1&perPage=2000"  // High perPage to get all (~1013 total)
        let response = try await performRequest(path: path)
        let uniqueNames = Set(response.equipments.map { $0.location })
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
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)
        token = response.token
        _ = try await fetchUserReservedEquipments(page: 1, perPage: 1000)  // Fetch all reserved to populate IDs
        return response
    }

    func reserveEquipment(equipmentId: String) async throws {
        let path = "/equipments/\(equipmentId)/rent"
        guard let request = createURLRequest(path: path, method: "POST") else { throw URLError(.badURL) }
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
            reservedIds.insert(equipmentId)
        } else {
            throw URLError(.badServerResponse)
        }
    }

    func unreserveEquipment(equipmentId: String) async throws {
        let path = "/equipments/\(equipmentId)/rent"
        guard let request = createURLRequest(path: path, method: "DELETE") else { throw URLError(.badURL) }
        let (_, response) = try await URLSession.shared.data(for: request)
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
