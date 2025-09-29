//
//  File.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import Foundation

struct Equipment: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let location: String
    let createdAt: String
    let modifiedAt: String
    // Add more fields if API provides (e.g., isHighlighted: Bool)
}
