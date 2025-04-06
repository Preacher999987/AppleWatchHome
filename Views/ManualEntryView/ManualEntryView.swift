//
//  ManualEntryView.swift
//  FunKollector
//
//  Created by Home on 06.04.2025.
//

import SwiftUI

struct ManualEntryView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = ManualEntryViewModel()
    var onSearchResults: ([Collectible]) -> Void
    
    // Focus management
    private enum Field: Hashable { case name, reference, series, barcode }
    @FocusState private var focusedField: Field?
    
    var body: some View {
        ZStack {
            // Background dimming
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
            
            // Content card
            VStack(spacing: 20) {
                // Header with close button
                HStack {
                    Text("Add New Item")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Form fields
                VStack(spacing: 16) {
                    TextField("Name", text: $viewModel.name)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .name)
                    
                    TextField("Reference #", text: $viewModel.refNumber)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .reference)
                        .keyboardType(.numberPad)
                    
                    TextField("Series", text: $viewModel.series)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .series)
                    
                    TextField("Barcode (UPC)", text: $viewModel.barcode)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .barcode)
                        .keyboardType(.numberPad)
                }
                .padding(.horizontal, 20)
                
                // Loading and error states
                if viewModel.isLoading {
                    ProgressView()
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Action buttons
                HStack(spacing: 20) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                    
                    Button("Search") {
                        Task {
                            await viewModel.performSearch()
                            if !viewModel.searchResults.isEmpty {
                                onSearchResults(viewModel.searchResults)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appPrimary)
                    .disabled(!viewModel.canSearch)
                }
                .padding(.bottom, 20)
            }
            .blurredBackgroundRounded()
            .frame(width: 320)
            .onAppear {
                focusedField = .name
                viewModel.reset()
            }
        }
        .zIndex(10)
        .transition(.opacity)
    }
}

// Data model for the collected information
struct ItemData {
    let name: String
    let reference: String
    let series: String
    let barcode: String
}
