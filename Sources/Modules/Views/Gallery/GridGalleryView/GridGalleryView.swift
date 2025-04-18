//
//  ContentView.swift
//  FunkoCollector
//
//  Created by Pedro Rojas on 29/09/21.
//

import SwiftUI

struct GridGalleryView: View {    
    @Namespace private var animationNamespace // For matchedGeometryEffect
    @State private var selectedItem: Int? // Track the selected grid item
    @State private var isFullScreen: Bool = false { // Track full-screen state
        didSet {
            resetInputViewState()
        }
    }
    
    @State private var selectedBackgroundImage: [UIImage]? = nil // Store the selected background image
    @State private var isShowingImagePicker: Bool = false // Control the image picker presentation
    @State private var showEllipsisMenu = false
    
    @State private var showAddToCollectionConfirmation = false
    // State property to manage gallery carousel
    @State private var currentImageIndex: Int = 0
    
    @State private var showCollectibleUserPhotoDeleteConfirmation = false
    
    @State private var showAddMenu = false
    
    @State private var leadingNavigationButtonRect: CGRect = .zero
    @State private var animateLogo = false
    let initialLogoRect: CGRect?
    
    @State private var showNavigationTitle = false
    
    // Modal Safari browser view
    @State private var showSafariView = false
    
    // Search results selection mode
    @State private var searchResultsSelectionModeOn = false
    
    @State var isHoneycombGridViewLayoutActive: Bool = false
    
    //DetailsView - DetailsRow - TextField State
    @FocusState private var showKeyboard: Bool
    @State private var keyboardType: UIKeyboardType = .default
    @State private var isTextFieldPresented = false
    @State private var textFieldTextInput = ""
    @State private var onTextFieldSaveAction = {}
    @State private var onDateSelected: (Date) -> Void = {_ in}
    @State private var textFieldTitle = ""
    
    // DetailsView - DetailsRow - User Photo Selection states
    @State private var chooseCollectibleUserPhotos: Bool = false
    @State private var selectedCollectibleUserPhotos: [UIImage]?
    @State private var editCollectibleUserPhotos: Bool = false
    
    @State private var isDetailsExpanded = false
    
    // State for controlling the date picker visibility
    @State private var showDatePicker = false
    // State for the selected date
    @State private var selectedDate = Date()
    
    // Create an instance of the ViewModel
    @StateObject private var viewModel = GridGalleryViewModel()
    
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var payload: [Collectible]
    
    private var disablePlusButton: Bool {
        appState.openRelated || isFullScreen
    }
    
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
                    appState.resetGridViewSortAndFilter()
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
    
    private var isCurrentImageDefault: Bool {
        if let index = selectedItem, currentImageIndex < payload[index].gallery.count {
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Views
    var body: some View {
        ZStack {
            backgroundView
            interactiveTutorial
            
            if !isFullScreen {
                gridContentView
            }
            
            if let selectedItem = selectedItem {
                fullScreenView(for: selectedItem)
                
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
            }
            
            if showDatePicker {
                datePickerView
            }
            
            if appState.showAddToCollectionButton && !isFullScreen && !payload.isEmpty {
                VStack {
                    Spacer()
                    informationFooter
                        .padding(.bottom, 40)
                }
            }
            
            // Animated logo transition
            if !appState.openRelated {
                logo
            }
            
            if viewModel.showLoadingIndicator {
                progressView
            }
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
        .modifier(if: isHoneycombGridViewLayoutActive) {
            $0.toolbarBackground(.hidden, for: .navigationBar)
        }
        .navigationBarBackButtonHidden(true)  // Hides the back button
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if appState.openRelated {
                showNavigationTitle = true
                loadRelatedItems()
            } else if appState.showAddToCollectionButton {
                searchResultsSelectionModeOn = true
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            if newValue != oldValue {
                loadGalleryImages()
            }
        }
    }
    
    private var datePickerView: some View {
        DatePickerView(
            showDatePicker: $showDatePicker,
            selectedDate: $selectedDate,
            title: textFieldTitle,
            onDateSelected: onDateSelected
        )
    }
    
    private var backgroundView: some View {
        Group {
            let backgroundImage = selectedBackgroundImage?.first.map { Image(uiImage: $0) }
            ?? Image("background-image")
            
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
        UIDevice.isiPhoneSE ? 6 : (UIDevice.isIpad ? 20 : 40)
    }
    
    private var informationFooterTitle: String {
        let count = viewModel.selectedItemsCount
        
        if count == 0 {
            return "Select"
        }
        
        return  "Add \(count) item\(count > 1 ? "s" : "") to Collection"
    }
    
    private var informationFooter: some View {
        VStack(spacing: 8) {
            Text("\(payload.count) items found")
                .font(.headline.weight(.medium))
            Text("Select items to add to your collection")
                .font(.subheadline)
            
            Button(action: addToCollectionButtonTapped) {
                Text(informationFooterTitle)
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(.black)
            }
            .buttonStyle(.borderedProminent)
            .tint(.appPrimary)
            .disabled(searchResultsSelectionModeOn && viewModel.selectedItemsCount == 0)
        }
        .foregroundColor(.white)
        .padding()
        .blurredBackgroundRounded()
        .padding(.horizontal, 16)
        .padding(.bottom, 60) // Adjusted bottom padding
        .frame(maxWidth: .infinity)
        .alert("Add \(viewModel.selectedItemsCount) item\(viewModel.selectedItemsCount > 1 ? "s" : "") to your collection?",
               isPresented: $showAddToCollectionConfirmation) {
            Button("Add item\(viewModel.selectedItemsCount > 1 ? "s" : "")", action: addToCollection)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will add all selected items to your collection.")
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
                            Text("Build your collection! Tap to choose items, then select 'Add' when you're done.")
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
                    .blurredBackgroundRounded()
                    .padding(60)
                }
                .zIndex(10)
            }
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
    
    private func resetInputViewState() {
        showKeyboard = false
        isTextFieldPresented = false
        textFieldTextInput = ""
        onTextFieldSaveAction = {}
        textFieldTitle = ""
    }
    
    private func resetDatePickerState() {
        textFieldTitle = ""
        onDateSelected = {_ in}
        selectedDate = Date()
        showDatePicker = false
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
                addNewItemTapped(.manually)
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
//                .rotationEffect(.degrees(showEllipsisMenu ? 90 : 0))
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
        viewModel.addToCollectionConfirmed { result in
            if case .success = result {
                searchResultsSelectionModeOn = false
                selectedItem = nil
                
                dismissActionWrapped()
                // TODO: Optimize my collection loading flow
                // Problem: state change and collection datasource load triggered in GridGalleryView
                // Solution:
                // - Move loading responsibility to HomeView
                showCollectionView()
            }
        }
    }
    
    private func showCollectionView() {
        Task {
            do {
                let collection = await viewModel.loadMyCollection()
                await MainActor.run {
                    payload = collection
                    appState.openMyCollection = true
                    appState.showPlusButton = true
                    appState.showEllipsisButton = true
                    appState.showAddToCollectionButton = false
                }
            } catch {
                print("Error loading collection: \(error)")
                // Handle error appropriately
            }
        }
    }
    
    private func onCollectibleDeletion(_ index: Int) {
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
    
    private func confirmCollectibleUserPhotoDeletion() {
        showCollectibleUserPhotoDeleteConfirmation = false
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
    
    @State private var showFullScreenCarousel = false
    
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
                        ZStack {
                            ZStack(alignment: .topLeading) {
                                AsyncImageLoader(
                                    url: viewModel.imageURL(from: imageData),
                                    placeholder: Image(.gridItemPlaceholder),
                                    grayScale: false,
                                    requiresAuth: viewModel.requiresAuth(imageData)
                                )
                                .cornerRadius(12)
                                // NOTE: For better visual feedback during swiping, consider adding this modifier:
                                //                        .animation(.interactiveSpring(), value: currentImageIndex)
                                
                                if currentItem.sold {
                                    Image(.soldBadge)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geometry.size.width * 0.75)
                                }
                            }
                            .scaledToFit()
//                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                            .tag(index)
                            .gesture(
                                TapGesture()
                                    .onEnded {
                                        withAnimation(.spring()) {
                                            editCollectibleUserPhotos = false
                                            
                                            if isFullScreen {
                                                showFullScreenCarousel = true
                                            } else {
                                                isFullScreen = true
                                            }
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
        // TODO: Investigate gesture conflict - when details view expands/collapses,
        // it unexpectedly triggers the carousel's horizontal swipe gestures on iPhone 16 Pro models.
        // Current workaround adjusts frame height (50% for 16 Pro, 45% for others).
        // Possible solutions:
        // 1. Add gesture recognizer delegate to prioritize vertical swipes
        // 2. Implement custom swipe detection with velocity thresholding
        // 3. Adjust zIndex or hit testing during details animation
        // Reproducible: Only occurs on iPhone 16 Pro models in portrait orientation
        // when details view is partially expanded (30-70% height).
            .frame(height: UIScreen.main.bounds.height * (UIDevice.isiPhone16Pro ? 0.5 :0.45))
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
        .textFieldAlert(
            isPresented: $isTextFieldPresented,
            title: textFieldTitle,
            text: $textFieldTextInput,
            onSave: onTextFieldSaveAction,
            onCancel: {
                resetInputViewState()
            })
        .keyboardType(keyboardType)
        .focused($showKeyboard)
        .offset(y: fullScreenViewOffsetY)  // Half of 300 to maintain visual balance
        .sheet(isPresented: $chooseCollectibleUserPhotos) {
            ImagePicker(selectedImages: $selectedCollectibleUserPhotos, selectionLimit: 5)
        }
        .sheet(isPresented: $showFullScreenCarousel) {
            FullScreenCarouselView(
                galleryImages: viewModel.combinedGalleryImages(for: payload[index]),
                initialIndex: currentImageIndex,
                currentIndex: $currentImageIndex,
                itemDetails: payload[index]
            )
            .edgesIgnoringSafeArea(.all)
        }
    
        .sheet(isPresented: $showSafariView) {
            if let url = URLRequest.ebayAffiliateSearchURL(for: payload[index]) {
                SafariView(url: url)
            }
        }
        .onChange(of: selectedCollectibleUserPhotos) {
            // Map each UIImage to PNG data with compression
            let imageDataArray = selectedCollectibleUserPhotos?.compactMap {
                $0.jpegData(compressionQuality: 0.8)
            }
            
            if let dataArray = imageDataArray {
                viewModel.uploadCollectibleUserPhotos(
                    collectibleId: payload[index].id,
                    photos: dataArray) { updatedItem in
                        payload[index] = updatedItem
                    }
            }
        }
    }
    
    private func onPricePaidInput(_ inputText: String) {
        guard let newPrice = Float(inputText) else {
            self.resetInputViewState()
            return
        }
        
        if let index = selectedItem {
            payload[index].pricePaid = newPrice
            viewModel.customAttributeUpdated(for: payload[index])
        }
        
        resetInputViewState()
    }
    
    private func onPurchaseDateInput(_ inputText: String) {
        guard let date = DateFormatUtility.date(from: inputText) else {
            // Show error to user if needed
            resetInputViewState()
            return
        }
        
        if let index = selectedItem {
            payload[index].purchaseDate = date
            viewModel.customAttributeUpdated(for: payload[index])
        }
        
        resetInputViewState()
    }
    
    // MARK: - Sale Details Handlers

    private func onSoldPriceInput(_ inputText: String) {
        guard let price = Float(inputText) else {
            resetInputViewState()
            return
        }
        
        if let index = selectedItem {
            payload[index].soldPrice = price
            viewModel.customAttributeUpdated(for: payload[index])
        }
        
        resetInputViewState()
    }

    private func onSaleDateInput(_ inputText: String) {
        guard let date = DateFormatUtility.date(from: inputText) else {
            resetInputViewState()
            return
        }
        
        if let index = selectedItem {
            payload[index].soldDate = date
            viewModel.customAttributeUpdated(for: payload[index])
        }
        
        resetInputViewState()
    }

    private func onPlatformInput(_ inputText: String) {
        if let index = selectedItem {
            payload[index].soldPlatform = inputText.isEmpty ? nil : inputText
            viewModel.customAttributeUpdated(for: payload[index])
        }
        
        resetInputViewState()
    }
    
    private func onMarkAsSoldTapped(_ value: String) {
        if let index = selectedItem {
            payload[index].sold = true
            viewModel.customAttributeUpdated(for: payload[index])
        }
        
        resetInputViewState()
    }
    
    private func unsellButtonTapped(_ value: String) {
        if let index = selectedItem {
            payload[index].customAttributes?.sales = nil
            viewModel.customAttributeUpdated(for: payload[index])
        }
        
        resetInputViewState()
    }
    
    // Modify the detailsView to be expandable
    private func detailsView(_ currentItem: Collectible) -> some View {
        ZStack {
            // Details content
            ScrollView() {
                Group {
                    headerView("General Info")
                        .padding(.top, 16)
                    detailRow(title: "ITEM:", value: currentItem.attributes.name)
                    detailRow(title: "VALUE:", value: currentItem.estimatedValueDisplay ?? "-", style: .browse)
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
                    
                    detailRow(
                        title: "SERIES:",
                        value: {
                           !(currentItem.querySubject?.isEmpty ?? true) ? currentItem.querySubject! : "-"
                        }(),
                        style: .menu)
                    
                    if viewModel.showAcquisitionDetails(for: currentItem.id) {
                        headerView("Acquisition Details")
                            .padding(.top, 8)
                        
                        detailRow(
                            title: "PURCHASE PRICE:",
                            value: {
                                currentItem.pricePaidDisplay
                            }(),
                            style: .input(UIKeyboardType.decimalPad),
                            onComplete: onPricePaidInput)
                        
                        detailRow(
                            title: "PURCHASE DATE:",
                            value: {
                                currentItem.purchaseDateDisplay
                            }(),
                            style: .datePicker,
                            onComplete: onPurchaseDateInput)
                        
                        detailRow(
                            title: "RETURN:",
                            value: currentItem.returnValueDisplay,
                            style: .returnValue)
                        
                        detailRow(
                            title: "CUSTOM PHOTOS:",
                            value: {
                                if let count = currentItem.customAttributes?.userPhotos?.count, count > 0 {
                                    let plural = count > 1 ? "s" : ""
                                    return "\(count) Photo\(plural)"
                                } else {
                                    return ""
                                }
                            }(),
                            style: .media)
                        
                        headerView("Sale Details")
                            .padding(.top, 8)
                        
                        // New Sale Details Section
                        if viewModel.showSaleDetails(for: currentItem.id) {
                            detailRow(
                                title: "SOLD PRICE:",
                                value: currentItem.soldPriceDisplay,
                                style: .input(UIKeyboardType.decimalPad),
                                onComplete: onSoldPriceInput)
                            
                            detailRow(
                                title: "SALE DATE:",
                                value: currentItem.soldDateDisplay,
                                style: .datePicker,
                                onComplete: onSaleDateInput)
                            
                            detailRow(
                                title: "PLATFORM:",
                                value: currentItem.soldPlatform ?? "",
                                style: .input(UIKeyboardType.default),
                                onComplete: onPlatformInput)
                            
                            detailRow(
                                title: "RETURN TO COLLECTION:",
                                value: "Unsell",
                                style: .actionButton,
                                onComplete: unsellButtonTapped)
                        } else {
                            detailRow(
                                title: "TAP TO ADD DETAILS",
                                value: "Mark as Sold",
                                style: .actionButton,
                                onComplete: onMarkAsSoldTapped)
                        }
                    }
                }
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
                        Image(systemName: isDetailsExpanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
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
        .blurredBackgroundRounded()
        .cornerRadius(20)
        .padding(.bottom, 60)
        .padding(.horizontal, 20)
        .frame(maxHeight: isDetailsExpanded ? .infinity : UIScreen.main.bounds.height*0.4) // Adjust height based on state
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDetailsExpanded)
    }
    
    // Separator
    private func headerView(_ title: String) -> some View {
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
    
    private var filteredRelatedSubjects: [RelatedSubject]? {
        // 1. Check if we have a valid selected item
        guard let index = selectedItem else { return nil }
        
        // 2. Safely access the current item's related subjects
        guard let relatedSubjects = payload[index].attributes.relatedSubjects else { return nil }
        
        // 4. Apply filters
        let filtered = relatedSubjects.filter { subject in
            let hasName = subject.name?.isEmpty == false
            let isNotPrimaryType = subject.type != .userSelectionPrimary
            return hasName && isNotPrimaryType
        }
        
        // 5. Return nil if empty, otherwise return filtered array
        return filtered.isEmpty ? nil : filtered
    }
    
    private func detailsViewMenu(title: String, value: String, style: DetailRowStyle) -> some View {
        HStack(spacing: 16) {
            Text(value)
                .font(.body)
                .foregroundColor(.white)
            
            if let relatedSubjects = filteredRelatedSubjects, let index = selectedItem {
                // Menu version when subject is empty
                relatedSubjectsMenu(
                    subjects: relatedSubjects,
                    label: selectSubjectLabel,
                    listItemImageIcon: "",
                    action: { handleSubjectSelection($0, for: payload[index]) })
            }
        }
    }
    
    private func detailsViewInput(title: String, value: String, keyboardType: UIKeyboardType, onComplete: ((String) -> Void)?) -> some View {
        Button(action: {
            withAnimation {
                onTextFieldSaveAction = { onComplete?(textFieldTextInput) }
                textFieldTitle = title
                isTextFieldPresented = true
                showKeyboard = true
            }
        }) {
            HStack(spacing: 16) {
                Text(value)
                    .font(.body)
                    .foregroundColor(.white)
                Text(!value.isEmpty ? "Edit" : "Set")
                    .font(.body)
                    .foregroundColor(.appPrimary)
            }
        }
    }
    
    private func detailsViewDatePicker(title: String, value: String, onComplete: ((String) -> Void)?) -> some View {
        Button(action: {
            withAnimation {
                withAnimation {
                    showDatePicker = true
                    textFieldTitle = title
                }
                
                onDateSelected = { date in
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    let dateString = formatter.string(from: date)
                    // Handle the selected date string
                    print("Selected date: \(dateString)")
                    
                    onComplete?(dateString)
                }
            }
        }) {
            HStack(spacing: 16) {
                Text(value)
                    .font(.body)
                    .foregroundColor(.white)
                Text(!value.isEmpty ? "Edit" : "Set")
                    .font(.body)
                    .foregroundColor(.appPrimary)
            }
        }
    }
    
    private func detailRow(title: String,
                           value: String,
                           style: DetailRowStyle = .regular,
                           onComplete: ((String) -> Void)? = nil) -> some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            switch style {
            case .regular:
                Text(value)
                    .font(.body)
                    .foregroundColor(.white)
            case .browse:
                Button(action: {
                    ViewHelpers.hapticFeedback()
                    withAnimation(.spring()) {
                        showSafariView = true
                    }
                }) {
                    HStack(spacing: 16) {
                        // TODO: Add RarityImage based on item estimated value
                        Text(value)
                            .font(.body)
                            .foregroundColor(.white)
                        Text("Browse similar")
                            .font(.body)
                            .foregroundColor(.appPrimary)
                    }
                }
            case .input(let keyboardType):
                detailsViewInput(title: title, value: value, keyboardType: keyboardType, onComplete: onComplete)
                
            case .datePicker:
                detailsViewDatePicker(title: title, value: value, onComplete: onComplete)
                
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
                        HStack(spacing: 16) {
                            Text(value)
                                .font(.body)
                                .foregroundColor(.white)
                            Text("Add")
                                .font(.body)
                                .foregroundColor(.appPrimary)
                        }
                    }
                }
                
                if !value.isEmpty {
                    Button(action: {
                        withAnimation {
                            if let index = selectedItem {
                                let defaultImagesCount = payload[index].gallery.count
                                if currentImageIndex < defaultImagesCount {
                                    currentImageIndex = defaultImagesCount // first index in user-uploaded collectible photos
                                }
                            }
                            editCollectibleUserPhotos = true
                        }
                    }) {
                        Text("Edit")
                            .font(.body)
                            .foregroundColor(.appPrimary)
                            .padding(.leading, 8)
                    }
                }
                
            case .returnValue:
                Text(value)
                    .foregroundColor(value.currencyColor)
                    .font(.body)
                
            case .menu:
                detailsViewMenu(title: title, value: value, style: style)
                
            case .actionButton:
                Button(action: {
                    withAnimation {
                        onComplete?("")
                    }
                }) {
                    Text(value)
                        .font(.body)
                        .foregroundColor(.appPrimary)
                        .padding(.leading, 8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
    
    private func relatedSubjectsMenu(subjects relatedSubjects: [RelatedSubject],
                                     label: some View,
                                     listItemImageIcon: String = "magnifyingglass",
                                     action: @escaping (RelatedSubject) -> Void) -> some View {
        Menu {
            Section {
                ForEach(relatedSubjects, id: \.name) { subject in
                    Button(action: {
                        action(subject)
                    }) {
                        Label(subject.name ?? "Untitled", systemImage: listItemImageIcon)
                    }
                }
            } header: {
                Text("Select subject")
                    .font(.title)
                    .foregroundColor(.primary)
            }
        } label: {
            label
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .menuIndicator(.hidden)
    }
    
    private func viewRelatedButton(_ currentItem: Collectible) -> some View {
        Group {
            let relatedSubjects = (currentItem.attributes.relatedSubjects ?? [])
                .filter {
                    $0.name?.isEmpty == false &&
                    $0.type != .userSelectionPrimary
                }
            
            if currentItem.querySubject == nil {
                // Menu version when subject is empty
                relatedSubjectsMenu(subjects: relatedSubjects, label: menuButtonLabel) {
                    if let updatedItem = handleSubjectSelection($0, for: currentItem) {
                        seeMissingPopsAction(updatedItem)
                    }
                }
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
            .blurredBackgroundRounded()
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.appPrimary, lineWidth: 2)
            )
    }
    
    private var selectSubjectLabel: some View {
        Text("Select")
            .font(.body)
            .foregroundColor(.appPrimary)
    }
    
    // Extracted subject selection logic
    private func handleSubjectSelection(_ subject: RelatedSubject, for currentItem: Collectible) -> Collectible? {
        guard let index = payload.firstIndex(where: { $0.id == currentItem.id }) else { return nil }
        
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
        
        return itemToUpdate
    }
    
    private var logo: some View {
        // TODO: Negative frame coordinates detected in leadingNavigationButtonRect
        // when navigating to GridGalleryView after "Add All" action.
        // Symptom: Logo animation moves off-screen during transition
        // Potential causes:
        // - Safe area insets not accounted for
        // - Navigation occurs before frame calculation completes
        // - Coordinate space mismatch (global vs local)
        // Temporary workaround: position hardcoded
        Image("logo-app")
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
    
    // MARK: - Toolbar Components
    
    private var navigationTitle: String {
        showNavigationTitle ? (payload.first?.querySubject ?? "") : ""
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
            if appState.showAddToCollectionButton && searchResultsSelectionModeOn {
                cancelSearchResultsSelectionButton
            }
            
            if appState.showPlusButton {
                addItemButtonDropDownView()
            }
            
            if editCollectibleUserPhotos && !isCurrentImageDefault {
                editCollectibleUserPhotosNavigationItem()
            } else if appState.showEllipsisButton {
                ellipsisButtonDropDownView()
            }
        }
    }
    
    // MARK: - Button Components
    
    private var cancelSearchResultsSelectionButton: some View {
        Button(action: {
            viewModel.cancelSearchResultsSelectionButtonTapped()
            searchResultsSelectionModeOn.toggle()
        }) {
            HStack(spacing: 4) {
                Text(searchResultsSelectionModeOn ? "Cancel" : "Select")
                    .font(.system(size: 14, weight: .medium))
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
    }
    
    private var gridContentView: some View {
        Group {
            if isHoneycombGridViewLayoutActive {
                HoneycombGridView(
                    selectedItem: $selectedItem,
                    isFullScreen: $isFullScreen,
                    showSafariView: $showSafariView,
                    showAddToCollectionButton: $appState.showAddToCollectionButton,
                    items: $payload,
                    onCollectibleDeletion: { index in
                        onCollectibleDeletion(index)
                    },
                    searchResultsSelectionModeOn: searchResultsSelectionModeOn,
                    parentViewModel: viewModel,
                    viewModel: BaseGridViewModel(
                        isHoneycombGridViewLayoutActive: $isHoneycombGridViewLayoutActive,
                        appState: appState)
                )
            } else {
                ResponsiveGridView(
                    selectedItem: $selectedItem,
                    isFullScreen: $isFullScreen,
                    showSafariView: $showSafariView,
                    showAddToCollectionButton: $appState.showAddToCollectionButton,
                    items: $payload,
                    onCollectibleDeletion: { index in
                        onCollectibleDeletion(index)
                    },
                    searchResultsSelectionModeOn: searchResultsSelectionModeOn,
                    parentViewModel: viewModel,
                    viewModel: BaseGridViewModel(
                        isHoneycombGridViewLayoutActive: $isHoneycombGridViewLayoutActive,
                        appState: appState)
                )
            }
        }
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
    
    private var progressView: some View {
        ProgressView()
            .scaleEffect(2)
            .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
            .zIndex(3) // Show above other content
    }
    
    private func addToCollectionButtonTapped() {
        guard viewModel.selectedItemsCount > 0 else {
            searchResultsSelectionModeOn = true
            return
        }
        
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
            Task {
                let myCollection = await viewModel.loadMyCollection()
                
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
                    await MainActor.run {
                        withAnimation(.easeInOut) {
                            payload.append(contentsOf: newItems)
                        }
                        print("Added \(newItems.count) new related items")
                    }
                }
            }
        }
    }
    
    /**
     Fullscreen View Behavior Rules:
     
     1. Presentation Rules:
        - Always shown at full height when expanded (`isFullScreen = true`)
        - Hidden below screen when in collection selection mode
        - Partially visible (peeking) in all other cases
     
     2. Interaction Logic:
        - Card taps only toggle selection in search mode
        - Requires explicit "View" action to show details
        - Never interrupts selection workflow
        - Maintains consistent selection controls
     
     3. Visual Treatment:
        - Default peeking position mimics Funko box figurine display
        - Fully hidden during collection management
        - Smooth transitions between states
     */
    private var fullScreenViewOffsetY: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        
        // Rule 1a: Fullscreen mode
        if isFullScreen { return 0 }
        
        // Rule 1b: Collection selection mode
        if appState.showAddToCollectionButton {
            return screenHeight * 0.8// Completely hidden
        }
        
        // Rule 1c: Default peeking position
        return screenHeight * 0.45 // Funko box display style
    }
}
