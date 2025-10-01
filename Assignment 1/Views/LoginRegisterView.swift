//
//  LoginRegisterView.swift
//  Assignment 1
//
//  Created by f2239480 on 29/9/2025.
//

import SwiftUI

struct LoginRegisterView: View {
    @Binding var isPresented: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var department = ""
    @State private var remark = ""
    @State private var isRegister = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    let onSuccess: (User) -> Void
    private let apiClient = APIClient.shared
    
    var body: some View {
        Form {
            if isRegister {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                SecureField("Password", text: $password)
                TextField("Department (optional)", text: $department)
                TextField("Remark (optional)", text: $remark)
            } else {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                SecureField("Password", text: $password)
            }
            
            Button(isRegister ? "Register" : "Login") {
                Task {
                    await performAuth()
                }
            }
            .disabled(email.isEmpty || password.isEmpty || (isRegister && name.isEmpty))
            .buttonStyle(.borderedProminent)
            .tint(isRegister ? .green : .blue)
            
            Button(isRegister ? "Switch to Login" : "Switch to Register") {
                isRegister.toggle()
            }
            .buttonStyle(.bordered)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }
    
    private func performAuth() async {
        isLoading = true
        do {
            let response: AuthResponse
            if isRegister {
                let request = RegisterRequest(name: name, email: email, password: password, department: department.isEmpty ? nil : department, remark: remark.isEmpty ? nil : remark)
                response = try await apiClient.register(user: request)
            } else {
                response = try await apiClient.login(email: email, password: password)
            }
            onSuccess(response.user)
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        isLoading = false
    }
}

#Preview {
    LoginRegisterView(isPresented: .constant(true), onSuccess: { _ in })
}
