import SwiftUI
import UIKit

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

class AppState: ObservableObject {
    @Published var openMyCollection = false
    @Published var openRelated = false
    // Button visibility settings
    
    @Published var showCollectionButton = false
    @Published var showBackButton = true
    @Published var showAddToCollectionButton = false
    @Published var showPlusButton = false
    @Published var showEllipsisButton = false
}

struct PayloadWrapperView<Content: View>: View {
    @State private var localPayload: [Collectible]
    let content: (Binding<[Collectible]>) -> Content
    
    init(initialPayload: [Collectible],
         @ViewBuilder content: @escaping (Binding<[Collectible]>) -> Content) {
        self._localPayload = State(initialValue: initialPayload)
        self.content = content
    }
    
    var body: some View {
        content($localPayload)
    }
}

// MARK: - Main Content View
// Example usage in a parent view
struct ContentView: View {
    @State private var capturedImage: UIImage?
    @State private var analysisResult: [Collectible] = []
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    
    // Add navigation path if not already present
    @State private var navigationPath = NavigationPath()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                if appState.openMyCollection {
                    LazyGridGalleryView(payload: $analysisResult,
                                        dismissAction: {
                        // Reset to initial state when going back
                        capturedImage = nil
                        analysisResult = []
                        appState.openMyCollection = false
                    },
                                        seeMissingPopsAction: { selectedItem in
                        appState.openRelated = true
                        let newPayload = [selectedItem];
                        navigationPath.append(newPayload)
                    })
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: [Collectible].self) { newPayload in
                        // Wrap in a view that creates local state
                        PayloadWrapperView(initialPayload: newPayload) {
                            LazyGridGalleryView(
                                payload: $0,  // Now gets a real binding
                                dismissAction: {
                                    appState.openRelated = false
                                    navigationPath.removeLast()
                                },
                                seeMissingPopsAction: {_ in })
                            .toolbar(.hidden, for: .navigationBar) // Hide navigation bar if needed
                            
                        }
                    }
                } else if let image = capturedImage {
                    if !analysisResult.isEmpty {
                        LazyGridGalleryView(payload: $analysisResult,
                                            dismissAction: {
                            // Reset to initial state when going back
                            capturedImage = nil
                            
                            if let result = try? FunkoDatabase.loadItems(), !result.isEmpty {
                                appState.openMyCollection = true
                                appState.showAddToCollectionButton = false
                                analysisResult = result
                            }
                        }, seeMissingPopsAction: {_ in })
                        .toolbar(.hidden, for: .navigationBar)
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
                    VStack(spacing: 20) {
                        // Take Photo Button
                        Button(action: {
                            showCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                            }
                            .frame(width: 200, height: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        // Choose from Gallery Button
                        Button(action: {
                            showPhotoPicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose from Gallery")
                            }
                            .frame(width: 200, height: 44)
                        }
                        .buttonStyle(.bordered)
                        
                        // Show My Collection Button
                        Button(action: {
                            // Reset to initial state when going back
                            capturedImage = nil
                            
                            if let result = try? FunkoDatabase.loadItems(), !result.isEmpty {
                                analysisResult = result
                            }
                            appState.openMyCollection = true
                            appState.showCollectionButton = false
                            appState.showAddToCollectionButton = false
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("My Collection")
                            }
                            .frame(width: 200, height: 44)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    appState.showAddToCollectionButton = true
                    capturedImage = image
                    analysisResult = []
                    showCamera = false
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker { image in
                    appState.showAddToCollectionButton = true
                    capturedImage = image
                    analysisResult = []
                    showPhotoPicker = false
                }
            }
        }
    }
}

// MARK: - Photo Picker
struct PhotoPicker: UIViewControllerRepresentable {
    var completion: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var completion: (UIImage) -> Void
        
        init(completion: @escaping (UIImage) -> Void) {
            self.completion = completion
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                completion(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
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
