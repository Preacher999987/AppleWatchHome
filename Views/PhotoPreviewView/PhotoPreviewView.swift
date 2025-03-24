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
    
    // Add a closure for when analysis is complete
    let onAnalysisComplete: (AnalysisResult) -> Void
    
    // Create an instance of the ViewModel
    @StateObject private var viewModel = PhotoPreviewViewModel()
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                HStack {
                    Button(action: retakeAction) {
                        Text("Retake")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    Spacer()
                    Button(action: {
                        isLoading = true
                        viewModel.analyzePhoto(image: image) { result in
                            isLoading = false
                            switch result {
                            case .success(let data):
                                onAnalysisComplete(data)
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }) {
                        Text("Analyze")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(isLoading)
                }
                .padding()
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                }
            }
            .alert("Analysis Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .layoutPriority(1)
        }
    }
}
