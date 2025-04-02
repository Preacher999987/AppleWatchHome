struct SideMenuView: View {
    let profile: UserProfile
    let logoutAction: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Header with user info
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.appPrimary)
                        
                        VStack(alignment: .leading) {
                            Text(profile.username)
                                .font(.title3.weight(.semibold))
                            Text(profile.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                }
                .padding()
                
                // Menu items
                List {
                    Section {
                        NavigationLink {
                            // Profile edit view would go here
                            Text("Edit Profile")
                                .navigationTitle("Edit Profile")
                        } label: {
                            Label("Edit Profile", systemImage: "person.fill")
                        }
                        
                        NavigationLink {
                            Text("Account Settings")
                                .navigationTitle("Account Settings")
                        } label: {
                            Label("Account Settings", systemImage: "gear")
                        }
                        
                        NavigationLink {
                            Text("Password")
                                .navigationTitle("Password")
                        } label: {
                            Label("Password", systemImage: "lock")
                        }
                    }
                    
                    Section {
                        NavigationLink {
                            Text("Privacy Policy")
                                .navigationTitle("Privacy Policy")
                        } label: {
                            Label("Privacy Policy", systemImage: "shield")
                        }
                        
                        Button {
                            // Share action
                            let url = URL(string: "https://yourapp.com")!
                            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                            UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
                        } label: {
                            Label("Share App", systemImage: "square.and.arrow.up")
                        }
                        
                        NavigationLink {
                            Text("Contact Us")
                                .navigationTitle("Contact Us")
                        } label: {
                            Label("Contact Us", systemImage: "envelope")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                // Sign out button at bottom
                VStack {
                    Divider()
                    Button(role: .destructive) {
                        dismiss()
                        logoutAction()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            }
            .navigationTitle("Menu")
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
}