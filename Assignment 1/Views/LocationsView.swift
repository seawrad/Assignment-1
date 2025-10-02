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
    @State private var isLoadingLocations = false
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
                                Task {
                                    await loadMoreForLocation()
                                }
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
                    await loadMoreForLocation()
                }
                .alert("Error", isPresented: $showingAlert) {
                    Button("OK") { }
                } message: {
                    Text(alertMessage)
                }
                .task {
                    if equipments.isEmpty {
                        await loadMoreForLocation()
                    }
                }
            } else {
                Group {
                    if isLoadingLocations {
                        ProgressView("Loading locations...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if locations.isEmpty {
                        Text("No locations available")
                            .foregroundColor(.secondary)
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
                    }
                }
                .navigationTitle("Locations")
                .task { @Sendable in
                    await loadLocations()
                }
            }
        }
    }

    private func loadLocations() async {
        isLoadingLocations = true
        do {
            locations = try await apiClient.fetchLocations()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        isLoadingLocations = false
    }

    private func loadMoreForLocation() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
        do {
            let response = try await apiClient.fetchEquipmentsByLocation(selectedLocation?.name ?? "", page: currentPage)
            equipments.append(contentsOf: response.equipments)
            let loaded = response.page * response.perPage
            hasMore = loaded < response.total
            currentPage += 1
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
        isLoading = false
    }
}

#Preview {
    LocationsView()
}
