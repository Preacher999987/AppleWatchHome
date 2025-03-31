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
            
            // Main Content Stack
            VStack {
                Spacer()
                
                // Enhanced AI Analysis Button
                Button(action: {
                    isLoading = true
                    viewModel.analyzePhoto(image: image) { result in
                        handleAnalysisResult(result)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.body.weight(.medium))
                            .foregroundColor(.appPrimary)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isLoading ? "Analyzing..." : "AI Analysis")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Identify collectible using computer vision")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(.black.opacity(0.6))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.appPrimary, lineWidth: 2)
                    )
                }
                .disabled(isLoading)
                .padding(.horizontal, 40) // Matches retake button's leading padding
                .padding(.bottom, 24)
                
                // Retake Button
                HStack {
                    Button(action: retakeAction) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.body.weight(.medium))
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.white.opacity(0.2)))
                            
                            Text("Retake Photo")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.black.opacity(0.25))
                        .cornerRadius(20)
                    }
                    Spacer()
                }
                .padding(.leading, 40)
                .padding(.bottom, 30)
            }
            
            if isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
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
                        .font(.system(size: 18, weight: .semibold)) // Larger text
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding()
            .background(isPrimary ? .appPrimary.opacity(0.7) : Color(.secondarySystemGroupedBackground).opacity(0.9))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
