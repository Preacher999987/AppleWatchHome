//
//  ProfileInfoView.swift
//  Fun Kollector
//
//  Created by Home on 02.04.2025.
//

import SwiftUI

struct ProfileInfoView: View {
    @StateObject private var viewModel: ProfileInfoViewModel
    private let logoutAction: () -> Void
    
    // Image picker state
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    
    @State private var showShareSheet = false
    
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
                .onChange(of: selectedImage) { newImage in
                    if let imageData = newImage?.jpegData(compressionQuality: 0.8) {
                        Task {
                            try? await viewModel.updateProfileImage(imageData)
                        }
                    }
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
                    
                    //                    Button {
                    //                    } label: {
                    //                        Label("Account Settings", systemImage: "gear")
                    //                            .foregroundColor(.appPrimary)
                    //                    }
                    
                    Button {
                    } label: {
                        Label("Change Password", systemImage: "lock")
                            .foregroundColor(.appPrimary)
                    }
                }
                
                Section(header: Text("Settings").font(.subheadline)) {
                    Button {
                    } label: {
                        Label("Privacy Policy", systemImage: "shield")
                            .foregroundColor(.appPrimary)
                    }
                    
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share App", systemImage: "square.and.arrow.up")
                            .foregroundColor(.appPrimary)
                    }
                    .sheet(isPresented: $showShareSheet) {
                        ShareSheet(activityItems: [viewModel.appShareURL])
                            .presentationDetents([.medium, .large]) // Allows medium or full screen
                            .presentationDragIndicator(.visible) // Shows the grabber
                    }
                    
                    Button {
                        UIApplication.shared.open(viewModel.contactUsURL)
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
