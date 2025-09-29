//
//  EquipmentDetailView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI

struct EquipmentDetailView: View {
    let equipment: Equipment
    let isLoggedIn: Bool
    @State private var isReserved = false  // Track local state; fetch from API in prod
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    private let apiClient = APIClient.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(equipment.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(equipment.description)
                    .font(.body)
                    .padding(.bottom, 8)
                
                HStack {
                    Label("Location", systemImage: "mappin")
                    Spacer()
                    Text(equipment.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("Created", systemImage: "calendar")
                    Spacer()
                    Text(equipment.createdAt)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("Modified", systemImage: "pencil")
                    Spacer()
                    Text(equipment.modifiedAt)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if isLoggedIn {
                    Button(isReserved ? "Unreserve" : "Reserve") {
                        toggleReserve()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isReserved ? .red : .green)
                    .disabled(isLoading)
                } else {
                    Text("Log in to reserve")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func toggleReserve() {
        isLoading = true
        if isReserved {
            apiClient.unreserveEquipment(equipmentId: equipment.id) { success, error in
                handleToggle(success: success, error: error, action: "unreserve")
            }
        } else {
            apiClient.reserveEquipment(equipmentId: equipment.id) { success, error in
                handleToggle(success: success, error: error, action: "reserve")
            }
        }
    }
    
    private func handleToggle(success: Bool, error: Error?, action: String) {
        DispatchQueue.main.async {
            isLoading = false
            if let error = error {
                alertMessage = "Failed to \(action): \(error.localizedDescription)"
                showingAlert = true
                return
            }
            if success {
                isReserved.toggle()
                alertMessage = "Successfully \(action)d!"
                showingAlert = true
            }
        }
    }
}

#Preview {
    EquipmentDetailView(equipment: Equipment(id: 1, name: "Sample", description: "Desc", location: "Street", createdAt: "2025-01-01", modifiedAt: "2025-01-01"), isLoggedIn: true)
}
