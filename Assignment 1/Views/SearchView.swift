//
//  SearchView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @StateObject private var viewModel = SearchViewModel()
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, onSearch: viewModel.performSearch)
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
                                    viewModel.loadMore(query: searchText)
                                }
                        }
                        if viewModel.isLoading {
                            ProgressView("Searching...")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .refreshable {
                        viewModel.performSearch(searchText)
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

class SearchViewModel: ObservableObject {
    @Published var results: [Equipment] = []
    @Published var isLoading = false
    @Published var hasMore = true
    private var currentPage = 1
    private let apiClient = APIClient.shared

    func performSearch(_ query: String) {
        results = []
        currentPage = 1
        hasMore = true
        loadMore(query: query)
    }

    func loadMore(query: String) {
        guard !isLoading, hasMore, !query.isEmpty else { return }
        isLoading = true
        apiClient.searchEquipments(query: query, page: currentPage) { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }
                if let response = response {
                    self?.results.append(contentsOf: response.equipments)
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
    SearchView()
}
