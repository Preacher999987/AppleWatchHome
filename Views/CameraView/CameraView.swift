import SwiftUI
import UIKit

// MARK: - Main App
@main
struct FunkoCollector: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Main Content View
// Example usage in a parent view
struct ContentView: View {
    @State private var capturedImage: UIImage?
    @State private var analysisResult: AnalysisResult?
    @State private var showCamera = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let image = capturedImage {
                    if let result = analysisResult {
                        LazyGridGalleryView(payload: result)
                    } else {
                        PhotoPreviewView(
                            image: image,
                            retakeAction: { capturedImage = nil },
                            onAnalysisComplete: { result in
                                analysisResult = result
                            }
                        )
                    }
                } else {
                    Button("Take Photo") {
                        showCamera = true
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                // Your camera view here that sets capturedImage
                // For example:
                CameraView { image in
                    capturedImage = image
                    analysisResult = nil
                    showCamera = false
                }
            }
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let onPhotoCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        
        // Check if the device supports the desired camera mode
        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            picker.cameraDevice = .rear
        } else {
            print("Rear camera not available. Falling back to default.")
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onPhotoCaptured(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
