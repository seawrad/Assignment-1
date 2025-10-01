//
//  HighlightedEquipmentsView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI
import Combine

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
            .navigationTitle("Highlighted Equipments")
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                Task {
                    await viewModel.loadInitial()
                }
            }
        }
    }
}

@MainActor
class EquipmentListViewModel: ObservableObject {
    @Published var equipments: [Equipment] = []
    @Published var isLoading = false
    @Published var hasMore = true
    private var currentPage = 1
    let fetchFunction: (Int, Int) async throws -> PaginatedResponse

    init(fetchFunction: @escaping (Int, Int) async throws -> PaginatedResponse) {
        self.fetchFunction = fetchFunction
    }

    func loadInitial() async {
        currentPage = 1
        equipments = []
        hasMore = true
        await loadMore()
    }

    func loadMore() async {
        guard !isLoading, hasMore else { return }
        isLoading = true
        do {
            let response = try await fetchFunction(currentPage, 10)
            equipments.append(contentsOf: response.equipments)
            let loaded = response.page * response.perPage
            hasMore = loaded < response.total
            currentPage += 1
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        isLoading = false
    }
}

#Preview {
    HighlightedEquipmentsView()
}
