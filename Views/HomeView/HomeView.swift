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
    @StateObject private var viewModel = HomeViewModel()

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
                } else if let image = capturedImage {
                    if !analysisResult.isEmpty {
                        galleryView
                    } else {
                        photoPreviewView(image: image)
                    }
                } else if !analysisResult.isEmpty {
                    galleryView
                } else {
                    ZStack(alignment: .top) {
                        VStack(spacing: 16) { // Reduced from 20 to match spacing
                            // Centered Logo with adjusted padding
                            Image(colorScheme == .dark ? "logo-white" : "logo-dark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 44)
                                .padding(.top, 0) // Reduced top padding
//                                .padding(.horizontal, 40)
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
                            
                            // Dashboard View with reduced top padding
                            DashboardView(
                                totalBalance: viewModel.totalBalance,
                                rateOfReturn: viewModel.rateOfReturn,
                                lifetimeSpendings: viewModel.lifetimeSpendings,
                                lastMonthSpendings: viewModel.lastMonthSpendings
                            )
                            
                            // Main action cards with adjusted spacing
                            VStack(spacing: 16) { // Reduced from 24
                                // Add Items Section
                                VStack(spacing: 12) { // Reduced from 16
                                    Text("ADD NEW ITEMS")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 20)
                                    
                                    actionCard(
                                        systemImage: "camera.fill",
                                        title: "Scan New Item",
                                        description: "Take a photo of your collectible to add it to your collection",
                                        shortDescription: "Photo scan of your collectible",
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
                                        shortDescription: "Select from your photos",
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
                                        shortDescription: "Locate a barcode on the box",
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
                                        shortDescription: "Search by name/details",
                                        action: {
                                            hapticAction {
                                                addNewItemAction(.manually)
                                            }
                                        }
                                    )
                                }
                                .padding(.horizontal)
                                
                                // View Collection Section
                                VStack(spacing: 12) { // Reduced from 16
                                    Text("YOUR COLLECTION")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 20)
                                    
                                    actionCard(
                                        systemImage: "rectangle.stack.fill",
                                        title: "Go to My Collection",
                                        description: "Browse and manage your existing collectibles",
                                        shortDescription: "View & manage your items",
                                        action: {
                                            hapticAction(loadCollection)
                                        },
                                        isPrimary: true
                                    )
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }
                            
                            Spacer()
                        }
                        
                        HStack {
                            Spacer()
                            // Profile button aligned with logo
                            userProfileButton
                                .padding(.top, 16) // Matches logo's top padding
                                .padding(.trailing, 16)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .onAppear {
                viewModel.loadDashboardData()
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
    
    // Dashboard View
    struct DashboardView: View {
        let totalBalance: String
        let rateOfReturn: String
        let lifetimeSpendings: String
        let lastMonthSpendings: String
        
        @State private var showLifetimeSpendings = true
        @State private var showLifetimeSellings = true
        
        var body: some View {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    DashboardCard(
                        title: "Total Balance",
                        value: totalBalance,
                        valueColor: .primary,
                        isInteractive: false
                    )
                    
                    DashboardCard(
                        title: "Rate of Return",
                        value: rateOfReturn,
                        valueColor: rateOfReturn.contains("-") ? .red : .green,
                        isInteractive: false
                    )
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showLifetimeSpendings.toggle()
                        }
                    }) {
                        DashboardCard(
                            title: showLifetimeSpendings ? "Lifetime Spendings" : "Last Month",
                            value: showLifetimeSpendings ? lifetimeSpendings : lastMonthSpendings,
                            valueColor: .primary,
                            isInteractive: true,
                            isToggled: !showLifetimeSpendings
                        )
                    }
                    .buttonStyle(.plain)
                }
                
//                HStack(spacing: 12) {
//                    Button(action: {
//                        withAnimation(.easeInOut(duration: 0.2)) {
//                            showLifetimeSpendings.toggle()
//                        }
//                    }) {
//                        DashboardCard(
//                            title: showLifetimeSpendings ? "Lifetime Spendings" : "Last Month Spendings",
//                            value: "£3,300.93",
//                            valueColor: .primary,
//                            isInteractive: true,
//                            isToggled: !showLifetimeSpendings
//                        )
//                    }
//                    .buttonStyle(.plain)
//                    
//                    Button(action: {
//                        withAnimation(.easeInOut(duration: 0.2)) {
//                            showLifetimeSellings.toggle()
//                        }
//                    }) {
//                        DashboardCard(
//                            title: showLifetimeSellings ? "Lifetime Sellings" : "Last Month Sellings",
//                            value: "£1,200.50",
//                            valueColor: .primary,
//                            isInteractive: true,
//                            isToggled: !showLifetimeSellings
//                        )
//                    }
//                    .buttonStyle(.plain)
//                }
            }
            .padding(.horizontal)
            .frame(maxHeight: 160)
        }
    }
    
    struct DashboardCard: View {
        let title: String
        let value: String
        let valueColor: Color
        var isInteractive: Bool = false
        var isToggled: Bool = false
        
        var body: some View {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text(title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                    }
                    
                    Text(value)
                        .font(.headline)
                        .foregroundColor(valueColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .minimumScaleFactor(0.8)
                }
                
                if isInteractive {
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .rotationEffect(.degrees(isToggled ? 180 : 0))
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.2), value: isToggled)
                }
            }
            .padding(UIDevice.isiPhoneSE ? 12 : 16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isInteractive ? Color.appPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .scaleEffect(isToggled ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isToggled)
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
        shortDescription: String = "",
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text((UIDevice.isiPhoneSE && !shortDescription.isEmpty) ? shortDescription : description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(UIDevice.isiPhoneSE ? 1 : 0)
                        .fixedSize(horizontal: false, vertical: true) // Ensure proper sizing
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(UIDevice.isiPhoneSE ? 12 : 16)
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
        
        viewModel.loadDashboardData()
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
