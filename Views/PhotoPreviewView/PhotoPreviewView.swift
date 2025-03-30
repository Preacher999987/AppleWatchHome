//
//  PhotoPreviewView.swift
//  FunkoCollector
//
//  Created by Home on 24.03.2025.
//
import SwiftUI

// MARK: - Photo Preview View
struct PhotoPreviewView: View {
    let image: UIImage
    let retakeAction: () -> Void
    let onAnalysisComplete: ([Collectible]) -> Void
    
    @StateObject private var viewModel = PhotoPreviewViewModel()
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background Image (unchanged)
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(
                    width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.height
                )
                .clipped()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.3))
            
            // Action Buttons - Now matching actionCard style
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    actionCard(
                        systemImage: "arrow.uturn.backward.circle.fill",
                        title: "Retake Photo",
                        description: "Capture a new image of your collectible",
                        color: .red,
                        action: retakeAction
                    )
                    
                    actionCard(
                        systemImage: "sparkles",
                        title: isLoading ? "Analyzing..." : "AI Analysis",
                        description: "Identify collectible using computer vision",
                        color: .green,
                        action: {
                            isLoading = true
                            viewModel.analyzePhoto(image: image) { result in
                                handleAnalysisResult(result)
                            }
                        },
                        isPrimary: true
                    )
                    .disabled(isLoading)
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 40)
            }
            
            if isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "d3a754")))
            }
        }
        .alert("Analysis Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleAnalysisResult(_ result: Result<[Collectible], Error>) {
        isLoading = false
        switch result {
        case .success(let data):
            onAnalysisComplete(data)
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // MARK: - Action Card Component
    
    private func actionCard(
        systemImage: String,
        title: String,
        description: String,
        color: Color,
        action: @escaping () -> Void,
        isPrimary: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
//                Image(systemName: "chevron.right")
//                    .foregroundColor(color)
            }
            .padding()
            .background(isPrimary ? Color(hex: "d3a754").opacity(0.7) : Color(.secondarySystemGroupedBackground).opacity(0.9))
            .cornerRadius(12)
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(color.opacity(0.3), lineWidth: 2)
//            )
        }
        .buttonStyle(.plain)
    }
}
