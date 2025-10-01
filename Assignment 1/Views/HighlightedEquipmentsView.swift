//
//  HighlightedEquipmentsView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI

struct HighlightedEquipmentsView: View {
    @StateObject private var viewModel = EquipmentListViewModel(fetchFunction: APIClient.shared.fetchHighlightedEquipments)
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.equipments) { equipment in
                    NavigationLink(destination: EquipmentDetailView(equipment: equipment)) {
                        EquipmentRow(equipment: equipment)
                    }
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

class EquipmentListViewModel: ObservableObject {
    @Published var equipments: [Equipment] = []
    @Published var isLoading = false
    @Published var hasMore = true
    private var currentPage = 1
    let fetchFunction: (Int, Int, @escaping (PaginatedResponse?, Error?) -> Void) -> Void

    init(fetchFunction: @escaping (Int, Int, @escaping (PaginatedResponse?, Error?) -> Void) -> Void) {
        self.fetchFunction = fetchFunction
    }

    func loadInitial() {
        currentPage = 1
        equipments = []
        hasMore = true
        loadMore()
    }

    func loadMore() {
        guard !isLoading, hasMore else { return }
        isLoading = true
        fetchFunction(currentPage, 10) { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }
                if let response = response {
                    self?.equipments.append(contentsOf: response.equipments)
                    let loaded = response.page * response.perPage
                    self?.hasMore = loaded < response.total
                    self?.currentPage += 1
                } else {
                    self?.hasMore = false
                }
            }
        }
    }
}

#Preview {
    HighlightedEquipmentsView()
}
