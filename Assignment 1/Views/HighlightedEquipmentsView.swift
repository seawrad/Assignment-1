//
//  HighlightedEquipmentsView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI
import Combine

struct HighlightedEquipmentsView: View {
    @StateObject private var viewModel = EquipmentListViewModel(isLoggedIn: APIClient.shared.token != "")
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            List {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.equipments) { equipment in
                        NavigationLink(destination: EquipmentDetailView(equipment: equipment, isLoggedIn: viewModel.isLoggedIn)) {
                            EquipmentRow(equipment: equipment)
                        }
                    }
                    if viewModel.isLoading {
                        ProgressView("Loading more...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
            .refreshable {
                viewModel.loadInitial()
            }
            .navigationTitle("Highlighted Equipments")
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                viewModel.loadInitial()
            }
        }
    }
}

// EquipmentRow moved to SharedViews.swift

class EquipmentListViewModel: ObservableObject {
    @Published var equipments: [Equipment] = []
    @Published var isLoading = false
    let isLoggedIn: Bool
    private var currentPage = 0
    private let apiClient = APIClient.shared

    init(isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn
    }

    func loadInitial() {
        currentPage = 1
        loadMore()
    }

    func loadMore() {
        guard !isLoading else { return }
        isLoading = true
        apiClient.fetchHighlightedEquipments(page: currentPage) { [weak self] equipments, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
                if self?.currentPage == 1 {
                    self?.equipments = equipments ?? []
                } else {
                    self?.equipments.append(contentsOf: equipments ?? [])
                }
                if !(equipments?.isEmpty ?? true) {
                    self?.currentPage += 1
                }
            }
        }
    }
}

#Preview {
    HighlightedEquipmentsView()
}
