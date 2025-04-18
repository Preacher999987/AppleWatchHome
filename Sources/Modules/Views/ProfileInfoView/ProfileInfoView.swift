//
//  ProfileInfoView.swift
//  Fun Kollector
//
//  Created by Home on 02.04.2025.
//

import SwiftUI

struct ProfileInfoView: View {
    @StateObject private var viewModel: ProfileInfoViewModel
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    private let logoutAction: () -> Void
    
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    @State private var activeDestination: SafariViewDestination?
    
    init(logoutAction: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: ProfileInfoViewModel())
        self.logoutAction = logoutAction
    }
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tint(.appPrimary)
                } else if let profile = viewModel.userProfile {
                    menuContent(profile: profile)
                } else {
                    noUserContent
                }
            }
            .navigationTitle("Account Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ProfileImagePicker(selectedImage: $selectedImage)
            }
            .sheet(item: $activeDestination) { destination in
                if let url = destination.url {
                    SafariView(url: url)
                }
            }
            .onChange(of: selectedImage) { newImage in
                if let imageData = newImage?.jpegData(compressionQuality: 0.8) {
                    Task {
                        try? await viewModel.updateProfileImage(imageData)
                    }
                }
            }
            .task {
                await subscriptionManager.checkOnAppLaunch()
            }
        }
    }
    
    private func menuContent(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with user info
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    ZStack(alignment: .topTrailing) {
                        if let image = profile.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.appPrimary, lineWidth: 2)
                                )
                        } else {
                            Button {
                                isImagePickerPresented = true
                            } label: {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.appPrimary)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.appPrimary, lineWidth: 2)
                                    )
                            }
                        }
                        
                        // Edit button
                        Button {
                            isImagePickerPresented = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.appPrimary)
                                .background(Color.black)
                                .clipShape(Circle())
                                .offset(x: 0, y: 0)
                        }
                    }
                    .frame(width: 60, height: 60)
                    .padding(.trailing, 12)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(profile.username ?? "Unknown User")
                                .font(.title3.weight(.semibold))
                            if let email = profile.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Menu items
            List {
                Section(header: Text("Profile Info").font(.subheadline)) {
                    Label {
                        Text(profile.email ?? "-")
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "envelope")
                            .foregroundColor(.appPrimary)
                    }
                }
                
                // New Subscription Section
                Section(header: Text("Subscription").font(.subheadline)) {
                    Label {
                        Text(subscriptionStatusText)
                            .foregroundColor(subscriptionStatusColor)
                    } icon: {
                        Image(systemName: "crown")
                            .foregroundColor(.appPrimary)
                    }
                    
//                    if let lastVerifiedDate = subscriptionManager.lastVerifiedDate {
//                        Label {
//                            Text(lastVerifiedDate.formatted())
//                                .foregroundColor(.secondary)
//                        } icon: {
//                            Image(systemName: "clock")
//                                .foregroundColor(.appPrimary)
//                        }
//                    }
                }
                
                Section(header: Text("Settings").font(.subheadline)) {
                    Button {
                        activeDestination = .privacyPolicy
                    } label: {
                        Label("Terms & Privacy Policy", systemImage: "shield")
                            .foregroundColor(.appPrimary)
                    }
                    
                    Button {
                        activeDestination = .shareApp
                    } label: {
                        Label("Share App", systemImage: "square.and.arrow.up")
                            .foregroundColor(.appPrimary)
                    }
                    
                    Button {
                        activeDestination = .instagram
                    } label: {
                        Label("Follow Us", systemImage: "camera")
                            .foregroundColor(.appPrimary)
                    }
                    
                    Button {
                        if let url = SafariViewDestination.contactUs.url {
                            if UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            } else {
                                activeDestination = .contactUs
                            }
                        }
                    } label: {
                        Label("Contact Us", systemImage: "envelope")
                            .foregroundColor(.appPrimary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            // Sign out button at bottom
            VStack {
                Divider()
                Button(role: .destructive) {
                    dismiss()
                    viewModel.logout()
                    logoutAction()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
    }
    
    private var subscriptionStatusText: String {
        switch subscriptionManager.subscriptionStatus {
        case .active: return "Active"
        case .expired: return "Expired"
        case .neverPurchased: return "Inactive"
        case .unknown: return "Unknown"
        }
    }
    
    private var subscriptionStatusColor: Color {
        switch subscriptionManager.subscriptionStatus {
        case .active: return .green
        case .expired: return .orange
        case .neverPurchased: return .gray
        case .unknown: return .red
        }
    }
    
    private var noUserContent: some View {
        VStack {
            Text("No user profile found")
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func shareApp() {
        let url = URL(string: "https://yourapp.com")!
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
    }
}
