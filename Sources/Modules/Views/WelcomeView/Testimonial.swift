//
//  Testimonial.swift
//  Fun Kollector
//
//  Created by Home on 01.04.2025.
//

import SwiftUI

struct Testimonial: Identifiable {
    let id = UUID()
    let text: String
    let author: String
    let collectionSize: String
}

struct TestimonialCard: View {
    let testimonial: Testimonial
    
    var body: some View {
        VStack(spacing: 12) {
            Text("""
                "\(testimonial.text)"
                """)
                .font(.body)
                .italic()
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 4) {
                Text(testimonial.author)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(testimonial.collectionSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
