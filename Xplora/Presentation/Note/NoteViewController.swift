//
//  NoteViewController.swift
//  Xplora
//

import MapKit
import PhotosUI
import SnapKit
import UIKit

final class NoteViewController: UIViewController {
    private let viewModel: NoteViewModelInput & NoteViewModelOutput

    private let editorContentView = NoteEditorContentView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private let searchContainerView = UIView()
    private let searchBar = UISearchBar()
    private let keyboardToolbar = UIToolbar()
    private var toolbarPrevItem: UIBarButtonItem?
    private var toolbarNextItem: UIBarButtonItem?
    private var toolbarDoneItem: UIBarButtonItem?
    private var searchContainerBottomConstraint: Constraint?

    private var keyboardObserverTokens: [NSObjectProtocol] = []
    private var lastState: NoteViewState?
    private var currentSearchQuery: String = ""
    private var isBoldTyping = false
    private var searchMatches: [NSRange] = []
    private var currentMatchIndex: Int = 0
    private let maxPhotoCount = 10

    init(viewModel: NoteViewModelInput & NoteViewModelOutput) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        keyboardObserverTokens.forEach { NotificationCenter.default.removeObserver($0) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = nil
        configureNavigationBar()
        configureBackButton()
        setupLayout()
        setupActions()
        bindViewModel()
        setupKeyboardHandling()
        viewModel.viewDidLoad()
    }

    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationController?.navigationBar.isTranslucent = true
    }

    private func configureBackButton() {
        let backImage = UIImage(systemName: "chevron.backward")
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: backImage,
            style: .plain,
            target: self,
            action: #selector(didTapBack)
        )
    }

    private func setupLayout() {
        view.addSubview(editorContentView)
        editorContentView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        view.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func setupActions() {
        editorContentView.textView.delegate = self
        let textTap = UITapGestureRecognizer(target: self, action: #selector(didTapText))
        editorContentView.textView.addGestureRecognizer(textTap)

        editorContentView.headerTitleTextField.addTarget(self, action: #selector(titleDidChange), for: .editingChanged)
        let headerTitleTap = UITapGestureRecognizer(target: self, action: #selector(didTapHeaderTitle))
        editorContentView.headerTitleTextField.addGestureRecognizer(headerTitleTap)

        editorContentView.photoSectionView.onRemovePhoto = { [weak self] index in
            self?.viewModel.didRemovePhoto(at: index)
        }
        editorContentView.photoSectionView.onAddPhoto = { [weak self] in
            self?.viewModel.didTapAddPhoto()
        }
        editorContentView.locationSectionView.onAddTapped = { [weak self] in
            self?.presentLocationSearch()
        }
        editorContentView.locationSectionView.onOpenTapped = { [weak self] in
            self?.openCurrentLocationInMaps()
        }
        editorContentView.locationSectionView.onRemoveTapped = { [weak self] in
            self?.viewModel.didRemoveLocation()
        }

        let dateTap = UITapGestureRecognizer(target: self, action: #selector(didTapDate))
        editorContentView.dateLabel.isUserInteractionEnabled = true
        editorContentView.dateLabel.addGestureRecognizer(dateTap)
    }

    private func setupSearchBar() {
        searchContainerView.backgroundColor = .clear
        searchContainerView.isHidden = true

        searchBar.placeholder = L10n.Notes.Editor.Search.placeholder
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundImage = UIImage()
        searchBar.isTranslucent = true
        searchBar.delegate = self
        let textField = searchBar.searchTextField
        textField.backgroundColor = UIColor.secondarySystemBackground
        textField.layer.cornerRadius = 18
        textField.clipsToBounds = true
        textField.clearButtonMode = .never

        configureSearchToolbar()
        textField.inputAccessoryView = keyboardToolbar

        view.addSubview(searchContainerView)
        searchContainerView.addSubview(searchBar)

        searchContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(44)
            searchContainerBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8).constraint
        }

        searchBar.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }

    private func configureSearchToolbar() {
        if toolbarPrevItem == nil {
            toolbarPrevItem = UIBarButtonItem(
                image: UIImage(systemName: "chevron.up"),
                style: .plain,
                target: self,
                action: #selector(didTapSearchPrev)
            )
            toolbarPrevItem?.tintColor = .secondaryLabel
        }

        if toolbarNextItem == nil {
            toolbarNextItem = UIBarButtonItem(
                image: UIImage(systemName: "chevron.down"),
                style: .plain,
                target: self,
                action: #selector(didTapSearchNext)
            )
            toolbarNextItem?.tintColor = .secondaryLabel
        }

        if toolbarDoneItem == nil {
            toolbarDoneItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(didTapSearchDone)
            )
        }

        keyboardToolbar.sizeToFit()
        keyboardToolbar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        keyboardToolbar.frame.size.width = view.bounds.width
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        keyboardToolbar.items = [toolbarPrevItem, toolbarNextItem, spacer, toolbarDoneItem].compactMap { $0 }
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.apply(state: state)
        }
        viewModel.onError = { [weak self] message in
            self?.showError(message: message)
        }
        viewModel.onSearchRequested = { [weak self] in
            guard let self else { return }
            if let state = self.lastState, state.mode == .edit {
                return
            }
            self.openSearchUI()
        }
        viewModel.onPhotoSourceRequested = { [weak self] in
            self?.presentPhotoSourcePicker()
        }
    }

    private func setupKeyboardHandling() {
        let willShow = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification: notification, showing: true)
        }
        let willHide = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification: notification, showing: false)
        }
        keyboardObserverTokens = [willShow, willHide]
    }

    private func handleKeyboard(notification: Notification, showing: Bool) {
        let searchBarOffset: CGFloat
        if showing {
            let keyboardTop = view.keyboardLayoutGuide.layoutFrame.minY
            let safeAreaBottom = view.bounds.height - view.safeAreaInsets.bottom
            let overlap = max(0, safeAreaBottom - keyboardTop)
            searchBarOffset = overlap + 8
        } else {
            searchBarOffset = 8
        }

        searchContainerBottomConstraint?.update(offset: -searchBarOffset)

        let searchBarHeight: CGFloat = searchContainerView.isHidden ? 0 : 52
        let bottomInset = searchBarOffset + searchBarHeight + 8
        editorContentView.scrollView.contentInset.bottom = bottomInset
        editorContentView.scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        view.layoutIfNeeded()
    }

    private func apply(state: NoteViewState) {
        let previousMode = lastState?.mode
        lastState = state

        editorContentView.placeTitleLabel.text = state.placeTitle
        editorContentView.placeTitleBookmarkImageView.isHidden = !state.isBookmarked
        if editorContentView.headerTitleTextField.text != state.title, !editorContentView.headerTitleTextField.isFirstResponder {
            editorContentView.headerTitleTextField.text = state.title
        }
        editorContentView.dateLabel.text = state.dateText
        editorContentView.photoSectionView.configure(
            .init(
                photoURLs: state.photoURLs,
                isEditing: state.mode == .edit,
                canAddPhoto: state.canAddPhoto
            )
        )
        editorContentView.locationSectionView.configure(
            .init(
                mode: state.mode == .edit ? .edit : .view,
                hasLocation: state.hasLocation,
                title: state.locationTitle,
                subtitle: state.locationSubtitle
            )
        )

        let isEditing = state.mode == .edit
        editorContentView.placeTitleRow.isHidden = isEditing
        editorContentView.headerTitleTextField.isHidden = !isEditing
        editorContentView.headerTitleTextField.isEnabled = isEditing
        editorContentView.headerTitleTextField.isUserInteractionEnabled = isEditing

        if isEditing, previousMode != .edit {
            DispatchQueue.main.async { [weak self] in
                self?.editorContentView.headerTitleTextField.becomeFirstResponder()
            }
        }

        if isEditing, !searchContainerView.isHidden {
            didTapSearchDone()
        }

        editorContentView.separatorAboveDate.isHidden = !isEditing
        editorContentView.separatorAboveText.isHidden = !isEditing

        editorContentView.textView.isEditable = isEditing
        editorContentView.textView.isSelectable = isEditing
        editorContentView.textView.isUserInteractionEnabled = true
        editorContentView.textPlaceholderLabel.isHidden = !state.text.isEmpty || !isEditing

        if !editorContentView.textView.isFirstResponder {
            if isEditing {
                editorContentView.textView.text = state.text
            } else {
                applySearchHighlight(text: state.text, query: currentSearchQuery)
            }
        }

        updateNavigationItems(state: state)

        view.isUserInteractionEnabled = !state.isLoading
        if state.isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    private func updateNavigationItems(state: NoteViewState) {
        let editButton = UIBarButtonItem(title: L10n.Common.edit, style: .plain, target: self, action: #selector(didTapEdit))

        let bookmarkTitle = state.isBookmarked ? L10n.Notes.Editor.Menu.Bookmark.remove : L10n.Notes.Editor.Menu.Bookmark.add
        let bookmarkImageName = state.isBookmarked ? "bookmark.fill" : "bookmark"
        let bookmarkAction = UIAction(
            title: bookmarkTitle,
            image: UIImage(systemName: bookmarkImageName),
            state: state.isBookmarked ? .on : .off
        ) { [weak self] _ in
            self?.viewModel.didToggleBookmark()
        }
        bookmarkAction.attributes = state.canToggleBookmark ? [] : [.disabled]

        let searchAction = UIAction(title: L10n.Notes.Editor.Menu.find, image: UIImage(systemName: "magnifyingglass")) { [weak self] _ in
            self?.viewModel.didTapSearch()
        }
        searchAction.attributes = (state.canSearch && state.mode != .edit) ? [] : [.disabled]

        let deleteAction = UIAction(title: L10n.Notes.Editor.Menu.delete, image: UIImage(systemName: "trash"), attributes: [.destructive]) { [weak self] _ in
            self?.confirmDelete()
        }
        deleteAction.attributes = state.isDeleteVisible ? [.destructive] : [.disabled, .destructive]

        let menu = UIMenu(title: "", children: [bookmarkAction, searchAction, deleteAction])
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease"), menu: menu)

        if state.mode == .edit {
            let doneButton = makeSystemCheckmarkButton(isEnabled: state.isSaveEnabled && !state.isLoading)
            navigationItem.rightBarButtonItems = [doneButton, menuButton]
        } else {
            navigationItem.rightBarButtonItems = [menuButton, editButton]
        }
    }

    private func makeSystemCheckmarkButton(isEnabled: Bool) -> UIBarButtonItem {
        let image = UIImage(systemName: "checkmark") ?? UIImage()
        let button = UIButton.systemButton(with: image, target: self, action: #selector(didTapSave))
        button.isEnabled = isEnabled
        button.tintColor = isEnabled ? .systemBlue : .tertiaryLabel
        let item = UIBarButtonItem(customView: button)
        item.isEnabled = isEnabled
        return item
    }

    private func showError(message: String) {
        present(NoteEditorAlertFactory.makeErrorAlert(message: message), animated: true)
    }

    private func confirmDelete() {
        let alert = NoteEditorAlertFactory.makeDeleteConfirmation { [weak self] in
            self?.viewModel.didTapDeleteConfirmed()
        }
        present(alert, animated: true)
    }

    private func confirmExitEditIfNeeded() {
        guard let state = lastState else { return }
        guard state.mode == .edit else { return }

        if state.hasUnsavedChanges {
            let alert = NoteEditorAlertFactory.makeExitConfirmation(
                isSaveEnabled: state.isSaveEnabled,
                onDiscard: { [weak self] in self?.exitScreen() },
                onSave: { [weak self] in self?.viewModel.didTapSave() }
            )
            present(alert, animated: true)
        } else {
            exitScreen()
        }
    }

    private func applySearchHighlight(text: String, query: String) {
        currentSearchQuery = query

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor.label
        ]
        let matchAttributes: [NSAttributedString.Key: Any] = [
            .backgroundColor: UIColor.systemYellow.withAlphaComponent(0.28)
        ]
        let activeMatchAttributes: [NSAttributedString.Key: Any] = [
            .backgroundColor: UIColor.systemYellow.withAlphaComponent(0.7),
            .foregroundColor: UIColor.label
        ]

        let result = NoteTextHighlighter.highlight(
            text: text,
            query: query,
            activeMatchIndex: currentMatchIndex,
            baseAttributes: baseAttributes,
            matchAttributes: matchAttributes,
            activeMatchAttributes: activeMatchAttributes
        )

        searchMatches = result.matches
        editorContentView.textView.attributedText = result.attributedText

        if query.isEmpty {
            currentMatchIndex = 0
        } else if !result.matches.isEmpty {
            currentMatchIndex = min(currentMatchIndex, result.matches.count - 1)
            editorContentView.textView.scrollRangeToVisible(result.matches[currentMatchIndex])
        }
        updateSearchNavigationButtons()
    }

    @objc private func titleDidChange() {
        viewModel.didChangeTitle(editorContentView.headerTitleTextField.text)
    }

    @objc private func didTapHeaderTitle() {
        guard let state = lastState, state.mode == .edit else { return }
        editorContentView.headerTitleTextField.becomeFirstResponder()
    }

    @objc private func didTapText() {
        guard let state = lastState, state.mode == .edit else { return }
        editorContentView.textView.becomeFirstResponder()
    }

    @objc private func didTapEdit() {
        if !searchContainerView.isHidden {
            didTapSearchDone()
        }
        viewModel.didTapEdit()
    }

    @objc private func didTapSave() {
        guard let state = lastState, state.isSaveEnabled else { return }
        viewModel.didTapSave()
    }

    @objc private func didTapBack() {
        guard let state = lastState else {
            exitScreen()
            return
        }
        guard state.mode == .edit, state.hasUnsavedChanges else {
            exitScreen()
            return
        }
        confirmExitEditIfNeeded()
    }

    @objc private func didTapDate() {
        guard let state = lastState, state.mode == .edit else { return }
        let today = NoteDateRangeNormalizer.today()
        let normalizedExisting = NoteDateRangeNormalizer.normalizedRange(
            start: state.tripStartDate,
            end: state.tripEndDate,
            today: today
        )
        let fallbackDate = NoteDateRangeNormalizer.normalizedRange(
            start: state.fallbackDate,
            end: state.fallbackDate,
            today: today
        ).start ?? today
        let initialStart = normalizedExisting.start ?? normalizedExisting.end ?? fallbackDate
        presentDatePicker(
            title: L10n.Notes.Editor.Date.from,
            initialDate: initialStart,
            maximumDate: today
        ) { [weak self] startDate in
            guard let self else { return }
            let normalizedStart = NoteDateRangeNormalizer.normalizedRange(
                start: startDate,
                end: startDate,
                today: today
            ).start ?? today
            let existingEnd = normalizedExisting.end ?? normalizedStart
            let initialEnd = max(existingEnd, normalizedStart)
            self.presentDatePicker(
                title: L10n.Notes.Editor.Date.to,
                initialDate: initialEnd,
                minimumDate: normalizedStart,
                maximumDate: today
            ) { [weak self] endDate in
                guard let self else { return }
                let normalizedRange = NoteDateRangeNormalizer.normalizedRange(
                    start: normalizedStart,
                    end: endDate,
                    today: today
                )
                guard let rangeStart = normalizedRange.start, let rangeEnd = normalizedRange.end else { return }
                self.viewModel.didUpdateTripDateRange(startDate: rangeStart, endDate: rangeEnd)
            }
        }
    }

    private func presentDatePicker(
        title: String,
        initialDate: Date,
        minimumDate: Date? = nil,
        maximumDate: Date? = nil,
        onSave: @escaping (Date) -> Void
    ) {
        let pickerController = NoteDatePickerSheetViewController(
            titleText: title,
            initialDate: initialDate,
            minimumDate: minimumDate,
            maximumDate: maximumDate
        ) { [weak self] selectedDate in
            self?.dismiss(animated: true)
            onSave(selectedDate)
        }
        let navigationController = UINavigationController(rootViewController: pickerController)
        navigationController.modalPresentationStyle = .pageSheet
        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        present(navigationController, animated: true)
    }

    @objc private func didTapFormat() {
        guard let state = lastState, state.mode == .edit else { return }
        let selectedRange = editorContentView.textView.selectedRange
        if selectedRange.length > 0 {
            let attributed = NSMutableAttributedString(attributedString: editorContentView.textView.attributedText ?? NSAttributedString(string: editorContentView.textView.text))
            let boldFont = UIFont.systemFont(ofSize: 16, weight: .bold)
            attributed.addAttribute(.font, value: boldFont, range: selectedRange)
            editorContentView.textView.attributedText = attributed
            editorContentView.textView.selectedRange = selectedRange
        } else {
            isBoldTyping.toggle()
            let font = isBoldTyping ? UIFont.systemFont(ofSize: 16, weight: .bold) : UIFont.systemFont(ofSize: 16, weight: .medium)
            editorContentView.textView.typingAttributes[.font] = font
        }
    }

    private func openCurrentLocationInMaps() {
        guard let state = lastState else { return }
        guard state.hasLocation, let coordinate = state.locationCoordinate else { return }
        let mapCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: mapCoordinate))
        mapItem.name = state.locationTitle
        MKMapItem.openMaps(with: [mapItem], launchOptions: nil)
    }

    private func presentPhotoSourcePicker() {
        if let state = lastState, !state.canAddPhoto {
            showError(message: L10n.Notes.Editor.Photo.limit(maxPhotoCount))
            return
        }

        let alert = NoteEditorAlertFactory.makePhotoSourceActionSheet(
            onCamera: { [weak self] in self?.presentCameraPicker() },
            onLibrary: { [weak self] in self?.presentPhotoLibraryPicker() }
        )

        if let popover = alert.popoverPresentationController {
            popover.sourceView = editorContentView.photoSectionView
            popover.sourceRect = CGRect(
                x: editorContentView.photoSectionView.bounds.midX,
                y: editorContentView.photoSectionView.bounds.midY,
                width: 1,
                height: 1
            )
        }
        present(alert, animated: true)
    }

    private func presentCameraPicker() {
        if let state = lastState, !state.canAddPhoto {
            showError(message: L10n.Notes.Editor.Photo.limit(maxPhotoCount))
            return
        }

        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showError(message: L10n.Notes.Editor.Photo.Camera.unavailable)
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    private func presentPhotoLibraryPicker() {
        guard let state = lastState else { return }
        let remainingSlots = maxPhotoCount - state.photoURLs.count
        guard remainingSlots > 0 else {
            showError(message: L10n.Notes.Editor.Photo.limit(maxPhotoCount))
            return
        }

        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = state.preselectedAssetIdentifiers.count + remainingSlots
        configuration.selection = .default
        configuration.filter = .images
        configuration.preselectedAssetIdentifiers = state.preselectedAssetIdentifiers

        let picker = PHPickerViewController(configuration: configuration)
        picker.title = L10n.Notes.Editor.Photo.Picker.counter(state.photoURLs.count, maxPhotoCount)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentLocationSearch() {
        let controller = LocationSearchViewController()
        controller.onLocationSelected = { [weak self] mapItem, completion in
            guard let self else { return }
            let placeName = self.resolvedPlaceName(mapItem: mapItem, completion: completion)
            let address = self.resolvedAddress(mapItem: mapItem, completion: completion)
            let coordinate = mapItem.placemark.coordinate
            self.viewModel.didSelectLocation(
                placeName: placeName,
                address: address,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        }
        controller.modalPresentationStyle = .pageSheet
        present(controller, animated: true)
    }

    private func resolvedPlaceName(mapItem: MKMapItem, completion: MKLocalSearchCompletion) -> String {
        let mapName = (mapItem.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !mapName.isEmpty {
            return mapName
        }
        return completion.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func resolvedAddress(mapItem: MKMapItem, completion: MKLocalSearchCompletion) -> String? {
        let completionSubtitle = completion.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !completionSubtitle.isEmpty {
            return completionSubtitle
        }
        let placemarkTitle = (mapItem.placemark.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return placemarkTitle.isEmpty ? nil : placemarkTitle
    }

    @objc private func didTapSearchDone() {
        searchContainerView.isHidden = true
        searchBar.searchTextField.resignFirstResponder()
        if let state = lastState {
            applySearchHighlight(text: state.text, query: "")
        }
        updateSearchNavigationButtons()
        editorContentView.scrollView.contentInset.bottom = 16
        editorContentView.scrollView.verticalScrollIndicatorInsets.bottom = 16
    }

    @objc private func didTapSearchPrev() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = max(0, currentMatchIndex - 1)
        applySearchHighlight(text: editorContentView.textView.text ?? "", query: currentSearchQuery)
    }

    @objc private func didTapSearchNext() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = min(searchMatches.count - 1, currentMatchIndex + 1)
        applySearchHighlight(text: editorContentView.textView.text ?? "", query: currentSearchQuery)
    }

    private func updateSearchNavigationButtons() {
        guard !searchMatches.isEmpty else {
            toolbarPrevItem?.isEnabled = false
            toolbarNextItem?.isEnabled = false
            return
        }
        toolbarPrevItem?.isEnabled = currentMatchIndex > 0
        toolbarNextItem?.isEnabled = currentMatchIndex < searchMatches.count - 1
    }

    private func openSearchUI() {
        if searchContainerView.superview == nil {
            setupSearchBar()
        }
        searchContainerView.isHidden = false
        searchBar.searchTextField.becomeFirstResponder()
        updateSearchNavigationButtons()
    }

    private func exitScreen() {
        if let navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

}

extension NoteViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        viewModel.didChangeText(textView.text)
        editorContentView.textPlaceholderLabel.isHidden = !textView.text.isEmpty
    }
}

extension NoteViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let state = lastState else { return }
        currentMatchIndex = 0
        applySearchHighlight(text: state.text, query: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.searchTextField.resignFirstResponder()
    }
}

extension NoteViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        viewModel.didFinishPhotoLibraryPicking(results: results)
    }
}

extension NoteViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        viewModel.didCapturePhoto(image)
    }
}
