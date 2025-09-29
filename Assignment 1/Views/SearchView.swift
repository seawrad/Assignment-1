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
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.results) { equipment in
                                NavigationLink(destination: EquipmentDetailView(equipment: equipment, isLoggedIn: !APIClient.shared.token.isEmpty)) {
                                    EquipmentRow(equipment: equipment)
                                }
                            }
                            if viewModel.isLoading {
                                ProgressView("Searching...")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                    }
                    .refreshable {
                        viewModel.loadMore(query: searchText)
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
    private var currentPage = 1
    private let apiClient = APIClient.shared

    func performSearch(_ query: String) {
        results = []
        currentPage = 1
        loadMore(query: query)
    }

    func loadMore(query: String = "") {
        guard !isLoading, !query.isEmpty else { return }
        isLoading = true
        apiClient.searchEquipments(query: query, page: currentPage) { [weak self] equipments, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
                if self?.currentPage == 1 {
                    self?.results = equipments ?? []
                } else {
                    self?.results.append(contentsOf: equipments ?? [])
                }
                if !(equipments?.isEmpty ?? true) {
                    self?.currentPage += 1
                }
            }
        }
    }
}

#Preview {
    SearchView()
}
