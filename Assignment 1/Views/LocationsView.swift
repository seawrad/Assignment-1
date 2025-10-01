//
//  LocationsView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI

struct LocationsView: View {
    @State private var locations: [Location] = []
    @State private var selectedLocation: Location? = nil
    @State private var equipments: [Equipment] = []
    @State private var currentPage = 1
    @State private var hasMore = true
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    private let apiClient = APIClient.shared

    var body: some View {
        NavigationView {
            if let selectedLocation = selectedLocation {
                List {
                    ForEach(equipments) { equipment in
                        NavigationLink(destination: EquipmentDetailView(equipment: equipment)) {
                            EquipmentRow(equipment: equipment)
                        }
                    }
                    if hasMore {
                        Color.clear
                            .onAppear {
                                loadMoreForLocation()
                            }
                    }
                    if isLoading {
                        ProgressView("Loading more...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .navigationTitle(selectedLocation.name)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back to Locations") {
                            self.selectedLocation = nil
                            equipments = []
                            currentPage = 1
                            hasMore = true
                        }
                    }
                }
                .refreshable {
                    currentPage = 1
                    equipments = []
                    hasMore = true
                    loadMoreForLocation()
                }
                .alert("Error", isPresented: $showingAlert) {
                    Button("OK") { }
                } message: {
                    Text(alertMessage)
                }
                .onAppear {
                    if equipments.isEmpty {
                        loadMoreForLocation()
                    }
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
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .navigationTitle("Locations")
                .onAppear {
                    if locations.isEmpty {
                        loadLocations()
                    }
                }
            }
        }
    }

    private func loadLocations() {
        apiClient.fetchLocations { newLocations, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
                return
            }
            locations = newLocations ?? []
        }
    }

    private func loadMoreForLocation() {
        guard !isLoading, hasMore else { return }
        isLoading = true
        apiClient.fetchEquipmentsByLocation(selectedLocation?.name ?? "", page: currentPage) { response, error in
            isLoading = false
            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
                return
            }
            if let response = response {
                equipments.append(contentsOf: response.equipments)
                let loaded = response.page * response.perPage
                hasMore = loaded < response.total
                currentPage += 1
            } else {
                hasMore = false
            }
        }
    }
}

#Preview {
    LocationsView()
}
