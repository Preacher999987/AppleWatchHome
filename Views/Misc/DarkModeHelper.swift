//
//  ColorInvertOnDarkMode.swift
//  Fun Kollector
//
//  Created by Home on 01.04.2025.
//

import SwiftUI

// MARK: - Dark Mode Helpers

extension View {
    @ViewBuilder
    func colorInvertIfLight() -> some View {
        self.modifier(ColorInvertOnDarkMode())
    }
}

struct ColorInvertOnDarkMode: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        if colorScheme == .light {
            content.colorInvert()
        } else {
            content
        }
    }
}
