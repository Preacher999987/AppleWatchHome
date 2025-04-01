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
