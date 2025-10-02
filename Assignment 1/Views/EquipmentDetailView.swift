//
//  EquipmentDetailView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI

struct EquipmentDetailView: View {
    let equipment: Equipment
    @ObservedObject var apiClient = APIClient.shared
    @State private var isReserved = false
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(equipment.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(equipment.description)
                    .font(.body)
                    .padding(.bottom, 8)
                
                if let imageURL = equipment.image, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 200)
                }
                
                HStack {
                    Label("Location", systemImage: "mappin")
                    Spacer()
                    Text(equipment.location ?? "Unknown")
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
                
                if !apiClient.token.isEmpty {
                    Button(isReserved ? "Unreserve" : "Reserve") {
                        Task {
                            await toggleReserve()
                        }
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
        .alert("Message", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            isReserved = apiClient.reservedIds.contains(equipment.id)
        }
    }
    
    private func toggleReserve() async {
        isLoading = true
        do {
            if isReserved {
                try await apiClient.unreserveEquipment(equipmentId: equipment.id)
                alertMessage = "Successfully unreserved!"
            } else {
                try await apiClient.reserveEquipment(equipmentId: equipment.id)
                alertMessage = "Successfully reserved!"
            }
            isReserved.toggle()
            showingAlert = true
        } catch {
            alertMessage = "Failed: \(error.localizedDescription)"
            showingAlert = true
        }
        isLoading = false
    }
}

#Preview {
    EquipmentDetailView(equipment: Equipment(id: "1", name: "Sample", description: "Desc", location: "Street", createdAt: "2025-01-01", modifiedAt: "2025-01-01", image: nil, color: nil, highlight: nil))
}
