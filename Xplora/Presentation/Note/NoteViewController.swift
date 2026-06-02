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

    private let keyboardObserver = NoteEditorKeyboardObserver()
    private lazy var photoPickerPresenter = NotePhotoPickerPresenter(maxPhotoCount: maxPhotoCount)
    private let searchController = NoteTextSearchController()
    private var lastState: NoteViewState?
    private var isBoldTyping = false
    private let maxPhotoCount = 10

    init(viewModel: NoteViewModelInput & NoteViewModelOutput) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        setupPhotoPickerPresenter()
        setupSearchController()
        viewModel.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Reclaim the interactive swipe-back gesture: UINavigationController
        // disables it by default when the leftBarButtonItem is custom (our
        // chevron back button). Hosting it through our delegate restores the
        // standard edge swipe.
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Release the delegate so other screens own the gesture again.
        if navigationController?.interactivePopGestureRecognizer?.delegate === self {
            navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }

    private func setupSearchController() {
        searchController.parentView = view
        searchController.textView = editorContentView.textView
        searchController.onClose = { [weak self] in
            guard let self else { return }
            self.editorContentView.scrollView.contentInset.bottom = 16
            self.editorContentView.scrollView.verticalScrollIndicatorInsets.bottom = 16
        }
    }

    private func setupPhotoPickerPresenter() {
        photoPickerPresenter.presentingViewController = self
        photoPickerPresenter.sourceView = editorContentView.photoSectionView
        photoPickerPresenter.onCapturePhoto = { [weak self] image in
            self?.viewModel.didCapturePhoto(image)
        }
        photoPickerPresenter.onPhotoLibrarySelection = { [weak self] results in
            self?.viewModel.didFinishPhotoLibraryPicking(results: results)
        }
        photoPickerPresenter.onError = { [weak self] message in
            self?.showError(message: message)
        }
    }

    private func configureNavigationBar() {
        NoteEditorNavigationBarConfigurator.applyTransparentAppearance(
            to: navigationItem,
            navigationBar: navigationController?.navigationBar
        )
    }

    private func configureBackButton() {
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = NoteEditorNavigationBarConfigurator.makeBackButton(
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
            self.searchController.open()
        }
        viewModel.onPhotoSourceRequested = { [weak self] in
            self?.presentPhotoSource()
        }
    }

    private func presentPhotoSource() {
        guard let state = lastState else { return }
        photoPickerPresenter.presentSource(context: .init(
            canAddPhoto: state.canAddPhoto,
            photoURLsCount: state.photoURLs.count,
            preselectedAssetIdentifiers: state.preselectedAssetIdentifiers
        ))
    }

    private func setupKeyboardHandling() {
        keyboardObserver.onWillShow = { [weak self] in
            self?.handleKeyboard(showing: true)
        }
        keyboardObserver.onWillHide = { [weak self] in
            self?.handleKeyboard(showing: false)
        }
        keyboardObserver.start()
    }

    private func handleKeyboard(showing: Bool) {
        let searchBarOffset: CGFloat
        if showing {
            let keyboardTop = view.keyboardLayoutGuide.layoutFrame.minY
            let safeAreaBottom = view.bounds.height - view.safeAreaInsets.bottom
            let overlap = max(0, safeAreaBottom - keyboardTop)
            searchBarOffset = overlap + 8
        } else {
            searchBarOffset = 8
        }

        searchController.setSearchBarBottomOffset(searchBarOffset)

        let bottomInset = searchBarOffset + searchController.searchBarHeight + 8
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

        if isEditing, searchController.isVisible {
            searchController.close()
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
                searchController.refresh(text: state.text)
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
        navigationItem.rightBarButtonItems = NoteEditorNavigationBarConfigurator.makeRightItems(
            state: state,
            editTarget: self,
            editAction: #selector(didTapEdit),
            saveTarget: self,
            saveAction: #selector(didTapSave),
            menuHandlers: .init(
                onToggleBookmark: { [weak self] in self?.viewModel.didToggleBookmark() },
                onTapSearch: { [weak self] in self?.viewModel.didTapSearch() },
                onConfirmDelete: { [weak self] in self?.confirmDelete() }
            )
        )
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
        if searchController.isVisible {
            searchController.close()
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

    private func presentLocationSearch() {
        let controller = LocationSearchViewController()
        controller.onLocationSelected = { [weak self] mapItem, completion in
            guard let self else { return }
            let placeName = self.resolvedPlaceName(mapItem: mapItem, completion: completion)
            let address = self.resolvedAddress(mapItem: mapItem, completion: completion)
            let coordinate = mapItem.placemark.coordinate
            let countryCode = mapItem.placemark.isoCountryCode
            self.viewModel.didSelectLocation(
                placeName: placeName,
                address: address,
                countryCode: countryCode,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        }
        let navigation = UINavigationController(rootViewController: controller)
        navigation.modalPresentationStyle = .pageSheet
        present(navigation, animated: true)
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

extension NoteViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === navigationController?.interactivePopGestureRecognizer else {
            return true
        }
        // Only the root note screen pops; otherwise nothing to swipe back to.
        guard (navigationController?.viewControllers.count ?? 0) > 1 else { return false }
        // Block the gesture when there are unsaved changes so a stray swipe
        // doesn't discard the draft. The chevron back button still routes
        // through the confirm dialog.
        if let state = lastState, state.mode == .edit, state.hasUnsavedChanges {
            return false
        }
        return true
    }
}
