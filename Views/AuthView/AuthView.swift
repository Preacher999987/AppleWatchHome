//
//  AuthView.swift
//  Fun Kollector
//
//  Created by Home on 01.04.2025.
//


import SwiftUI
import AuthenticationServices
import GoogleSignInSwift
import GoogleSignIn

struct AuthView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject var appState: AppState
    
    @State private var showSuccessCheckmark = false
    
    // Consistent horizontal padding for all elements
    private let horizontalPadding: CGFloat = 20
    
    var body: some View {
        ZStack {
            // Background layer
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                // App Logo with constrained width
                Image(colorScheme == .dark ? "logo-white" : "logo-dark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                //                                .frame(height: 80)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 40)
                //                                .colorInvertIfLight()
                
                // Tab Selector
                HStack(spacing: 0) {
                    Button(action: {
                        viewModel.isSignIn = true
                    }) {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(viewModel.isSignIn ? .primary : .secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                viewModel.isSignIn ? Color.appPrimary.opacity(0.1) : Color.clear
                            )
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        viewModel.isSignIn = false
                    }) {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(!viewModel.isSignIn ? .primary : .secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                !viewModel.isSignIn ? Color.appPrimary.opacity(0.1) : Color.clear
                            )
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                
                // Form Container
                Group {
                    if viewModel.isSignIn {
                        signInView
                    } else {
                        signUpView
                    }
                }
                .transition(.opacity)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            
            // Success Checkmark Overlay
            if showSuccessCheckmark {
                SuccessCheckmarkView()
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation {
                                showSuccessCheckmark = false
                                dismiss()
                            }
                        }
                    }
            }
        }
    }
    
    private var signInView: some View {
        VStack(spacing: 20) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your email address?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Email Field
                TextField("Enter your email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    SecureField("Enter a password", text: $viewModel.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            // Continue Button
            Button(action: {
                viewModel.signIn(completion: processSignInResult)
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                } else {
                    Text("Continue")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.email.isEmpty || viewModel.isLoading)
            
            // Separator
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                
                Text("Or")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
            }
            .padding(.vertical, 16)
            
            // Social Sign In
            VStack(spacing: 12) {
                SignInWithAppleButton(.signIn,
                                      onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                                      onCompletion: appleSignInButtonTapped)
                .frame(height: 50)
                .cornerRadius(8)
                
                GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(style: .wide),
                                    action: googleSignInButtonTapped)
                    .cornerRadius(8)
                    
            }
        }
    }
    
    private var signUpView: some View {
        VStack(spacing: 20) {
            // Full Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Username")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Enter your username", text: $viewModel.username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
            }
            
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Enter your email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                SecureField("Enter a password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Terms and Privacy
            HStack(spacing: 4) {
                Text("By signing up, you agree to our")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Terms") {
                    // Show terms
                }
                .font(.caption)
                .foregroundColor(.appPrimary)
                
                Text("and")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Privacy Policy") {
                    // Show privacy policy
                }
                .font(.caption)
                .foregroundColor(.appPrimary)
            }
            .padding(.vertical, 8)
            
            // Create Account Button
            Button(action: {
                viewModel.signUp(completion: processSignInResult)
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                } else {
                    Text("Create Account")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty || viewModel.username.isEmpty || viewModel.isLoading)
            
            // Separator
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                
                Text("Or")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
            }
            .padding(.vertical, 16)
            
            // Social Sign Up
            VStack(spacing: 12) {
                SignInWithAppleButton(.signUp) { request in
                    // Configure request
                } onCompletion: { result in
                    // Handle completion
                }
                .frame(height: 50)
                .cornerRadius(8)
                
                Button(action: {
                    // Google sign up
                }) {
                    HStack {
                        Image("google-logo") // Add your Google logo asset
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                        Text("Sign up with Google")
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
            }
        }
    }
    
    fileprivate func processSignInResult(_ result: Result<Bool, any Error>) {
        if case .success = result {
            withAnimation {
                showSuccessCheckmark = true
            }
        }
    }
    
    private func googleSignInButtonTapped() {
        guard let rootViewController = getRootViewController() else {
            print("Could not find root view controller")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController) {
                viewModel.googleSignInButtonTapped($0, $1, completion: processSignInResult)
            }
    }
    
    private func appleSignInButtonTapped(_ result: Result<ASAuthorization, any Error>) {
        viewModel.appleSignInButtonTapped(result, completion: processSignInResult)
    }
}

// MARK: - Custom Button Style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.appPrimary)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
