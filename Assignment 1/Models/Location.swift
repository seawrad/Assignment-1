//
//  Location.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import Foundation

struct Location: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

extension Location {
    static let all: [Location] = [
        Location(name: "Street"),
        Location(name: "Place"),
        Location(name: "Center"),
        Location(name: "Drive"),
        Location(name: "Avenue"),
        Location(name: "Trail"),
        Location(name: "Park"),
        Location(name: "Road"),
        Location(name: "Plaza"),
        Location(name: "Hill"),
        Location(name: "Parkway"),
        Location(name: "Crossing"),
        Location(name: "Pass"),
        Location(name: "Court"),
        Location(name: "Circle"),
        Location(name: "Lane"),
        Location(name: "Terrace"),
        Location(name: "Alley"),
        Location(name: "Point"),
        Location(name: "Way")
    ]
}
