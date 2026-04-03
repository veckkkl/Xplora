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

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let photoSectionView = NotePhotoSectionView()
    private let locationSectionView = NoteLocationSectionView()
    private let placeTitleRow = UIStackView()
    private let placeTitleLabel = UILabel()
    private let placeTitleBookmarkImageView = UIImageView()
    private let headerTitleTextField = UITextField()
    private let dateLabel = UILabel()
    private let separatorAboveDate = UIView()
    private let separatorAboveText = UIView()
    private let textView = UITextView()
    private let textPlaceholderLabel = UILabel()
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
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .fill

        placeTitleRow.axis = .horizontal
        placeTitleRow.alignment = .center
        placeTitleRow.spacing = 8

        placeTitleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        placeTitleLabel.textColor = .label
        placeTitleLabel.numberOfLines = 0
        placeTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        placeTitleBookmarkImageView.image = UIImage(systemName: "bookmark.fill")
        placeTitleBookmarkImageView.tintColor = .systemOrange
        placeTitleBookmarkImageView.contentMode = .scaleAspectFit
        placeTitleBookmarkImageView.isHidden = true
        placeTitleBookmarkImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        headerTitleTextField.placeholder = "Title"
        headerTitleTextField.borderStyle = .none
        headerTitleTextField.backgroundColor = .clear
        headerTitleTextField.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        headerTitleTextField.textColor = .label
        headerTitleTextField.isUserInteractionEnabled = true

        dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        dateLabel.textColor = .secondaryLabel

        textView.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        textView.textColor = .label
        textView.backgroundColor = .clear
        textView.layer.cornerRadius = 0
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.isScrollEnabled = false
        let textTap = UITapGestureRecognizer(target: self, action: #selector(didTapText))
        textView.addGestureRecognizer(textTap)

        textPlaceholderLabel.text = "Write your note..."
        textPlaceholderLabel.textColor = .tertiaryLabel
        textPlaceholderLabel.font = UIFont.preferredFont(forTextStyle: .body)
        textView.addSubview(textPlaceholderLabel)

        textPlaceholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        separatorAboveDate.backgroundColor = .separator
        separatorAboveText.backgroundColor = .separator

        placeTitleRow.addArrangedSubview(placeTitleLabel)
        placeTitleRow.addArrangedSubview(placeTitleBookmarkImageView)
        stackView.addArrangedSubview(placeTitleRow)
        stackView.addArrangedSubview(headerTitleTextField)
        stackView.addArrangedSubview(photoSectionView)
        stackView.addArrangedSubview(locationSectionView)
        stackView.addArrangedSubview(separatorAboveDate)
        stackView.addArrangedSubview(dateLabel)
        stackView.addArrangedSubview(separatorAboveText)
        stackView.addArrangedSubview(textView)

        placeTitleBookmarkImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        separatorAboveDate.snp.makeConstraints { make in
            make.height.equalTo(1)
        }

        separatorAboveText.snp.makeConstraints { make in
            make.height.equalTo(1)
        }

        textView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(240)
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-24)
        }

        view.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func setupActions() {
        headerTitleTextField.addTarget(self, action: #selector(headerTitleDidChange), for: .editingChanged)
        let headerTitleTap = UITapGestureRecognizer(target: self, action: #selector(didTapHeaderTitle))
        headerTitleTextField.addGestureRecognizer(headerTitleTap)

        photoSectionView.onRemovePhoto = { [weak self] index in
            self?.viewModel.didRemovePhoto(at: index)
        }
        photoSectionView.onAddPhoto = { [weak self] in
            self?.viewModel.didTapAddPhoto()
        }
        locationSectionView.onAddTapped = { [weak self] in
            self?.presentLocationSearch()
        }
        locationSectionView.onOpenTapped = { [weak self] in
            self?.openCurrentLocationInMaps()
        }
        locationSectionView.onRemoveTapped = { [weak self] in
            self?.viewModel.didRemoveLocation()
        }

        let dateTap = UITapGestureRecognizer(target: self, action: #selector(didTapDate))
        dateLabel.isUserInteractionEnabled = true
        dateLabel.addGestureRecognizer(dateTap)
    }

    private func setupSearchBar() {
        searchContainerView.backgroundColor = .clear
        searchContainerView.isHidden = true

        searchBar.placeholder = "Search in note"
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
        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        view.layoutIfNeeded()
    }

    private func apply(state: NoteViewState) {
        let previousMode = lastState?.mode
        lastState = state

        placeTitleLabel.text = state.placeTitle
        placeTitleBookmarkImageView.isHidden = !state.isBookmarked
        if headerTitleTextField.text != state.title, !headerTitleTextField.isFirstResponder {
            headerTitleTextField.text = state.title
        }
        dateLabel.text = state.dateText
        photoSectionView.configure(
            .init(
                photoURLs: state.photoURLs,
                isEditing: state.mode == .edit,
                canAddPhoto: state.canAddPhoto
            )
        )
        locationSectionView.configure(
            .init(
                mode: state.mode == .edit ? .edit : .view,
                hasLocation: state.hasLocation,
                title: state.locationTitle,
                subtitle: state.locationSubtitle
            )
        )

        let isEditing = state.mode == .edit
        placeTitleRow.isHidden = isEditing
        headerTitleTextField.isHidden = !isEditing
        headerTitleTextField.isEnabled = isEditing
        headerTitleTextField.isUserInteractionEnabled = isEditing

        if isEditing, previousMode != .edit {
            DispatchQueue.main.async { [weak self] in
                self?.headerTitleTextField.becomeFirstResponder()
            }
        }

        if isEditing, !searchContainerView.isHidden {
            didTapSearchDone()
        }

        separatorAboveDate.isHidden = !isEditing
        separatorAboveText.isHidden = !isEditing

        textView.isEditable = isEditing
        textView.isSelectable = isEditing
        textView.isUserInteractionEnabled = true
        textPlaceholderLabel.isHidden = !state.text.isEmpty || !isEditing

        if !textView.isFirstResponder {
            if isEditing {
                textView.text = state.text
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
        let editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(didTapEdit))

        let bookmarkTitle = state.isBookmarked ? "Remove Bookmark" : "Add Bookmark"
        let bookmarkImageName = state.isBookmarked ? "bookmark.fill" : "bookmark"
        let bookmarkAction = UIAction(
            title: bookmarkTitle,
            image: UIImage(systemName: bookmarkImageName),
            state: state.isBookmarked ? .on : .off
        ) { [weak self] _ in
            self?.viewModel.didToggleBookmark()
        }
        bookmarkAction.attributes = state.canToggleBookmark ? [] : [.disabled]

        let searchAction = UIAction(title: "Find in Note", image: UIImage(systemName: "magnifyingglass")) { [weak self] _ in
            self?.viewModel.didTapSearch()
        }
        searchAction.attributes = (state.canSearch && state.mode != .edit) ? [] : [.disabled]

        let deleteAction = UIAction(title: "Delete Note", image: UIImage(systemName: "trash"), attributes: [.destructive]) { [weak self] _ in
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
        let alert = UIAlertController(title: "Something went wrong", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func confirmDelete() {
        let alert = UIAlertController(
            title: "Delete note?",
            message: "This action can't be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.viewModel.didTapDeleteConfirmed()
        })
        present(alert, animated: true)
    }

    private func confirmExitEditIfNeeded() {
        guard let state = lastState else { return }
        guard state.mode == .edit else { return }

        if state.hasUnsavedChanges {
            let alert = UIAlertController(
                title: "Save changes?",
                message: "You have unsaved changes.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
                self?.exitScreen()
            })
            let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
                self?.viewModel.didTapSave()
            }
            saveAction.isEnabled = state.isSaveEnabled
            alert.addAction(saveAction)
            present(alert, animated: true)
        } else {
            exitScreen()
        }
    }

    private func applySearchHighlight(text: String, query: String) {
        currentSearchQuery = query
        guard !query.isEmpty else {
            searchMatches = []
            currentMatchIndex = 0
            textView.attributedText = NSAttributedString(string: text, attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.label
            ])
            return
        }

        let attributed = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor.label
        ])

        let lowercasedText = text.lowercased()
        let lowercasedQuery = query.lowercased()
        var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex
        searchMatches = []

        while let range = lowercasedText.range(of: lowercasedQuery, options: [], range: searchRange) {
            let nsRange = NSRange(range, in: lowercasedText)
            searchMatches.append(nsRange)
            attributed.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.28), range: nsRange)
            searchRange = range.upperBound..<lowercasedText.endIndex
        }

        if !searchMatches.isEmpty {
            currentMatchIndex = min(currentMatchIndex, searchMatches.count - 1)
            let currentMatch = searchMatches[currentMatchIndex]
            attributed.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.7), range: currentMatch)
            attributed.addAttribute(.foregroundColor, value: UIColor.label, range: currentMatch)
            textView.attributedText = attributed
            textView.scrollRangeToVisible(currentMatch)
        } else {
            textView.attributedText = attributed
        }
        updateSearchNavigationButtons()
    }

    @objc private func headerTitleDidChange() {
        viewModel.didChangeTitle(headerTitleTextField.text)
    }

    @objc private func didTapHeaderTitle() {
        guard let state = lastState, state.mode == .edit else { return }
        headerTitleTextField.becomeFirstResponder()
    }

    @objc private func didTapText() {
        guard let state = lastState, state.mode == .edit else { return }
        textView.becomeFirstResponder()
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
            title: "From",
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
                title: "To",
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
        let selectedRange = textView.selectedRange
        if selectedRange.length > 0 {
            let attributed = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString(string: textView.text))
            let boldFont = UIFont.systemFont(ofSize: 16, weight: .bold)
            attributed.addAttribute(.font, value: boldFont, range: selectedRange)
            textView.attributedText = attributed
            textView.selectedRange = selectedRange
        } else {
            isBoldTyping.toggle()
            let font = isBoldTyping ? UIFont.systemFont(ofSize: 16, weight: .bold) : UIFont.systemFont(ofSize: 16, weight: .medium)
            textView.typingAttributes[.font] = font
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
            showError(message: "You can add up to 10 photos.")
            return
        }

        let alert = UIAlertController(title: "Add Photo", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.presentCameraPicker()
        })
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.presentPhotoLibraryPicker()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = photoSectionView
            popover.sourceRect = CGRect(
                x: photoSectionView.bounds.midX,
                y: photoSectionView.bounds.midY,
                width: 1,
                height: 1
            )
        }
        present(alert, animated: true)
    }

    private func presentCameraPicker() {
        if let state = lastState, !state.canAddPhoto {
            showError(message: "You can add up to 10 photos.")
            return
        }

        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showError(message: "Camera is not available on this device.")
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
            showError(message: "You can add up to \(maxPhotoCount) photos.")
            return
        }

        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = state.preselectedAssetIdentifiers.count + remainingSlots
        configuration.selection = .default
        configuration.filter = .images
        configuration.preselectedAssetIdentifiers = state.preselectedAssetIdentifiers

        let picker = PHPickerViewController(configuration: configuration)
        picker.title = "\(state.photoURLs.count)/\(maxPhotoCount)"
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
        scrollView.contentInset.bottom = 16
        scrollView.verticalScrollIndicatorInsets.bottom = 16
    }

    @objc private func didTapSearchPrev() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = max(0, currentMatchIndex - 1)
        applySearchHighlight(text: textView.text ?? "", query: currentSearchQuery)
    }

    @objc private func didTapSearchNext() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = min(searchMatches.count - 1, currentMatchIndex + 1)
        applySearchHighlight(text: textView.text ?? "", query: currentSearchQuery)
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
        textPlaceholderLabel.isHidden = !textView.text.isEmpty
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

private final class NoteDatePickerSheetViewController: UIViewController {
    private let titleText: String
    private let minimumDate: Date?
    private let maximumDate: Date?
    private let onSave: (Date) -> Void
    private let datePicker = UIDatePicker()

    init(
        titleText: String,
        initialDate: Date,
        minimumDate: Date?,
        maximumDate: Date?,
        onSave: @escaping (Date) -> Void
    ) {
        self.titleText = titleText
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
        var clampedDate = initialDate
        if let minimumDate, clampedDate < minimumDate {
            clampedDate = minimumDate
        }
        if let maximumDate, clampedDate > maximumDate {
            clampedDate = maximumDate
        }
        datePicker.date = clampedDate
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = titleText

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(didTapCancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(didTapSave)
        )

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate = minimumDate
        datePicker.maximumDate = maximumDate

        view.addSubview(datePicker)
        datePicker.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
        }
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    @objc private func didTapSave() {
        onSave(datePicker.date)
    }
}
