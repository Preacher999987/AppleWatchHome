//
//  BarcodeScannerView.swift
//  Fun Kollector
//
//  Created by Home on 28.03.2025.
//


import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @State private var isScanning = true
    @State private var isLoading = false
    @State private var lastScannedCode = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onItemsFound: ([Collectible]) -> Void
    
    var body: some View {
        ZStack {
            // Camera View
            if isScanning {
                BarcodeScannerViewController(
                    isScanning: $isScanning,
                    lastScannedCode: $lastScannedCode,
                    onBarcodeFound: { code in
                        handleBarcodeFound(code)
                    }
                )
                .edgesIgnoringSafeArea(.all)
            }
            
            // Loading/Result View
            if isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.opacity(0.7))
            }
            // Close Button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .opacity(0.8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
        }
        .alert("Scan Error", isPresented: $showError) {
            Button("OK") {
                isScanning = true
                isLoading = false
            }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: lastScannedCode) { newValue in
            if !newValue.isEmpty {
                handleBarcodeFound(newValue)
            }
        }
    }
    
    private func handleBarcodeFound(_ code: String) {
        isScanning = false
        isLoading = true
        
        Task {
            do {
                let items = try await lookupBarcode(code)
                DispatchQueue.main.async {
                    onItemsFound(items)
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func lookupBarcode(_ upc: String) async throws -> [Collectible] {
        guard let url = URL(string: "http://192.168.1.17:3000/lookup?upc=\(upc)") else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Collectible].self, from: data)
    }
}

struct BarcodeScannerViewController: UIViewControllerRepresentable {
    @Binding var isScanning: Bool
    @Binding var lastScannedCode: String
    let onBarcodeFound: (String) -> Void
    
    func makeUIViewController(context: Context) -> ScannerVC {
        let vc = ScannerVC()
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ScannerVC, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, ScannerVCDelegate {
        let parent: BarcodeScannerViewController
        
        init(parent: BarcodeScannerViewController) {
            self.parent = parent
        }
        
        func didFindBarcode(_ code: String) {
            parent.lastScannedCode = code
            parent.onBarcodeFound(code)
        }
    }
}

protocol ScannerVCDelegate: AnyObject {
    func didFindBarcode(_ code: String)
}

class ScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerVCDelegate?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else { return }
        
        captureSession.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let code = readableObject.stringValue {
            captureSession.stopRunning()
            delegate?.didFindBarcode(code)
        }
    }
}
