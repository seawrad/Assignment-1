//
//  LocationsView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI

struct LocationsView: View {
    @State private var selectedLocation: Location? = nil
    @State private var equipments: [Equipment] = []
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    private let apiClient = APIClient.shared
    let locations = Location.all

    var body: some View {
        NavigationView {
            if let selectedLocation = selectedLocation {
                EquipmentListView(equipments: equipments, isLoggedIn: !apiClient.token.isEmpty, location: selectedLocation.name, onLoadMore: loadMoreForLocation)
                    .navigationTitle(selectedLocation.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Back to Locations") {
                                self.selectedLocation = nil
                                equipments = []
                            }
                            .font(.subheadline)
                        }
                    }
                    .alert("Error", isPresented: $showingAlert) {
                        Button("OK") { }
                    } message: {
                        Text(alertMessage)
                    }
                    .onAppear {
                        loadInitialForLocation(selectedLocation)
                    }
            } else {
                List(locations) { location in
                    Button(action: {
                        selectedLocation = location
                    }) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.blue)
                            Text(location.name)
                                .font(.body)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .navigationTitle("Locations")
            }
        }
    }

    private func loadInitialForLocation(_ location: Location) {
        loadMoreForLocation()
    }

    private func loadMoreForLocation() {
        guard !isLoading else { return }
        isLoading = true
        apiClient.fetchEquipmentsByLocation(selectedLocation?.name ?? "", page: equipments.count / 10 + 1) { newEquipments, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    return
                }
                equipments.append(contentsOf: newEquipments ?? [])
            }
        }
    }
}

struct EquipmentListView: View {
    let equipments: [Equipment]
    let isLoggedIn: Bool
    let location: String
    let onLoadMore: () -> Void
    @State private var isLoading = false // Local state for this view

    var body: some View {
        List {
            LazyVStack(spacing: 0) {
                ForEach(equipments) { equipment in
                    NavigationLink(destination: EquipmentDetailView(equipment: equipment, isLoggedIn: isLoggedIn)) {
                        EquipmentRow(equipment: equipment) // Assume EquipmentRow defined elsewhere or add here
                    }
                }
                if isLoading {
                    ProgressView()
                        .padding()
                }
            }
        }
        .onAppear {
            if equipments.isEmpty {
                onLoadMore()
            }
        }
    }
}

#Preview {
    LocationsView()
}
