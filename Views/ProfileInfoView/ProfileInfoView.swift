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
        }
    }
    
    private func menuContent(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with user info
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.appPrimary)
                    
                    VStack(alignment: .leading) {
                        Text(profile.username ?? "Unknown User")
                            .font(.title3.weight(.semibold))
                        if let email = profile.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
            }
            .padding()
            
            // Menu items
            List {
                Section {
                    Button {
                    } label: {
                        Label("Edit Username", systemImage: "person.fill")
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
                
                Section {
                    Button {
                    } label: {
                        Label("Privacy Policy", systemImage: "shield")
                            .foregroundColor(.appPrimary)
                    }
                    
                    Button {
                    } label: {
                        Label("Share App", systemImage: "square.and.arrow.up")
                            .foregroundColor(.appPrimary)
                    }
                    
                    Button {
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
