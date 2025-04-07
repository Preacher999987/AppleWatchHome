import SwiftUI
import UIKit

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
struct HomeView: View {
    @State private var capturedImage: UIImage?
    @State private var analysisResult: [Collectible] = []
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showBarcodeReader = false
    @State private var showManualEntryView = false
    @State private var navigationPath = NavigationPath()
    
    @State private var logoRect: CGRect = .zero
    
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    private func addNewItemAction (_ action: AddNewItemAction) {
        switch action {
        case .barcode:
            showBarcodeReader = true
        case .camera:
            showCamera = true
        case .photoPicker:
            showPhotoPicker = true
        case .manually:
            showManualEntryView = true
        }
    }
    
    func hapticAction(_ action: () -> Void) -> Void {
        ViewHelpers.hapticFeedback()
        action()
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background layer
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Main content
                if appState.openMyCollection {
                    collectionView
                } else if let image = capturedImage { // <-- Camera/Gallery image selected
                    if !analysisResult.isEmpty {
                        galleryView // <-- Camera/Gallery image analysis succeeded, show in Gallery Grid View
                    } else {
                        photoPreviewView(image: image) // <-- Send image at PreviewView
                    }
                } else if !analysisResult.isEmpty { // <-- Barcode Reader succeeded
                    galleryView
                } else {
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 20) {
                            
                            // Logo header
                            Image(colorScheme == .dark ? "logo-white" : "logo-dark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 60)
                                .padding(.top, 40)
                                .padding(.horizontal, 60)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .onAppear {
                                                logoRect = geo.frame(in: .global)
                                            }
                                            .onChange(of: geo.frame(in: .global)) { newRect in
                                                logoRect = newRect
                                            }
                                    }
                                )
                            
                            // Main action cards
                            VStack(spacing: 24) {
                                // Add Items Section
                                VStack(spacing: 16) {
                                    Text("ADD NEW ITEMS")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 20)
                                    
                                    actionCard(
                                        systemImage: "camera.fill",
                                        title: "Scan New Item",
                                        description: "Take a photo of your collectible to add it to your collection",
                                        action: {
                                            hapticAction {
                                                addNewItemAction(.camera)
                                            }
                                        }
                                    )
                                    .overlay(alignment: .topTrailing) {
                                        AIPoweredBadge()
                                            .offset(x: -8, y: -8)
                                    }
                                    
                                    actionCard(
                                        systemImage: "photo.on.rectangle",
                                        title: "Add From Gallery",
                                        description: "Select an existing photo of your collectible",
                                        action: {
                                            hapticAction {
                                                addNewItemAction(.photoPicker)
                                            }
                                        }
                                    )
                                    .overlay(alignment: .topTrailing) {
                                        AIPoweredBadge()
                                            .offset(x: -8, y: -8)
                                    }
                                    
                                    actionCard(
                                        systemImage: "barcode.viewfinder",
                                        title: "Scan Barcode",
                                        description: "Add items by scanning the barcode on your collectible box",
                                        action: {
                                            hapticAction {
                                                addNewItemAction(.barcode)
                                            }
                                        }
                                    )
                                    
                                    actionCard(
                                            systemImage: "magnifyingglass",
                                            title: "Lookup by Name",
                                            description: "Search for collectibles by name or description",
                                            action: {
                                                hapticAction {
                                                    addNewItemAction(.manually)
                                                }
                                            }
                                        )
                                }
                                .padding(.horizontal)
                                
                                // View Collection Section
                                VStack(spacing: 16) {
                                    Text("YOUR COLLECTION")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 20)
                                    
                                    actionCard(
                                        systemImage: "rectangle.stack.fill",
                                        title: "Go to My Collection",
                                        description: "Browse and manage your existing collectibles",
                                        action: {
                                            hapticAction(loadCollection)
                                        },
                                        isPrimary: true
                                    )
                                }
                                .padding(.horizontal)
                            }
                            
                            Spacer()
                        }
                        
                        userProfileButton
                            .padding(.trailing, 14)
                            .padding(.top, 10)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    handleNewImage(image)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker { image in
                    handleNewImage(image)
                }
            }
            .sheet(isPresented: $showBarcodeReader) {
                BarcodeScannerView { items in
                    appState.showAddToCollectionButton = true
                    analysisResult = items
                }
            }
            .sheet(isPresented: $showManualEntryView) {
                ManualEntryView(isPresented: $showManualEntryView) { itemData in
                    appState.showAddToCollectionButton = true
                    analysisResult = itemData
                }
                .presentationBackground(.clear)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var collectionView: some View {
        GridGalleryView(
            initialLogoRect: logoRect,
            payload: $analysisResult,
            dismissAction: resetToInitialState,
            seeMissingPopsAction: { selectedItem in
                appState.openRelated = true
                navigationPath.append([selectedItem])
            },
            addNewItemAction: addNewItemAction
        )
        .navigationDestination(for: [Collectible].self) { newPayload in
            PayloadWrapperView(initialPayload: newPayload) {
                GridGalleryView(
                    initialLogoRect: logoRect,
                    payload: $0,
                    dismissAction: {
                        appState.openRelated = false
                        navigationPath.removeLast()
                    },
                    seeMissingPopsAction: { _ in },
                    addNewItemAction: addNewItemAction
                )
            }
        }
    }
    
    private var galleryView: some View {
        GridGalleryView(
            initialLogoRect: logoRect,
            payload: $analysisResult,
            dismissAction: resetToInitialState,
            seeMissingPopsAction: { _ in },
            addNewItemAction: { _ in }
        )
        .sheet(isPresented: $appState.showAuthView) {
            AuthView()
                .environmentObject(appState)
        }
    }
    
    private var userProfileButton: some View {
        Group {
            if let profile = try? UserProfileRepository.getCurrentUserProfile() {
                Button(action: {
                    withAnimation {
                        appState.showProfileInfo.toggle()
                    }
                }) {
                    if let image = profile.profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.appPrimary, lineWidth: 2)
                            )
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.appPrimary)
                            .overlay(
                                Circle()
                                    .stroke(Color.appPrimary, lineWidth: 2)
                            )
                    }
                }
                .sheet(isPresented: $appState.showProfileInfo) {
                    ProfileInfoView() {
                        KeychainHelper.logout()
                        resetToInitialState()
                    }
                }
            } else {
                Button(action: {
                    appState.showAuthView = true
                }) {
                    Text("Sign In")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.appPrimary)
                }
            }
        }
    }
    
    private func photoPreviewView(image: UIImage) -> some View {
        PhotoPreviewView(
            image: image,
            retakeAction: { capturedImage = nil },
            onAnalysisComplete: { result in
                analysisResult = result
            }
        )
    }
    
    private func actionCard(
        systemImage: String,
        title: String,
        description: String,
        action: @escaping () -> Void,
        isPrimary: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.title)
                    .foregroundColor(.appPrimary)
                    .frame(width: 44, height: 44)
                    .background(.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                isPrimary ? .appPrimary.opacity(0.2) : Color(.secondarySystemGroupedBackground)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Actions
    
    private func loadCollection() {
        guard KeychainHelper.hasValidJWTToken else {
            appState.showAuthView = true
            return
        }
        
        withAnimation(.easeOut) {
            showCollectionView()
        }
    }
    
    private func handleNewImage(_ image: UIImage) {
        appState.showAddToCollectionButton = true
        capturedImage = image
        analysisResult = []
    }
    
    private func resetToInitialState() {
        capturedImage = nil
        analysisResult = []
        showCamera = false
        showPhotoPicker = false
        showBarcodeReader = false
        appState.showPlusButton = false
        appState.showEllipsisButton = false
        appState.openMyCollection = false
        appState.showAddToCollectionButton = false
        // Show HomeView as Root View
        appState.showHomeView = true
    }
    
    private func showCollectionView() {
        if let result = try? CollectiblesRepository.loadItems() {
            analysisResult = result
        }
        appState.openMyCollection = true
        appState.showPlusButton = true
        appState.showEllipsisButton = true
        appState.showCollectionButton = false
        appState.showAddToCollectionButton = false
    }
}
