//
//  User.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import Foundation

struct User: Codable {
    let id: Int
    let name: String
    let email: String
    let department: String?
    let remark: String?
    // Add color if API supports
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let name: String
    let email: String
    let password: String
    let department: String?
    let remark: String?
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct Reservation: Identifiable, Codable {
    let id: Int
    let equipmentId: Int
    let userId: Int
    let reservedAt: String
}
