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

extension UIDevice {
    static var isiPhoneSE: Bool {
        let screenHeight = UIScreen.main.nativeBounds.height
        // iPhone SE (1st gen): 1136, iPhone SE (2nd/3rd gen): 1334
        return screenHeight == 1136 || screenHeight == 1334
    }
}
