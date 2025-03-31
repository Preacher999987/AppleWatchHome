//
//  ViewHelpers.swift
//  Fun Kollector
//
//  Created by Home on 29.03.2025.
//

import UIKit
import SwiftUI

struct Helpers {
    static func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}
