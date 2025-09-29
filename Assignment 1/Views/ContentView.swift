//
//  ContentView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HighlightedEquipmentsView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Highlighted")
                }
            
            LocationsView()
                .tabItem {
                    Image(systemName: "mappin.and.ellipse")
                    Text("Locations")
                }
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            UserView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("User")
                }
        }
        .accentColor(.blue)
        .background(Color(.systemGray6))
    }
}

#Preview {
    ContentView()
}
