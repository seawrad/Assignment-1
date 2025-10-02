//
//  Equipment.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import Foundation

struct Equipment: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let location: String?
    let createdAt: String
    let modifiedAt: String
    let image: String?
    let color: String?
    let highlight: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case description
        case location
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
        case image
        case color
        case highlight
    }
}
