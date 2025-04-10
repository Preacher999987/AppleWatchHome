//
//  DatePickerView.swift
//  FunKollector
//
//  Created by Home on 10.04.2025.
//

import SwiftUI

struct DatePickerView: View {
    @Binding var showDatePicker: Bool
    @Binding var selectedDate: Date
    var title: String
    var onDateSelected: ((Date) -> Void)?
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        showDatePicker = false
                    }
                }
            
            // Date picker container
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // Toolbar with title and buttons
                    HStack {
                        Button("Cancel") {
                            withAnimation {
                                showDatePicker = false
                            }
                        }
                        .foregroundColor(.appPrimary)
                        
                        Spacer()
                        
                        Text(title)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Done") {
                            onDateSelected?(selectedDate)
                            withAnimation {
                                showDatePicker = false
                            }
                        }
                        .foregroundColor(.appPrimary)
                    }
                    .padding()
                    
                    // Date picker
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: [.date] // Adjust components as needed
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                }
                .background(Color(.systemBackground))
                .cornerRadius(16, corners: [.topLeft, .topRight])
                .transition(.move(edge: .bottom))
            }
        }
        .zIndex(1) // Ensure it appears above other content
    }
}
