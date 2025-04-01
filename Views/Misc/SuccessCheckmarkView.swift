//
//  SuccessCheckmarkView.swift
//  Fun Kollector
//
//  Created by Home on 01.04.2025.
//

import SwiftUI

// MARK: - Success Checkmark View
struct SuccessCheckmarkView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            Circle()
                .fill(Color.white)
                .frame(width: 120, height: 120)
            
            Image(systemName: "checkmark")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.appPrimary)
                .scaleEffect(animate ? 1.0 : 0.5)
                .opacity(animate ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: animate)
        }
        .onAppear {
            animate = true
        }
    }
}
