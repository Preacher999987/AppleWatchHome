//
//  GIFView.swift
//  Fun Kollector
//
//  Created by Home on 01.04.2025.
//

import SwiftUI

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
            imageView.contentMode = .scaleAspectFit // Add this to maintain aspect ratio
            
            // Start observing animation
            imageView.startAnimating()
            
            // Schedule completion handler
            DispatchQueue.main.asyncAfter(deadline: .now() + gifImage.duration) {
                self.onCompletion?()
            }
        }
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Modified constraints to maintain aspect ratio
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor)
        ])
        
        // Add aspect ratio constraint if we have the image
        if let image = imageView.image {
            let aspectRatio = image.size.width / image.size.height
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor,
                                          multiplier: aspectRatio).isActive = true
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
