//
//  ImagePicker.swift
//  FunKollector
//
//  Created by Home on 06.04.2025.
//

import SwiftUI
import PhotosUI // Import PhotosUI for PHPickerViewController

/// Image Picker using PHPickerViewController (multi-selection)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]?
    var selectionLimit: Int

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images // Allow only images
        configuration.selectionLimit = selectionLimit // 0 means unlimited selection

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            let dispatchGroup = DispatchGroup()
            var images: [UIImage] = []

            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    dispatchGroup.enter()
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        defer { dispatchGroup.leave() }

                        if let image = object as? UIImage {
                            images.append(image)
                        }
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                self.parent.selectedImages = images
            }
        }
    }
}
