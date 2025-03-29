//
//  LaunchView.swift
//  Fun Kollector
//
//  Created by Home on 29.03.2025.
//

import SwiftUI
// MARK: - Main App
@main
struct FunkoCollector: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppState())
        }
    }
}

struct LaunchView: View {
    @State private var isActive = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if isActive {
                    ContentView()
            } else {
                GIFView(gifName: "animated-logo") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

struct GIFView: UIViewRepresentable {
    let gifName: String
    var onCompletion: (() -> Void)?
    @State private var animationFinished = false
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let imageView = UIImageView()
        
        if let gifURL = Bundle.main.url(forResource: gifName, withExtension: "gif"),
           let gifData = try? Data(contentsOf: gifURL),
           let gifImage = UIImage.gifImage(data: gifData) {
            
            imageView.image = gifImage
            imageView.animationImages = gifImage.images
            imageView.animationDuration = gifImage.duration
            imageView.animationRepeatCount = 1 // Play once
            
            // Start observing animation
            imageView.startAnimating()
            
            // Schedule completion handler
            DispatchQueue.main.asyncAfter(deadline: .now() + gifImage.duration) {
                imageView.removeFromSuperview()
//                self.onCompletion?()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + gifImage.duration + 0.25) {
//                imageView.removeFromSuperview()
                self.onCompletion?()
            }
        }
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
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
