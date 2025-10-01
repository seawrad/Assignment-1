//
//  ReservationsView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI
import Combine

struct ReservationsView: View {
    @StateObject private var viewModel = ReservationsViewModel()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        List {
            ForEach(viewModel.reservedEquipments) { equipment in
                VStack(alignment: .leading) {
                    Text(equipment.name)
                        .font(.headline)
                    Text(equipment.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Unreserve") {
                        Task {
                            await viewModel.unreserve(equipment)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(viewModel.isLoading)
                }
                .padding(.vertical, 4)
            }
            if viewModel.hasMore {
                Color.clear
                    .onAppear {
                        Task {
                            await viewModel.loadMore()
                        }
                    }
            }
            if viewModel.isLoading {
                ProgressView("Loading more...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .refreshable {
            await viewModel.loadInitial()
        }
        .navigationTitle("My Reservations")
        .task {
            await viewModel.loadInitial()
        }
    }
}

@MainActor
class ReservationsViewModel: ObservableObject {
    @Published var reservedEquipments: [Equipment] = []
    @Published var isLoading = false
    @Published var hasMore = true
    private var currentPage = 1
    private let apiClient = APIClient.shared
    
    func loadInitial() async {
        currentPage = 1
        reservedEquipments = []
        hasMore = true
        await loadMore()
    }
    
    func loadMore() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
        do {
            let response = try await apiClient.fetchUserReservedEquipments(page: currentPage)
            reservedEquipments.append(contentsOf: response.equipments)
            let loaded = response.page * response.perPage
            hasMore = loaded < response.total
            currentPage += 1
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func unreserve(_ equipment: Equipment) async {
        isLoading = true
        do {
            try await apiClient.unreserveEquipment(equipmentId: equipment.id)
            reservedEquipments.removeAll { $0.id == equipment.id }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        isLoading = false
    }
}

#Preview {
    ReservationsView()
}
