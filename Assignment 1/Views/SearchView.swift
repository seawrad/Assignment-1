//
//  SearchView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI
import Combine

struct SearchView: View {
    @State private var searchText = ""
    @StateObject private var viewModel = SearchViewModel()
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText) { query in
                    Task {
                        await viewModel.performSearch(query)
                    }
                }
                .padding()

                if searchText.isEmpty {
                    Spacer()
                    Text("Enter a keyword to search equipments")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.results) { equipment in
                            NavigationLink(destination: EquipmentDetailView(equipment: equipment)) {
                                EquipmentRow(equipment: equipment)
                            }
                        }
                        if viewModel.hasMore {
                            Color.clear
                                .onAppear {
                                    Task {
                                        await viewModel.loadMore(query: searchText)
                                    }
                                }
                        }
                        if viewModel.isLoading {
                            ProgressView("Searching...")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .refreshable {
                        await viewModel.performSearch(searchText)
                    }
                }
            }
            .navigationTitle("Search")
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var results: [Equipment] = []
    @Published var isLoading = false
    @Published var hasMore = true
    private var currentPage = 1
    private let apiClient = APIClient.shared

    func performSearch(_ query: String) async {
        results = []
        currentPage = 1
        hasMore = true
        await loadMore(query: query)
    }

    func loadMore(query: String) async {
        guard !isLoading, hasMore, !query.isEmpty else { return }
        isLoading = true
        do {
            let response = try await apiClient.searchEquipments(query: query, page: currentPage)
            var newResults = response.equipments
            // Local sorting for better relevance: sort by name containing query
            newResults.sort { $0.name.lowercased().contains(query.lowercased()) && !$1.name.lowercased().contains(query.lowercased()) }
            results.append(contentsOf: newResults)
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
    SearchView()
}
