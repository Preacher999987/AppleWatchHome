//
//  ViewHelpers.swift
//  Fun Kollector
//
//  Created by Home on 29.03.2025.
//

import SwiftUI
import GoogleSignInSwift
import SafariServices
import UIKit

struct ViewHelpers {
    static func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}

class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    func push(_ route: String) {
        path.append(route)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// First, add this enum above your view struct
enum DetailRowStyle {
    case regular, browse, input(UIKeyboardType), media, returnValue, menu, datePicker, actionButton
}

struct TextFieldAlert<Presenting>: View where Presenting: View {
    @Binding var isPresented: Bool
    let presenting: Presenting
    let title: String
    @Binding var text: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            presenting
            
            if isPresented {
                // Background dimming
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }
                    .zIndex(1)
                
                // Content card
                VStack(spacing: 20) {
                    // Header with title (matching ManualEntryView)
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.appPrimary)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                isPresented = false
                            }
                            onCancel()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Text field
                    TextField("Enter value", text: $text)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 20)
                        .submitLabel(.done)
                    
                    // Action buttons (matching ManualEntryView's button style)
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            onCancel()
                            withAnimation {
                                isPresented = false
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.gray)
                        
                        Button("Save") {
                            onSave()
                            withAnimation {
                                isPresented = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.appPrimary)
                    }
                    .padding(.bottom, 20)
                }
                .blurredBackgroundRounded()
                .frame(width: 320)
                .zIndex(2)
                .transition(.opacity)
            }
        }
    }
}

// Safari View Controller wrapper for SwiftUI
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true
        return SFSafariViewController(url: url, configuration: config)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

// TODO: -
struct RarityIcon: View {
    let estimatedValue: Int
    
    var body: some View {
        Image(systemName: Rarity.common.iconName)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    TextFieldAlert(isPresented: .constant(true), presenting: LaunchView(), title: "Title", text: .constant("Some Text"), onSave: {}, onCancel: {})
}
