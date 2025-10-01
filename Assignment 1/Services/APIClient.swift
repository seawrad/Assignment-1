//
//  APIClient.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import Foundation
import SwiftUI

struct PaginatedResponse: Codable {
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

    func fetchHighlightedEquipments(page: Int = 1, perPage: Int = 10, completion: @escaping (PaginatedResponse?, Error?) -> Void) {
        let path = "/equipments?highlight=true&page=\(page)&perPage=\(perPage)"
        performRequest(path: path, completion: completion)
    }

    func fetchEquipmentsByLocation(_ location: String, page: Int = 1, perPage: Int = 10, completion: @escaping (PaginatedResponse?, Error?) -> Void) {
        let path = "/equipments?location=\(location)&page=\(page)&perPage=\(perPage)"
        performRequest(path: path, completion: completion)
    }

    func searchEquipments(query: String, page: Int = 1, perPage: Int = 10, completion: @escaping (PaginatedResponse?, Error?) -> Void) {
        let path = "/equipments?q=\(query)&page=\(page)&perPage=\(perPage)"
        performRequest(path: path, completion: completion)
    }

    func fetchUserReservedEquipments(page: Int = 1, perPage: Int = 10, completion: @escaping (PaginatedResponse?, Error?) -> Void) {
        let path = "/equipments?rentedByMe=true&page=\(page)&perPage=\(perPage)"
        performRequest(path: path) { response, error in
            if let response = response {
                let ids = response.equipments.map { $0.id }
                self.reservedIds.formUnion(ids)
            }
            completion(response, error)
        }
    }

    private func performRequest(path: String, completion: @escaping (PaginatedResponse?, Error?) -> Void) {
        guard let request = createURLRequest(path: path) else { return }
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(nil, error); return }
            guard let data = data else { completion(nil, NSError(domain: "NoData", code: 0)); return }
            let response = try? JSONDecoder().decode(PaginatedResponse.self, from: data)
            DispatchQueue.main.async { completion(response, nil) }
        }.resume()
    }

    func fetchLocations(completion: @escaping ([Location]?, Error?) -> Void) {
        let path = "/equipments?page=1&perPage=2000"  // High perPage to get all (~1013 total)
        performRequest(path: path) { response, error in
            if let error = error { completion(nil, error); return }
            let uniqueNames = Set(response?.equipments.map { $0.location } ?? [])
            let locations = uniqueNames.sorted().map { Location(name: $0) }
            completion(locations, nil)
        }
    }

    func login(email: String, password: String, completion: @escaping (AuthResponse?, Error?) -> Void) {
        let body = try? JSONEncoder().encode(LoginRequest(email: email, password: password))
        guard let request = createURLRequest(path: "/login", method: "POST", body: body) else { return }
        performAuthRequest(request: request, completion: completion)
    }

    func register(user: RegisterRequest, completion: @escaping (AuthResponse?, Error?) -> Void) {
        let body = try? JSONEncoder().encode(user)
        guard let request = createURLRequest(path: "/users", method: "POST", body: body) else { return }
        performAuthRequest(request: request, completion: completion)
    }

    private func performAuthRequest(request: URLRequest, completion: @escaping (AuthResponse?, Error?) -> Void) {
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(nil, error); return }
            guard let data = data else { completion(nil, NSError(domain: "NoData", code: 0)); return }
            let response = try? JSONDecoder().decode(AuthResponse.self, from: data)
            if let response = response {
                self.token = response.token
                self.fetchUserReservedEquipments { _, _ in }  // Initial fetch for reservedIds
            }
            DispatchQueue.main.async { completion(response, nil) }
        }.resume()
    }

    func reserveEquipment(equipmentId: String, completion: @escaping (Bool, Error?) -> Void) {
        let path = "/equipments/\(equipmentId)/rent"
        guard let request = createURLRequest(path: path, method: "POST") else { return }
        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = (response as? HTTPURLResponse)?.statusCode == 201
            if success { self.reservedIds.insert(equipmentId) }
            DispatchQueue.main.async { completion(success, error) }
        }.resume()
    }

    func unreserveEquipment(equipmentId: String, completion: @escaping (Bool, Error?) -> Void) {
        let path = "/equipments/\(equipmentId)/rent"
        guard let request = createURLRequest(path: path, method: "DELETE") else { return }
        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = (response as? HTTPURLResponse)?.statusCode == 200
            if success { self.reservedIds.remove(equipmentId) }
            DispatchQueue.main.async { completion(success, error) }
        }.resume()
    }

    func logout() {
        token = ""
        reservedIds = []
    }
}

extension AuthResponse: Sendable {}
extension Equipment: Sendable {}
