//
//  ReservationsView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI

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
                        viewModel.unreserve(equipment)
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
                        viewModel.loadMore()
                    }
                }
            if viewModel.isLoading {
                ProgressView("Loading more...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .refreshable {
            viewModel.loadInitial()
        }
        .navigationTitle("My Reservations")
        .onAppear {
            viewModel.loadInitial()
        }
    }
}

class ReservationsViewModel: ObservableObject {
    @Published var reservedEquipments: [Equipment] = []
    @Published var isLoading = false
    @Published var hasMore = true
    private var currentPage = 1
    private let apiClient = APIClient.shared
    
    func loadInitial() {
        currentPage = 1
        reservedEquipments = []
        hasMore = true
        loadMore()
    }
    
    func loadMore() {
        guard !isLoading, hasMore else { return }
        isLoading = true
        apiClient.fetchUserReservedEquipments(page: currentPage) { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }
                if let response = response {
                    self?.reservedEquipments.append(contentsOf: response.equipments)
                    let loaded = response.page * response.perPage
                    self?.hasMore = loaded < response.total
                    self?.currentPage += 1
                } else {
                    self?.hasMore = false
                }
            }
        }
    }
    
    func unreserve(_ equipment: Equipment) {
        isLoading = true
        apiClient.unreserveEquipment(equipmentId: equipment.id) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
                if success {
                    self?.reservedEquipments.removeAll { $0.id == equipment.id }
                }
            }
        }
    }
}

#Preview {
    ReservationsView()
}
