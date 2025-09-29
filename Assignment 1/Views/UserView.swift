//
//  UserView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI
import Combine

struct UserView: View {
    @StateObject private var viewModel = UserViewModel()
    @State private var showingLogin = false
    @State private var showingReservations = false
    @State private var isRegisterMode = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = viewModel.user {
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if let department = user.department {
                            Text(department)
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 4)
                    
                    Button("View Reservations") {
                        showingReservations = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("Logout") {
                        viewModel.logout()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    VStack(spacing: 16) {
                        Text("Welcome")
                            .font(.title)
                            .fontWeight(.semibold)
                        Button("Login") {
                            isRegisterMode = false
                            showingLogin = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        Button("Register") {
                            isRegisterMode = true
                            showingLogin = true
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    }
                }
            }
            .padding()
            .navigationTitle("User")
            .sheet(isPresented: $showingLogin) {
                LoginRegisterView(onSuccess: viewModel.onAuthSuccess)
            }
            .sheet(isPresented: $showingReservations) {
                ReservationsView()
            }
        }
    }
}

class UserViewModel: ObservableObject {
    @Published var user: User?
    private let apiClient = APIClient.shared

    init() {
        if !apiClient.token.isEmpty {
            user = nil // Fetch via /api/users/{id} if you store user ID
        }
    }

    func onAuthSuccess(_ user: User) {
        self.user = user
    }

    func logout() {
        apiClient.logout()
        user = nil
    }
}

#Preview {
    UserView()
}
