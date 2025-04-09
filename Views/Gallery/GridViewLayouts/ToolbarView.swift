//
//  ToolbarView.swift
//  FunKollector
//
//  Created by Home on 08.04.2025.
//

import SwiftUI

struct ToolbarView<ViewModel: GridViewToolbarProtocol & ObservableObject>: View {
    @ObservedObject var viewModel: ViewModel
    
    var columnLayoutActive: Bool = true
    
    var body: some View {
        HStack {
            honeycombGridLayoutButton
            if columnLayoutActive {
                columnCountMenu
                
                Button {
                    viewModel.showSections.toggle()
                } label: {
                    Image(systemName: viewModel.showSections ? "rectangle.grid.1x2.fill" : "rectangle.grid.1x2")
                        .padding(8)
                        .background(
                            Capsule()
                                .fill(.black.opacity(0.5))
                                .shadow(radius: 2)
                        )
                        .clipShape(Circle())
                        .foregroundColor(.appPrimary)
                }
            }
            
            Spacer()
            
            filterButton
            
            sortButton
        }
        .padding()
        .padding(.bottom, 40)
    }
    
    // MARK: - Subviews
    
    private var columnCountMenu: some View {
        Menu {
            ForEach(1...4, id: \.self) { columns in
                Button(action: { viewModel.setColumnCount(columns) }) {
                    HStack {
                        Text("\(columns) Columns")
                        if viewModel.columnCount == columns {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "square.grid.2x2")
                .padding(8)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.5))
                        .shadow(radius: 2)
                )
                .clipShape(Circle())
                .foregroundColor(.appPrimary)
        }
    }
    
    private var honeycombGridLayoutButton: some View {
        Button(action: {
            viewModel.toggleHoneycombGridLayout()
        }) {
            Image(systemName: "circle.grid.3x3")
                .padding(8)
                .background(
                    Group {
                        if !viewModel.isHoneycombGridViewLayoutActive {
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue, .green]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.black.opacity(0.5)
                        }
                    }
                )
                .clipShape(Circle())
                .shadow(radius: 2)
                .foregroundColor(.appPrimary)
                .overlay(
                    Group {
                        if !viewModel.isHoneycombGridViewLayoutActive {
                            Circle()
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]),
                                        center: .center
                                    ),
                                    lineWidth: 2
                                )
                        }
                    }
                )
        }
        .padding(.leading, 8)
    }
    
    private var filterButton: some View {
        Menu {
            Button {
                withAnimation {
                    viewModel.selectedFilter = nil
                }
            } label: {
                HStack {
                    Text("All Subjects")
                    if viewModel.selectedFilter == nil {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Divider()
            
            ForEach(viewModel.filterOptions(), id: \.self) { subject in
                Button {
                    withAnimation {
                        viewModel.selectedFilter = subject
                    }
                } label: {
                    HStack {
                        Text(subject)
                        if viewModel.selectedFilter == subject {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .padding(8)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.5))
                        .shadow(radius: 2)
                )
                .clipShape(Circle())
                .foregroundColor(.appPrimary)
        }
    }
    
    private var sortButton: some View {
        Menu {
            // Default selection (first option)
            let defaultOption = viewModel.sortOptions().first ?? .nameAZ
            Button {
                withAnimation {
                    viewModel.selectedSortOption = defaultOption
                }
            } label: {
                HStack {
                    Text(defaultOption.rawValue)
                    if viewModel.selectedSortOption == defaultOption {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Divider()
            
            // All sort options
            ForEach(viewModel.sortOptions().filter({ $0 != .series }), id: \.self) { option in
                Button {
                    withAnimation {
                        viewModel.selectedSortOption = option
                    }
                } label: {
                    HStack {
                        Text(option.rawValue)
                        if viewModel.selectedSortOption == option {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            // Bottom separator
            Divider()
            
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .padding(8)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.5))
                        .shadow(radius: 2)
                )
                .clipShape(Circle())
                .foregroundColor(.appPrimary)
        }
    }
}
