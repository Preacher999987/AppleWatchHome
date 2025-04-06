//
//  View+Extensions.swift
//  FunKollector
//
//  Created by Home on 06.04.2025.
//


import SwiftUI

extension View {
    func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }
}

extension UIDevice {
    static var isiPhoneSE: Bool {
        let screenHeight = UIScreen.main.nativeBounds.height
        // iPhone SE (1st gen): 1136, iPhone SE (2nd/3rd gen): 1334
        return screenHeight == 1136 || screenHeight == 1334
    }
    static var isiPhone16Pro: Bool {
        let screenHeight = UIScreen.main.nativeBounds.height
        return screenHeight == 2622
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

extension View {
    func textFieldAlert(
        isPresented: Binding<Bool>,
        title: String,
        text: Binding<String>,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        TextFieldAlert(
            isPresented: isPresented,
            presenting: self,
            title: title,
            text: text,
            onSave: onSave,
            onCancel: onCancel
        )
    }
    
    func blurredBackgroundRounded() -> some View {
        self
            .background(
                ZStack {
                    VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                    Color.black.opacity(0.2)
                }
                    .cornerRadius(20)
            )
    }
}

// Custom View Modifier for Conditional Scaling
extension View {
    @ViewBuilder
    func applyConditionalScaling(isScaledToFit: Bool) -> some View {
        if isScaledToFit {
            self.scaledToFit() // Apply .scaledToFit() if condition is true
        } else {
            self.scaledToFill() // Apply .scaledToFill() if condition is false
        }
    }
}
