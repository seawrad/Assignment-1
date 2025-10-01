//
//  UserView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI

struct UserView: View {
    @ObservedObject private var apiClient = APIClient.shared
    @State private var user: User? = nil
    @State private var showingLogin = false
    @State private var showingReservations = false

    var isLoggedIn: Bool {
        !apiClient.token.isEmpty
    }

    var body: some View {
        NavigationView {
            if isLoggedIn {
                List {
                    Section(header: Text("User Information")) {
                        Text("Name: \(user?.name ?? "Unknown")")
                        Text("Email: \(user?.email ?? "Unknown")")
                        if let department = user?.department {
                            Text("Department: \(department)")
                        }
                        if let remark = user?.remark {
                            Text("Remark: \(remark)")
                        }
                    }
                    
                    Button("View Reservations") {
                        showingReservations = true
                    }
                    
                    Button("Logout") {
                        apiClient.logout()
                        user = nil
                    }
                    .foregroundColor(.red)
                }
                .navigationTitle("User Profile")
            } else {
                VStack {
                    Text("Please log in or register to access reservations.")
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Login / Register") {
                        showingLogin = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .navigationTitle("User")
            }
        }
        .sheet(isPresented: $showingLogin) {
            LoginRegisterView(isPresented: $showingLogin, onSuccess: { newUser in
                user = newUser
            })
        }
        .sheet(isPresented: $showingReservations) {
            ReservationsView()
        }
    }
}

#Preview {
    UserView()
}
