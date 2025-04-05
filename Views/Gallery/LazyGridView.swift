//
//  ContentView.swift
//  FunkoCollector
//
//  Created by Pedro Rojas on 29/09/21.
//

import SwiftUI
import PhotosUI // Import PhotosUI for PHPickerViewController

struct LazyGridGalleryView: View {
    @Namespace private var animationNamespace // For matchedGeometryEffect
    @State private var selectedItem: Int? = nil {
        didSet {
            if selectedItem != oldValue {
                loadGalleryImages()
            }
        }
    } // Track the selected grid item
    @State private var isFullScreen: Bool = false // Track full-screen state
    
    @State private var selectedBackgroundImage: [UIImage]? = nil // Store the selected background image
    @State private var isShowingImagePicker: Bool = false // Control the image picker presentation
    @State private var showEllipsisMenu = false
    
    @State private var showAddToCollectionConfirmation = false
    // State property to manage gallery carousel
    @State private var currentImageIndex: Int = 0
    
    @State private var showCollectibleDeleteConfirmation = false
    @State private var showCollectibleUserPhotoDeleteConfirmation = false
    
    @State private var showAddMenu = false
    
    @State private var leadingNavigationButtonRect: CGRect = .zero
    @State private var animateLogo = false
    let initialLogoRect: CGRect?
    
    @State private var showNavigationTitle = false
    
    // Manual Entry View States
    @State private var showManualEntryView = false
    private enum Field: Hashable {
        case name, reference, series, barcode
    }
    @FocusState private var focusedField: Field?
    @State private var manualEntryName = ""
    @State private var manualEntryReference = ""
    @State private var manualEntrySeries = ""
    @State private var manualEntryBarcode = ""
    
    // Create an instance of the ViewModel
    @StateObject private var viewModel = LazyGridViewModel()
    
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    private static let size: CGFloat = 150
    private static let spacingBetweenColumns: CGFloat = 12
    private static let spacingBetweenRows: CGFloat = 12
    private static let totalColumns: Int = 4
    
    private var disablePlusButton: Bool {
        appState.openRelated || isFullScreen
    }
    
    private var backgroundView: some View {
        Group {
            let backgroundImage = selectedBackgroundImage?.first.map { Image(uiImage: $0) }
            ?? Image("background-image-1")
            
            backgroundImage
                .resizable()
                .scaledToFill()
                .frame(
                    width: UIScreen.main.bounds.width,
                    height: UIScreen.main.bounds.height
                )
                .clipped()
                .ignoresSafeArea()
        }
    }
    
    private var logoTopPadding: CGFloat {
        UIDevice.isiPhoneSE ? 6 : 40
    }
    
    private var informationFooter: some View {
        Group {
            if appState.showAddToCollectionButton && !isFullScreen && !payload.isEmpty {
                VStack(spacing: 8) {
                    Text("\(payload.count) items found")
                        .font(.headline.weight(.medium))
                    Text("Tap items to remove unwanted ones")
                        .font(.subheadline)
                    
                    Button(action: addToCollectionButtonTapped) {
                        Text("Add All to Collection")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appPrimary)
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    ZStack {
                        // Blur effect with vibrancy
                        VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                        
                        // Subtle dark overlay for better contrast
                        Color.black.opacity(0.2)
                    }
                        .cornerRadius(20)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 60) // Adjusted bottom padding
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var interactiveTutorial: some View {
        Group {
            if appState.showAddToCollectionButton && !payload.isEmpty && appState.showSearchResultsInteractiveTutorial {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .onTapGesture { appState.showSearchResultsInteractiveTutorial = false }
                    
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Image(systemName: "checklist")
                                .font(.largeTitle)
                            Text("Review Your Results")
                                .font(.title3.weight(.bold))
                            Text("Tap items to remove ones you don't want, then press 'Add All' to save the remaining items")
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                                .padding(.horizontal, 16)
                        }
                        .padding(16)
                        .foregroundColor(.white)
                        Button("Got It!") {
                            appState.showSearchResultsInteractiveTutorial = false
                        }
                        .buttonStyle(.automatic)
                        .font(.headline)
                        .tint(.appPrimary)
                        .padding(.bottom, 16)
                    }
                    .background(
                        ZStack {
                            // Blur effect with vibrancy
                            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                            
                            // Subtle dark overlay for better contrast
                            Color.black.opacity(0.2)
                        }
                            .cornerRadius(20)
                    )
                    .padding(60)
                }
                .zIndex(10)
            }
        }
    }
    
    @Binding var payload: [Collectible]
    
    var dismissAction: () -> Void
    
    var dismissActionWrapped: () -> Void {
        get {
            return {
                //                Helpers.hapticFeedback()
                if editCollectibleUserPhotos {
                    editCollectibleUserPhotos = false
                } else if isFullScreen {
                    withAnimation {
                        isFullScreen = false
                    }
                } else if selectedItem != nil {
                    withAnimation {
                        selectedItem = nil
                    }
                } else {
                    withAnimation {
                        showNavigationTitle = false
                        animateLogo = false
                        dismissAction()
                    }
                }
            }
        }
    }
    
    var seeMissingPopsAction: (Collectible) -> Void
    var addNewItemAction: (AddNewItemAction) -> Void
    
    var gridItems = Array(
        repeating: GridItem(
            .fixed(size),
            spacing: spacingBetweenColumns,
            alignment: .center
        ),
        count: totalColumns
    )
    
    private var isCurrentImageDefault: Bool {
        if let index = selectedItem, currentImageIndex < payload[index].gallery.count {
            return true
        } else {
            return false
        }
    }
    
    private func addNewItemTapped(_ action: AddNewItemAction) {
        /* TODO: BUTTON ROTATION ISSUE
         * Component: Add item button
         * Expected: 45° rotation on toggle
         * Current behavior: No visual rotation
         * Verified:
         * - State changes properly (showAddMenu)
         * - rotationEffect modifier exists
         * - Animation wrapper present
         * Investigation needed:
         * - Is view identity preserved?
         * - Any animation modifiers higher in hierarchy?
         * - Try explicit animation trigger
         */
        showAddMenu.toggle()
        selectedItem = nil
        isFullScreen = false
        withAnimation() {
            dismissAction()
            addNewItemAction(action)
        }
    }
    
    private func addItemButtonDropDownView() -> some View {
        Menu {
            Button(action: {
                addNewItemTapped(.barcode)
            }) {
                Label("Scan Barcode", systemImage: "barcode.viewfinder")
            }
            
            Button(action: {
                addNewItemTapped(.camera)
            }) {
                Label("Take a Photo", systemImage: "camera")
            }
            
            Button(action: {
                addNewItemTapped(.photoPicker)
            }) {
                Label("Add from Gallery", systemImage: "photo")
            }
            
            Button(action: {
                //                addNewItemTapped(.manually)
                showManualEntryView = true
            }) {
                Label("Add Manually", systemImage: "keyboard")
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 22))
                .rotationEffect(.degrees(showAddMenu ? 90 : 0))
                .foregroundColor(.black.opacity(0.8)) // Change color when disabled
                .background(disablePlusButton ? .gray.opacity(0.5) : .appPrimary) // Adjust background
                .clipShape(Circle())
                .opacity(disablePlusButton ? 0.7 : 1.0) // Reduce opacity when disabled
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .menuIndicator(.hidden)
        .disabled(appState.openRelated)
    }
    
    private func ellipsisButtonDropDownView() -> some View {
        Menu {
            Button(action: {
                showEllipsisMenu.toggle()
                if isFullScreen {
                    withAnimation {
                        isFullScreen = false
                    }
                }
                isShowingImagePicker = true
            }) {
                Label("Change Wallpaper", systemImage: "photo.fill.on.rectangle.fill")
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.system(size: 22))
                .rotationEffect(.degrees(showEllipsisMenu ? 90 : 0))
                .foregroundColor(.black).opacity(0.8)
                .background(.gray)
                .clipShape(Circle())
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .menuIndicator(.hidden)
        //        .padding(.trailing, 20)
        //        .background(Color.green.opacity(0.3))
        //        .sheet(isPresented: $isPresentingScanner) {
        //            BarcodeScannerView { items in
        //                payload.append(contentsOf: items)
        //            }
        //        }
    }
    
    private func addToCollection() {
        // Implement your Collection saving logic here
        print("Adding items to Collection: \(payload)")
        do {
            let itemIds = payload.map { $0.id }
            
            viewModel.manageCollection(itemIds: itemIds, method: .add) { result in
                if case .success = result {
                    viewModel.addToCollection(payload)
                    
                    dismissActionWrapped()
                    
                    appState.openMyCollection = true
                    appState.showPlusButton = true
                    appState.showEllipsisButton = true
                    appState.showCollectionButton = false
                    appState.showAddToCollectionButton = false
                }
            }
        } catch {
            //TODO: -
            print("Error saving to Collection:", error.localizedDescription)
        }
    }
    
    private func gridItemView(for index: Int, proxy: GeometryProxy) -> some View {
        ZStack {
            AsyncImageLoader(
                url: viewModel.getGridItemUrl(from: payload[index]),
                placeholder: Image(.gridItemPlaceholder),
                grayScale: !payload[index].inCollection
            )
            .scaledToFit()
            .cornerRadius(Self.size/8)
            .scaleEffect(scale(proxy: proxy, value: index))
            .offset(x: offsetX(index), y: 0)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedItem = index
                }
            }
            
            // MISSING label - matches xmark button position/size
            if !payload[index].inCollection {
                Text("MISSING")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                
                    .frame(width: .infinity, height: 24)
                    .background(.red)
                    .cornerRadius(12)
                    .offset(x: offsetX(index) + Self.size / 4 - 10, y: -Self.size / 2 + 10)
            }
            
            if selectedItem == index {
                if !payload[index].inCollection {
                    Button(action: {
                        ViewHelpers.hapticFeedback()
                        withAnimation(.spring()) {
                            selectedItem = index
                            isFullScreen = true
                        }
                    }) {
                        Text("Shop")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appPrimary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.5))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.appPrimary, lineWidth: 2)
                            )
                    }
                    .offset(x: offsetX(index), y: 0)
                } else {
                    Button(action: {
                        ViewHelpers.hapticFeedback()
                        withAnimation(.spring()) {
                            selectedItem = index
                            isFullScreen = true
                        }
                    }) {
                        Text("View")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(.green, lineWidth: 2)
                            )
                    }
                    .offset(x: offsetX(index), y: 0)
                }
                if payload[index].inCollection {
                    Button(action: {
                        showCollectibleDeleteConfirmation = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.black).opacity(0.8)
                            .background(.red)
                            .clipShape(Circle())
                    }
                    .frame(width: 44, height: 44) // Minimum tappable area
                    .contentShape(Circle()) // Makes entire circle tappable
                    .offset(x: offsetX(index) + Self.size / 2 - 10, y: -Self.size / 2 + 10)
                    .alert("Delete \(payload[index].attributes.name)?", isPresented: $showCollectibleDeleteConfirmation) {
                        Button("Delete", role: .destructive, action: confirmCollectibleDeletion)
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will permanently remove the item from your collection.")
                    }
                }
            }
        }
    }
    
    private func confirmCollectibleDeletion() {
        showCollectibleDeleteConfirmation = false
        if let index = selectedItem {
            let itemId = payload[index].id
            viewModel.manageCollection(itemIds: [itemId], method: .delete) { result in
                // NOTE: Errors are handled by the ViewModel before reaching the completion handler
                if case .success = result {
                    // Remove the item from the local repository
                    withAnimation(.easeOut(duration: 0.3)) {
                        viewModel.deleteItem(for: payload[index].id)
                        
                        payload.remove(at: index)
                        // Reset selection
                        selectedItem = nil
                    }
                }
            }
        }
    }
    
    private func confirmCollectibleUserPhotoDeletion() {
        showCollectibleDeleteConfirmation = false
        if let index = selectedItem {
            var itemToUpdate = payload[index]
            // NOTE: Combines standard gallery images with user-uploaded photos for the carousel. Only user-uploaded photos can be deleted.
            let indexToDelete = currentImageIndex - (itemToUpdate.gallery.count)
            itemToUpdate.customAttributes?.userPhotos?.remove(at: indexToDelete)
            viewModel.manageCollection(itemIds: [itemToUpdate.id], method: .update, collectible: itemToUpdate) { result in
                // NOTE: Errors are handled by the ViewModel before reaching the completion handler
                if case .success = result {
                    // Remove the item from the local repository
                    withAnimation(.easeOut(duration: 0.3)) {
                        viewModel.updateItem(itemToUpdate)
                        payload[index].customAttributes?.userPhotos?.remove(at: indexToDelete)
                    }
                }
            }
        }
    }
    
    // State for showing subject selection menu
    @State private var showSubjectMenu = false
    
    private func fullScreenView(for index: Int) -> some View {
        // Get the current item from payload
        let currentItem = payload[index]
        let galleryImages = viewModel.combinedGalleryImages(for: currentItem)
        
        // Carousel View
        let carouselView = ZStack {
            // Image Carousel with conditional offset
            TabView(selection: $currentImageIndex) {
                ForEach(Array(galleryImages.enumerated()), id: \.offset) { index, imageData in
                    GeometryReader { geometry in
                        AsyncImageLoader(
                            url: viewModel.imageURL(from: imageData),
                            placeholder: Image(.gridItemPlaceholder),
                            grayScale: false
                        )
                        // NOTE: For better visual feedback during swiping, consider adding this modifier:
//                        .animation(.interactiveSpring(), value: currentImageIndex)
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                        .tag(index)
                        .gesture(
                            TapGesture()
                                .onEnded {
                                    withAnimation(.spring()) {
                                        editCollectibleUserPhotos = false
                                        isFullScreen.toggle()
                                    }
                                }
                                .exclusively(before: DragGesture()
                                    .onEnded { gesture in
                                        if gesture.translation.height > 50 { // Swipe Down
                                            withAnimation(.spring()) {
                                                if !isFullScreen { // Hide Carousel Preview on Swipe Down
                                                    selectedItem = nil
                                                }
                                                editCollectibleUserPhotos = false
                                                isFullScreen = false // Collapse fullscreen Carousel on Swipe Down
                                            }
                                        } else if gesture.translation.height < -50 { // Swipe Up
                                            withAnimation(.spring()) {
                                                isFullScreen = true
                                            }
                                        }
                                    }
                                )
                        )
                    }
                    .padding(.horizontal, 4) // Adds spacing between cards
                }
            }
            .background(
                ZStack {
                    VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                        .opacity(isFullScreen ? 0 : 1)
                        .mask(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black, location: 0.4)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                    .edgesIgnoringSafeArea(.bottom)
            )
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: isFullScreen ? .always : .never))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            // Navigation Arrows
            if galleryImages.count > 1 {
                HStack {
                    Button(action: {
                        withAnimation {
                            currentImageIndex = (currentImageIndex - 1 + galleryImages.count) % galleryImages.count
                        }
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .opacity(0.8)
                            .background(.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            currentImageIndex = (currentImageIndex + 1) % galleryImages.count
                        }
                    }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .opacity(0.8)
                            .background(.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                }
                .offset(y: !isFullScreen ? 40 : 0)
            }
        }
            .frame(height: UIScreen.main.bounds.height*0.45)
            .matchedGeometryEffect(id: index, in: animationNamespace)
        
        // Details View
        return VStack(spacing: 20) {
            carouselView
            if isFullScreen {
                detailsView(currentItem)
            }
        }
        .transition(.opacity)
        .onAppear {
            currentImageIndex = 0
            isDetailsExpanded = false // Reset expansion state when view appears
        }
        .textFieldAlert(isPresented: $isInputFieldFocused, title: "PURCHASE PRICE", text: $editedPricePaid) {
            // Save the edited value when done
//            if title == "PURCHASE PRICE" {
            guard let newPrice = Float(editedPricePaid) else {
                return
            }
            
            viewModel.purchasePriceUpdated(newPrice, for: currentItem)
            payload[index].pricePaid = newPrice
//            }
        }
    }
    
    @State private var isDetailsExpanded = false
    private let collapsedRowCount = 3 // Number of rows to show when collapsed
    
    // Modify the detailsView to be expandable
    private func detailsView(_ currentItem: Collectible) -> some View {
        ZStack{
            // Details content
            ScrollView() {
                Group {
                    HeaderView("General Info")
                        .padding(.top, 16)
                    detailRow(title: "ITEM:", value: currentItem.attributes.name)
                    detailRow(title: "VALUE:", value: currentItem.estimatedValue ?? "-")
                    detailRow(title: "RELEASE:", value: currentItem.attributes.dateFrom ?? "-")
                    detailRow(
                        title: "STATUS:",
                        value: {
                            let statusText = currentItem.attributes.productionStatus?
                                .joined(separator: ", ")
                                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                            
                            return !statusText.isEmpty ? statusText : "-"
                        }()
                    )
                    
                    detailRow(title: "REF #:", value: currentItem.attributes.refNumber ?? "-")
                    
                    let series = !currentItem.subject.isEmpty ? currentItem.subject : "-"
                    detailRow(title: "SERIES:", value: series)
                    
                    HeaderView("Acquisition Details")
                        .padding(.top, 8)
                    
                    detailRow(
                        title: "PURCHASE PRICE:",
                        value: {
                            var price = ""
                            if let intPrice = currentItem.customAttributes?.pricePaid {
                                price = String(intPrice)
                            }
                            
                            return price
                    }(),
                              style: .input)
                    
                    detailRow(
                        title: "CUSTOM PHOTOS:",
                        value: {
                            if let count = currentItem.customAttributes?.userPhotos?.count, count > 0 {
                                return "\(count) Photos"
                            } else {
                                return ""
                            }
                        }(),
                        style: .media)
                }
                //                .padding(.top, 8)
                .padding(.bottom, 90)
            }
            //            .padding(.horizontal, 20)
            //            .padding(.bottom, 16)
            
            
            if !appState.showAddToCollectionButton && !appState.openRelated {
                VStack {
                    Spacer()
                    viewRelatedButton(currentItem)
                        .padding(.bottom, 20)
                }
            }
            
            // Add expand/collapse button in the top corner
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isDetailsExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isDetailsExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                        //                            .padding(8)
                            .opacity(0.8)
                            .background(.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                Spacer()
            }
        }
        .background(
            ZStack {
                // Blur effect with vibrancy
                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                
                // Subtle dark overlay for better contrast
                Color.black.opacity(0.2)
            }
                .cornerRadius(20)
        )
        .cornerRadius(20)
        .padding(.bottom, 60)
        .padding(.horizontal, 20)
        .frame(maxHeight: isDetailsExpanded ? .infinity : UIScreen.main.bounds.height*0.4) // Adjust height based on state
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDetailsExpanded)
    }
    
    // Separator
    private func HeaderView(_ title: String) -> some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.appPrimary.opacity(0.3))
                .layoutPriority(1) // Important for proper shrinking
            
            Text(title)
                .font(.body)
                .foregroundColor(.appPrimary)
                .fixedSize() // Prevent text wrapping
                .lineLimit(1) // Ensure single line
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.appPrimary.opacity(0.3))
                .layoutPriority(1) // Important for proper shrinking
        }
        .padding(.horizontal, 20)
    }
    
    struct VisualEffectView: UIViewRepresentable {
        var effect: UIVisualEffect?
        
        func makeUIView(context: Context) -> UIVisualEffectView {
            UIVisualEffectView(effect: effect)
        }
        
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
            uiView.effect = effect
        }
    }
    
    // DetailsView - DetailsRow - Price Paid states
    @State private var editedPricePaid: String = ""
    @State private var isInputFieldFocused: Bool = false
    
    // DetailsView - DetailsRow - User Photo Selection states
    @State private var chooseCollectibleUserPhotos: Bool = false
    @State private var selectedCollectibleUserPhotos: [UIImage]?
    @State private var editCollectibleUserPhotos: Bool = false
    
    private func detailRow(title: String, value: String, style: DetailRowStyle = .regular) -> some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            switch style {
            case .regular:
                Text(value)
                    .font(.body)
                    .foregroundColor(.secondary)
                
            case .input:
                Button(action: {
                    withAnimation {
                        editedPricePaid = value
                        isInputFieldFocused = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(value.isEmpty ? "-" : "\(Locale.current.currency?.identifier ?? "") \(value)")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Text(!value.isEmpty ? "Edit" : "Set")
                            .font(.body)
                            .foregroundColor(.appPrimary)
                    }
                }
                
            case .media:
                Button(action: {
                    withAnimation {
                        chooseCollectibleUserPhotos = true
                    }
                }) {
                    if value.isEmpty {
                        Text("Add Your Photos")
                            .font(.body)
                            .foregroundColor(.appPrimary)
                    } else {
                        HStack(spacing: 8) {
                            Text(value)
                                .font(.body)
                                .foregroundColor(.secondary)
                            Text("Add")
                                .font(.body)
                                .foregroundColor(.appPrimary)
                        }
                    }
                }
                
                if !value.isEmpty {
                    Button(action: {
                        editCollectibleUserPhotos = true
                    }) {
                        Text("Edit")
                            .font(.body)
                            .foregroundColor(.appPrimary)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
    
    private func viewRelatedButton(_ currentItem: Collectible) -> some View {
        Group {
            let relatedSubjects = (currentItem.attributes.relatedSubjects ?? [])
                .filter {
                    $0.name?.isEmpty == false &&
                    $0.type != .userSelectionPrimary
                }
            
            if currentItem.subject.isEmpty {
                // Menu version when subject is empty
                Menu {
                    Section {
                        ForEach(relatedSubjects, id: \.name) { subject in
                            Button(action: {
                                handleSubjectSelection(subject, for: currentItem)
                            }) {
                                Label(subject.name ?? "Untitled", systemImage: "magnifyingglass")
                            }
                        }
                    } header: {
                        Text("Choose a Category")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                } label: {
                    menuButtonLabel
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .menuIndicator(.hidden)
            } else {
                // Regular button when subject exists
                Button(action: {
                    seeMissingPopsAction(currentItem)
                }) {
                    menuButtonLabel
                }
            }
        }
    }
    
    // Extracted button label for consistency
    private var menuButtonLabel: some View {
        Text("See More in This Series")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.appPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.appPrimary, lineWidth: 2)
            )
    }
    
    // Extracted subject selection logic
    private func handleSubjectSelection(_ subject: RelatedSubject, for currentItem: Collectible) {
        guard let index = payload.firstIndex(where: { $0.id == currentItem.id }) else { return }
        
        var itemToUpdate = currentItem
        
        if let existingIndex = itemToUpdate.attributes.relatedSubjects?
            .firstIndex(where: { $0.type == .userSelectionPrimary }) {
            // Update existing
            itemToUpdate.attributes.relatedSubjects?[existingIndex].name = subject.name
            itemToUpdate.attributes.relatedSubjects?[existingIndex].url = subject.url
        } else {
            // Add new
            let newSubject = RelatedSubject(
                url: subject.url,
                name: subject.name,
                type: .userSelectionPrimary
            )
            itemToUpdate.attributes.relatedSubjects?.append(newSubject)
        }
        
        viewModel.updateItem(itemToUpdate)
        
        payload[index] = itemToUpdate
        seeMissingPopsAction(itemToUpdate)
    }
    
    var body: some View {
        ZStack {
            backgroundView
            interactiveTutorial
            // Animated logo transition
            if !appState.openRelated {
                // TODO: Negative frame coordinates detected in leadingNavigationButtonRect
                // when navigating to LazyGridView after "Add All" action.
                // Symptom: Logo animation moves off-screen during transition
                // Potential causes:
                // - Safe area insets not accounted for
                // - Navigation occurs before frame calculation completes
                // - Coordinate space mismatch (global vs local)
                // Temporary workaround: position hardcoded
                Image("logo-white")
                    .resizable()
                    .background(content: {
                        //                        Color.gray
                    })
                    .aspectRatio(contentMode: .fit)
                    .frame(height: animateLogo ? 30 : initialLogoRect?.height ?? 200)
                    .position(
                        x: animateLogo ? UIScreen.main.bounds.midX : initialLogoRect?.midX ?? 0,
                        // TODO: Replace hardcoded Y-position offset with dynamic layout calculation
                        // Issue: Using topBarLogoRect.midY - 40 is fragile
                        // Solution: Use alignment guides or proper view hierarchy for positioning
                        //                        y: animateLogo ? leadingNavigationButtonRect.midY - 40 : (initialLogoRect?.midY ?? 0) - 40
                        y: animateLogo ? logoTopPadding : (initialLogoRect?.midY ?? 0) - logoTopPadding
                    )
            }
            
            if viewModel.showLoadingIndicator {
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .zIndex(3) // Show above other content
            }
            
            if !isFullScreen {
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    LazyVGrid(
                        columns: gridItems,
                        alignment: .center,
                        spacing: Self.spacingBetweenRows
                    ) {
                        ForEach(payload.indices, id: \.self) { index in
                            GeometryReader { proxy in
                                gridItemView(for: index, proxy: proxy)
                            }
                            .frame(height: Self.size)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity).combined(with: .move(edge: .trailing))
                            ))
                        }
                    }
                    .padding(.trailing, Self.size/2 + 20) // Add proper padding
                    .padding(.top, Self.size/2 + 20)
                    .padding(.bottom, Self.size/2)
                    .padding(.leading, 20)
                }
                .contentShape(Rectangle()) // Make entire scroll view tappable
                .gesture(
                    TapGesture()
                        .onEnded {
                            if !isFullScreen {
                                withAnimation(.spring()) {
                                    selectedItem = nil
                                }
                            }
                        }
                )
                .sheet(isPresented: $isShowingImagePicker) {
                    ImagePicker(selectedImages: $selectedBackgroundImage, selectionLimit: 1)
                }
            }
            
            if let selectedItem = selectedItem {
                fullScreenView(for: selectedItem)
                    .offset(y: !isFullScreen ? UIScreen.main.bounds.height*0.45 : 0)  // Half of 300 to maintain visual balance
                    .sheet(isPresented: $chooseCollectibleUserPhotos) {
                        ImagePicker(selectedImages: $selectedCollectibleUserPhotos, selectionLimit: 5)
                    }
                    .onChange(of: selectedCollectibleUserPhotos) {
                        // Map each UIImage to PNG data with compression
                        let imageDataArray = selectedCollectibleUserPhotos?.compactMap {
                            $0.jpegData(compressionQuality: 0.8)
                        }
                        
                        if let dataArray = imageDataArray {
                            viewModel.uploadCollectibleUserPhotos(
                                collectibleId: payload[selectedItem].id,
                                photos: dataArray) { updatedItem in
                                    payload[selectedItem] = updatedItem
                                }
                        }
                    }
                // Success Checkmark Overlay
                if viewModel.showSuccessCheckmark {
                    SuccessCheckmarkView()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                withAnimation {
                                    viewModel.showSuccessCheckmark = false
                                    dismiss()
                                }
                            }
                        }
                }
            } else {
                VStack {
                    Spacer()
                    informationFooter
                }
            }
            
            manualEntryView
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { leadingNavigationButton }
            ToolbarItem(placement: .navigationBarTrailing) { trailingNavigationButtons }
            ToolbarItem(placement: .principal) {
                Text(navigationTitle)
                    .font(.system(size: 16, weight: .bold)) // Semi-bold, size 16
                    .foregroundColor(.appPrimary) // Your hex color
                //                    .textCase(.uppercase) // Uppercase text
                    .kerning(0.5) // Slight letter spacing for better readability
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)  // Hides the back button
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if appState.openRelated {
                showNavigationTitle = true
                loadRelatedItems()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Toolbar Components
    
    private var navigationTitle: String {
        showNavigationTitle ? (payload.first?.subject ?? "") : ""
    }
    
    private var backNavigationItemIcon: String {
        appState.openRelated || appState.showAddToCollectionButton || isFullScreen || selectedItem != nil
        ? "chevron.left.circle.fill"
        : "house.circle.fill"
    }
    
    private var leadingNavigationButton: some View {
        Group {
            if appState.showBackButton {
                Button(action: dismissActionWrapped) {
                    if editCollectibleUserPhotos {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.appPrimary)
                    } else {
                        // System icon version
                        Image(systemName: backNavigationItemIcon)
                            .font(.system(size: 22))
                            .foregroundColor(.black).opacity(0.8)
                            .background(Color.appPrimary)
                            .clipShape(Circle())
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Circle())
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        leadingNavigationButtonRect = geo.frame(in: .global)
                        if initialLogoRect != nil {
                            withAnimation(.bouncy(duration: 0.5)){
                                animateLogo = true
                            }
                        }
                    }
            }
        )
    }
    
    private func editCollectibleUserPhotosNavigationItem() -> some View {
        Button(action: {
            showCollectibleUserPhotoDeleteConfirmation = true
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.black).opacity(0.8)
                .background(.red)
                .clipShape(Circle())
        }
        .frame(width: 44, height: 44) // Minimum tappable area
        .contentShape(Circle()) // Makes entire circle tappable
        .alert("Delete Collectible Photo?", isPresented: $showCollectibleUserPhotoDeleteConfirmation) {
            Button("Delete", role: .destructive, action: confirmCollectibleUserPhotoDeletion)
            Button("Keep", role: .cancel) {}
        } message: {
            Text("Photo will be permanently deleted from your collectible's gallery.")
        }
    }
    
    private var trailingNavigationButtons: some View {
        HStack(spacing: 12) {
            if appState.showAddToCollectionButton {
                addToCollectionButton
            }
            
            if appState.showPlusButton {
                addItemButtonDropDownView()
            }
            
            if editCollectibleUserPhotos && !isCurrentImageDefault {
                editCollectibleUserPhotosNavigationItem()
            } else if appState.showEllipsisButton {
                ellipsisButtonDropDownView()
            }
            
            if appState.showCollectionButton {
                myCollectionButton
            }
        }
    }
    
    private var manualEntryView: some View {
        Group {
            if showManualEntryView {
                ZStack {
                    // Background dimming
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .onTapGesture { showManualEntryView = false }
                    
                    // Content card
                    VStack(spacing: 20) {
                        // Header with close button
                        HStack {
                            Text("Add New Item")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button {
                                showManualEntryView = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Form fields
                        VStack(spacing: 16) {
                            TextField("Name", text: $manualEntryName)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.next)
                                .focused($focusedField, equals: .name)
                            
                            TextField("Reference #", text: $manualEntryReference)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.next)
                                .focused($focusedField, equals: .reference)
                                .keyboardType(.numberPad)
                            
                            TextField("Series", text: $manualEntrySeries)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.next)
                                .focused($focusedField, equals: .series)
                            
                            TextField("Barcode (UPC)", text: $manualEntryBarcode)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.done)
                                .focused($focusedField, equals: .barcode)
                                .keyboardType(.numberPad)
                        }
                        .padding(.horizontal, 20)
                        
                        // Action buttons
                        HStack(spacing: 20) {
                            Button("Cancel") {
                                showManualEntryView = false
                            }
                            .buttonStyle(.bordered)
                            .tint(.gray)
                            
                            Button("Search") {
                                // Handle search action
                                //TODO: -
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.appPrimary)
                            .disabled(manualEntryName.isEmpty)
                        }
                        .padding(.bottom, 20)
                    }
                    .background(
                        ZStack {
                            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                            Color.black.opacity(0.2)
                        }
                            .cornerRadius(20)
                    )
                    .frame(width: 320)
                    .onAppear {
                        // Auto-focus first field when appears
                        focusedField = .name
                    }
                }
                .zIndex(10)
            }
        }
    }
    
    // MARK: - Button Components
    
    private var addToCollectionButton: some View {
        Button(action: addToCollectionButtonTapped) {
            HStack(spacing: 4) {
                Text("Add All")
                    .font(.system(size: 14, weight: .medium))
                Text("(\(payload.count))")
                    .font(.system(size: 12, weight: .bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.black.opacity(0.5))
                    .shadow(radius: 2)
            )
            .foregroundColor(.appPrimary)
            .overlay(
                Capsule()
                    .stroke(Color.appPrimary, lineWidth: 2)
            )
        }
        .alert("Add \(payload.count) items to your collection?", isPresented: $showAddToCollectionConfirmation) {
            Button("Add All", action: addToCollection)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Only remaining items will be added. Remove any you don't want first.")
        }
    }
    
    private var myCollectionButton: some View {
        Button(action: {
            appState.openMyCollection = true
            appState.showCollectionButton = false
            appState.showAddToCollectionButton = false
            dismissAction()
        }) {
            Text("My Collection")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.black.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.appPrimary, lineWidth: 1.5)
                        )
                )
                .shadow(radius: 2)
        }
    }
    
    private func addToCollectionButtonTapped() {
        // Check if user is logged in
        if KeychainHelper.hasValidJWTToken {
            // Existing collection saving logic
            showAddToCollectionConfirmation = true
        } else {
            appState.showAuthView = true
        }
    }
    
    private func loadGalleryImages() {
        guard let selectedIndex = selectedItem,
              selectedIndex < payload.count else {
            print("No valid item selected")
            return
        }
        
        if !payload[selectedIndex].gallery.isEmpty {
            return
        }
        
        let currentItemId = payload[selectedIndex].id
        
        viewModel.getGalleryImages(for: currentItemId) { result in
            DispatchQueue.main.async {
                // Safety check 1: Verify selected index still exists
                guard selectedIndex < payload.count else {
                    print("Item index out of bounds after async return")
                    return
                }
                
                // Safety check 2: Verify same item still exists at this index
                guard payload[selectedIndex].id == currentItemId else {
                    print("Item at index \(selectedIndex) was replaced")
                    return
                }
                
                switch result {
                case .success(let images):
                    // Final safety check before modification
                    if selectedIndex < payload.count &&
                        payload[selectedIndex].id == currentItemId {
                        
                        do {
                            try viewModel.updateGallery(by: currentItemId, galleryImages: images)
                            
                            payload[selectedIndex].attributes.images.gallery = images
                            print("Successfully updated gallery for item: \(payload[selectedIndex].attributes.name)")
                        } catch {
                            print("Failed to update database: \(error.localizedDescription)")
                        }
                    }
                    
                case .failure(let error):
                    print("Failed to load details: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadRelatedItems() {
        guard !payload.isEmpty else { return }
        
        viewModel.getRelated(for: payload[0].id) { items in
            DispatchQueue.main.async {
                // Process new items with inCollection flag
                let myCollection = viewModel.loadMyCollection()
                
                let newItems = items.compactMap { newItem -> Collectible? in
                    // Skip duplicates
                    guard !payload.contains(where: { $0.id == newItem.id }) else {
                        return nil
                    }
                    
                    // Check if item exists in collection
                    let inCollection = myCollection.contains { $0.id == newItem.id }
                    
                    // Return modified item
                    var modifiedItem = newItem
                    modifiedItem.inCollection = inCollection
                    return modifiedItem
                }
                
                // Add to payload with animation
                if !newItems.isEmpty {
                    withAnimation(.easeInOut) {
                        payload.append(contentsOf: newItems)
                    }
                    print("Added \(newItems.count) new related items")
                }
            }
        }
    }
    
    func offsetX(_ value: Int) -> CGFloat {
        let rowNumber = value / gridItems.count
        
        if rowNumber % 2 == 0 {
            return Self.size/2 + Self.spacingBetweenColumns/2
        }
        
        return 0
    }
    
    func appName(_ value: Int) -> String {
        apps[value%apps.count]
    }
    
    var center: CGPoint {
        CGPoint(
            x: UIScreen.main.bounds.size.width*0.5,
            y: UIScreen.main.bounds.size.height*0.5
        )
    }
    
    // This was my hardcoded approach... really bad for the future!
    //    var deviceCornerAngle: CGFloat {
    //        if UIDevice.current.userInterfaceIdiom == .pad {
    //            return (UIDevice.current.orientation == .portrait) ? 55 : 35
    //        } else {
    //            return (UIDevice.current.orientation == .portrait) ? 65 : 25
    //        }
    //    }
    
    func scale(proxy: GeometryProxy, value: Int) -> CGFloat {
        let rowNumber = value / gridItems.count
        
        // We need to consider the offset for even rows!
        let x = (rowNumber % 2 == 0)
        ? proxy.frame(in: .global).midX + proxy.size.width/2
        : proxy.frame(in: .global).midX
        
        let y = proxy.frame(in: .global).midY
        let maxDistanceToCenter = getDistanceFromEdgeToCenter(x: x, y: y)
        
        let currentPoint = CGPoint(x: x, y: y)
        let distanceFromCurrentPointToCenter = distanceBetweenPoints(p1: center, p2: currentPoint)
        
        // This creates a threshold for not just the pure center could get
        // the max scaleValue.
        let distanceDelta = min(
            abs(distanceFromCurrentPointToCenter - maxDistanceToCenter),
            maxDistanceToCenter*0.3
        )
        
        // Helps to get closer to scale 1.0 after the threshold.
        let scalingFactor = 3.3
        let scaleValue = distanceDelta/(maxDistanceToCenter) * scalingFactor
        
        return scaleValue
    }
    
    func getDistanceFromEdgeToCenter(x: CGFloat, y: CGFloat) -> CGFloat {
        let m = slope(p1: CGPoint(x: x, y: y), p2: center)
        let currentAngle = angle(slope: m)
        
        let edgeSlope = slope(p1: .zero, p2: center)
        let deviceCornerAngle = angle(slope: edgeSlope)
        
        if currentAngle > deviceCornerAngle {
            let yEdge = (y > center.y) ? center.y*2 : 0
            let xEdge = (yEdge - y)/m + x
            let edgePoint = CGPoint(x: xEdge, y: yEdge)
            
            return distanceBetweenPoints(p1: center, p2: edgePoint)
        } else {
            let xEdge = (x > center.x) ? center.x*2 : 0
            let yEdge = m * (xEdge - x) + y
            let edgePoint = CGPoint(x: xEdge, y: yEdge)
            
            return distanceBetweenPoints(p1: center, p2: edgePoint)
        }
    }
    
    func distanceBetweenPoints(p1: CGPoint, p2: CGPoint) -> CGFloat {
        let xDistance = abs(p2.x - p1.x)
        let yDistance = abs(p2.y - p1.y)
        
        return CGFloat(
            sqrt(
                pow(xDistance, 2) + pow(yDistance, 2)
            )
        )
    }
    
    func slope(p1: CGPoint, p2: CGPoint) -> CGFloat {
        return (p2.y - p1.y)/(p2.x - p1.x)
    }
    
    func angle(slope: CGFloat) -> CGFloat {
        return abs(atan(slope) * 180 / .pi)
    }
}

struct Axes: View {
    var body: some View {
        
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: geometry.frame(in: .global).maxX, y: geometry.frame(in: .global).midY))
                path.addLine(to: CGPoint(x: 0, y: geometry.frame(in: .global).midY))
                path.move(to: CGPoint(x: geometry.frame(in: .global).midX, y: geometry.frame(in: .global).midY))
                path.addLine(to: CGPoint(x: geometry.frame(in: .global).midX, y: geometry.frame(in: .global).maxY))
                
                path.addLine(to: CGPoint(x: geometry.frame(in: .global).midX, y: geometry.frame(in: .global).minY - 60))
            }
            .stroke(.blue, lineWidth: 3)
        }
    }
}

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

// Custom View Modifier for Conditional Scaling
extension View {
    @ViewBuilder
    func applyConditionalScaling(isScaledToFit: Bool) -> some View {
        if isScaledToFit {
            self.scaledToFit() // Apply .scaledToFit() if condition is true
        } else {
            self.scaledToFill() // Apply .scaledToFill() if condition is false
        }
    }
}
