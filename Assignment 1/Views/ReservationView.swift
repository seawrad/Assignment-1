//
//  ReservationView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI
import Combine

struct ReservationsView: View {
    @StateObject private var viewModel = ReservationsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(viewModel.reservations) { reservation in
                VStack(alignment: .leading) {
                    Text("Equipment ID: \(reservation.equipmentId)")
                        .font(.headline)
                    Text("Reserved: \(reservation.reservedAt)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Unreserve") {
                        viewModel.unreserve(reservation)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(viewModel.isLoading)
                }
                .padding(.vertical, 4)
            }
            .refreshable {
                viewModel.loadReservations()
            }
            .navigationTitle("My Reservations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                viewModel.loadReservations()
            }
        }
    }
}

class ReservationsViewModel: ObservableObject {
    @Published var reservations: [Reservation] = []
    @Published var isLoading = false
    private let apiClient = APIClient.shared
    
    func loadReservations() {
        isLoading = true
        apiClient.fetchUserReservations { [weak self] resvs, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
                self?.reservations = resvs ?? []
            }
        }
    }
    
    func unreserve(_ reservation: Reservation) {
        isLoading = true
        apiClient.unreserveEquipment(equipmentId: reservation.equipmentId) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
                if success {
                    self?.reservations.removeAll { $0.equipmentId == reservation.equipmentId }
                }
            }
        }
    }
}

#Preview {
    ReservationsView()
}
