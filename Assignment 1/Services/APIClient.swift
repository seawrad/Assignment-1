//
//  APIClient.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class APIClient: ObservableObject {
    static let shared = APIClient()
    private let baseURL = "https://comp4107-spring2025.azurewebsites.net/api"
    @AppStorage("authToken") var token: String = ""
    
    private func createURLRequest(path: String, method: String = "GET", body: Data? = nil) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)\(path)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.httpBody = body
        }
        return request
    }
    
    func fetchHighlightedEquipments(page: Int = 1, limit: Int = 10, completion: @escaping ([Equipment]?, Error?) -> Void) {
        let path = "/equipments?highlighted=true&page=\(page)&limit=\(limit)"
        guard let request = createURLRequest(path: path) else { return }
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(nil, error); return }
            guard let data = data else { completion(nil, NSError(domain: "NoData", code: 0)); return }
            let equipments = try? JSONDecoder().decode([Equipment].self, from: data)
            DispatchQueue.main.async { completion(equipments, nil) }
        }.resume()
    }
    
    func fetchEquipmentsByLocation(_ location: String, page: Int = 1, limit: Int = 10, completion: @escaping ([Equipment]?, Error?) -> Void) {
        let path = "/equipments?location=\(location)&page=\(page)&limit=\(limit)"
        guard let request = createURLRequest(path: path) else { return }
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(nil, error); return }
            guard let data = data else { completion(nil, NSError(domain: "NoData", code: 0)); return }
            let equipments = try? JSONDecoder().decode([Equipment].self, from: data)
            DispatchQueue.main.async { completion(equipments, nil) }
        }.resume()
    }
    
    func searchEquipments(query: String, page: Int = 1, limit: Int = 10, completion: @escaping ([Equipment]?, Error?) -> Void) {
        let path = "/equipments?q=\(query)&page=\(page)&limit=\(limit)"
        guard let request = createURLRequest(path: path) else { return }
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(nil, error); return }
            guard let data = data else { completion(nil, NSError(domain: "NoData", code: 0)); return }
            let equipments = try? JSONDecoder().decode([Equipment].self, from: data)
            DispatchQueue.main.async { completion(equipments, nil) }
        }.resume()
    }
    
    func fetchUserReservations(page: Int = 1, limit: Int = 10, completion: @escaping ([Reservation]?, Error?) -> Void) {
        let path = "/equipments?rentedByMe=true&page=\(page)&limit=\(limit)" // Placeholder; adjust per backend
        guard let request = createURLRequest(path: path) else { return }
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(nil, error); return }
            guard let data = data else { completion(nil, NSError(domain: "NoData", code: 0)); return }
            let reservations = try? JSONDecoder().decode([Reservation].self, from: data)
            DispatchQueue.main.async { completion(reservations, nil) }
        }.resume()
    }
    
    func login(email: String, password: String, completion: @escaping (AuthResponse?, Error?) -> Void) {
        let requestBody = try? JSONEncoder().encode(LoginRequest(email: email, password: password))
        guard let urlRequest = createURLRequest(path: "/login", method: "POST", body: requestBody) else { return }
        URLSession.shared.dataTask(with: urlRequest) { data, _, error in
            if let error = error { completion(nil, error); return }
            guard let data = data else { completion(nil, NSError(domain: "NoData", code: 0)); return }
            let response = try? JSONDecoder().decode(AuthResponse.self, from: data)
            if let response = response {
                self.token = response.token
            }
            DispatchQueue.main.async { completion(response, nil) }
        }.resume()
    }
    
    func register(user: RegisterRequest, completion: @escaping (AuthResponse?, Error?) -> Void) {
        let requestBody = try? JSONEncoder().encode(user)
        guard let urlRequest = createURLRequest(path: "/users", method: "POST", body: requestBody) else { return }
        URLSession.shared.dataTask(with: urlRequest) { data, _, error in
            if let error = error { completion(nil, error); return }
            guard let data = data else { completion(nil, NSError(domain: "NoData", code: 0)); return }
            let response = try? JSONDecoder().decode(AuthResponse.self, from: data)
            if let response = response {
                self.token = response.token
            }
            DispatchQueue.main.async { completion(response, nil) }
        }.resume()
    }
    
    func reserveEquipment(equipmentId: Int, completion: @escaping (Bool, Error?) -> Void) {
        let path = "/equipments/\(equipmentId)/rent"
        guard let request = createURLRequest(path: path, method: "POST") else { return }
        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = (response as? HTTPURLResponse)?.statusCode == 201
            DispatchQueue.main.async { completion(success, error) }
        }.resume()
    }
    
    func unreserveEquipment(equipmentId: Int, completion: @escaping (Bool, Error?) -> Void) { // Changed to equipmentId for DELETE
        let path = "/equipments/\(equipmentId)/rent"
        guard let request = createURLRequest(path: path, method: "DELETE") else { return }
        URLSession.shared.dataTask(with: request) { _, response, error in
            let success = (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async { completion(success, error) }
        }.resume()
    }
    
    func logout() {
        token = ""
        // Call POST /api/logout if needed
    }
}

extension AuthResponse: Sendable {}
extension Equipment: Sendable {}
extension Reservation: Sendable {}
