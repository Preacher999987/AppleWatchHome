//
//  AIPoweredBadge.swift
//  Fun Kollector
//
//  Created by Home on 29.03.2025.
//

import SwiftUI

struct AIPoweredBadge: View {
    var body: some View {
        Label {
            Text("AI-Powered")
                .font(.system(size: 12, weight: .semibold))
        } icon: {
            Image(systemName: "sparkles")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.appPrimary)
        .foregroundColor(.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}
