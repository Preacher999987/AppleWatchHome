//
//  PhotoPreviewView.swift
//  FunkoCollector
//
//  Created by Home on 24.03.2025.
//
import SwiftUI

struct PhotoPreviewView: View {
    let image: UIImage
    let retakeAction: () -> Void
    let onAnalysisComplete: ([Collectible]) -> Void
    
    @StateObject private var viewModel = PhotoPreviewViewModel()
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showTypeMenu = false
    
    private let collectibleTypes = ["Funko Pop", "Trading Cards", "LEGO"]
    
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
                
                // Hint Text above the button
                Text("Identify collectible using computer vision")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                
                // AI Analysis Button with Type Selection Menu
                Menu {
                    Section {
                        ForEach(collectibleTypes, id: \.self) { type in
                            Button(action: {
                                Task {
                                    do {
                                        isLoading = true
                                        let result = try await viewModel.analyzePhoto(image: image, type: type)
                                        onAnalysisComplete(result)
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        showError = true
                                    }
                                    isLoading = false
                                }
                            }) {
                                Text(type)
                            }
                        }
                    } header: {
                        Text("Select collectible type")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.headline)
                            .foregroundColor(.appPrimary)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                        
                        Text(isLoading ? "Analyzing..." : "Lookup with AI")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.appPrimary)
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
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
                
                // Retake Button (unchanged)
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
            
            // Loading Indicator
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
}
