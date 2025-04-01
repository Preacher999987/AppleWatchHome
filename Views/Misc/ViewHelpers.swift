//
//  ViewHelpers.swift
//  Fun Kollector
//
//  Created by Home on 29.03.2025.
//

import UIKit
import SwiftUI

struct ViewHelpers {
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


// Add this UIImage extension
extension UIImage {
    class func gifImage(data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let count = CGImageSourceGetCount(source)
        var images = [UIImage]()
        var duration = 0.0
        
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                images.append(image)
                
                let delaySeconds = UIImage.delayForImageAtIndex(i, source: source)
                duration += delaySeconds
            }
        }
        
        return UIImage.animatedImage(with: images, duration: duration)
    }
    
    class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifPropertiesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 0)
        if CFDictionaryGetValueIfPresent(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque(), gifPropertiesPointer) == false {
            return delay
        }
        
        let gifProperties = unsafeBitCast(gifPropertiesPointer.pointee, to: CFDictionary.self)
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        delay = delayObject as? Double ?? 0.1
        
        return delay
    }
}

class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    func push(_ route: String) {
        path.append(route)
    }
}
