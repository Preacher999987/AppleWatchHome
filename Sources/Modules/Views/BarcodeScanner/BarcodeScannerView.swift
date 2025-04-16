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
    @State private var isTorchOn = false
    @State private var detectedBarcodeFrame: CGRect? = nil
    @State private var isProcessingBarcode = false

    let onItemsFound: ([Collectible]) -> Void
    
    private let apiClient: APIClientProtocol
    
    init(
        onItemsFound: @escaping ([Collectible]) -> Void,
        apiClient: APIClientProtocol = APIClient.shared
    ) {
        self.onItemsFound = onItemsFound
        self.apiClient = apiClient
    }

    var body: some View {
        ZStack {
            if isScanning {
                BarcodeScannerViewController(
                    isScanning: $isScanning,
                    lastScannedCode: $lastScannedCode,
                    isTorchOn: $isTorchOn,
                    detectedBarcodeFrame: $detectedBarcodeFrame,
                    isProcessingBarcode: $isProcessingBarcode,
                    onBarcodeFound: handleBarcodeFound
                )
                .edgesIgnoringSafeArea(.all)
            }

            // Fullscreen dim overlay with transparent cutout
            GeometryReader { geometry in
                Color.black.opacity(0.6)
                    .mask {
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .frame(width: 280, height: 180)
                                    .blendMode(.destinationOut)
                                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            )
                            .compositingGroup()
                    }
                    .ignoresSafeArea()
            }

            // Barcode highlight (if tracking while loading)
            if let frame = detectedBarcodeFrame {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appPrimary, lineWidth: 4)
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
                    .animation(.easeInOut, value: frame)
            }

            // Animated line (when idle)
            if isScanning && detectedBarcodeFrame == nil {
                ScannerLineAnimation()
                    .frame(width: 250, height: 2)
            }

            // Top instruction
            if isScanning && detectedBarcodeFrame == nil {
                VStack {
                    Text("Point camera at barcode")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 60)
                    Spacer()
                }
            }

            // Top buttons
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .opacity(0.8)
                    }
                    .padding()

                    Spacer()

                    Button(action: { isTorchOn.toggle() }) {
                        Image(systemName: isTorchOn ? "bolt.circle.fill" : "bolt.slash.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .opacity(0.8)
                    }
                    .padding()
                }
                Spacer()
            }

            // Loading view
            if isLoading {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
            }
        }
        .alert("Scan Error", isPresented: $showError) {
            Button("OK", action: resetScanner)
        } message: {
            Text(errorMessage)
        }
        .onChange(of: lastScannedCode) { newCode in
            if !newCode.isEmpty && !isProcessingBarcode {
                handleBarcodeFound(newCode)
            }
        }
    }

    private func handleBarcodeFound(_ code: String) {
        isProcessingBarcode = true
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
                    resetScanner()
                }
            }
        }
    }

    private func resetScanner() {
        isLoading = false
        isProcessingBarcode = false
        lastScannedCode = ""
        detectedBarcodeFrame = nil
        isScanning = true
    }

    private func lookupBarcode(_ upc: String) async throws -> [Collectible] {
        let request = BarcodeLookupRequest(upc: upc)
        return try await apiClient.get(
            path: .lookup,
            queryItems: [URLQueryItem(name: "upc", value: upc)]
        )
    }
}

// MARK: - Subviews

struct BarcodeScannerOverlay: View {
    var detectedFrame: CGRect?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let frame = detectedFrame {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                } else {
                    let centerFrameWidth: CGFloat = 300
                    let centerFrameHeight: CGFloat = 200
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: centerFrameWidth, height: centerFrameHeight)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
        .compositingGroup()
        .luminanceToAlpha()
    }
}

struct ScannerLineAnimation: View {
    @State private var yOffset: CGFloat = -100
    
    var body: some View {
        Rectangle()
            .fill(Color.appPrimary)
            .shadow(color: .appPrimary.opacity(0.8), radius: 5, x: 0, y: 0)
            .onAppear {
                withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: true)) {
                    yOffset = 100
                }
            }
            .offset(y: yOffset)
    }
}

// MARK: - View Controller

struct BarcodeScannerViewController: UIViewControllerRepresentable {
    @Binding var isScanning: Bool
    @Binding var lastScannedCode: String
    @Binding var isTorchOn: Bool
    @Binding var detectedBarcodeFrame: CGRect?
    @Binding var isProcessingBarcode: Bool
    let onBarcodeFound: (String) -> Void
    
    func makeUIViewController(context: Context) -> ScannerVC {
        let vc = ScannerVC()
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ScannerVC, context: Context) {
        uiViewController.toggleTorch(on: isTorchOn)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, ScannerVCDelegate {
        let parent: BarcodeScannerViewController
        
        init(parent: BarcodeScannerViewController) {
            self.parent = parent
        }
        
        func didFindBarcode(_ code: String) {
            guard !parent.isProcessingBarcode else { return }
            parent.lastScannedCode = code
            parent.onBarcodeFound(code)
        }
        
        func didDetectBarcodeFrame(_ frame: CGRect?) {
            parent.detectedBarcodeFrame = frame
        }
    }
}

protocol ScannerVCDelegate: AnyObject {
    func didFindBarcode(_ code: String)
    func didDetectBarcodeFrame(_ frame: CGRect?)
}

class ScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerVCDelegate?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var videoCaptureDevice: AVCaptureDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else { return }
        
        self.videoCaptureDevice = videoCaptureDevice
        captureSession.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(metadataOutput) else { return }
        
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    func toggleTorch(on: Bool) {
        guard let device = videoCaptureDevice, device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
            delegate?.didDetectBarcodeFrame(nil)
            return
        }
        
        let transformedObject = previewLayer.transformedMetadataObject(for: readableObject)
        delegate?.didDetectBarcodeFrame(transformedObject?.bounds)
        
        if let code = readableObject.stringValue {
            delegate?.didFindBarcode(code)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
}
