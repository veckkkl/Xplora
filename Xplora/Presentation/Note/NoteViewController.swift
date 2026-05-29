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

    private func setupSearchController() {
        searchController.parentView = view
        searchController.textView = textView
        searchController.onClose = { [weak self] in
            guard let self else { return }
            self.scrollView.contentInset.bottom = 16
            self.scrollView.verticalScrollIndicatorInsets.bottom = 16
        }
    }

    private func setupPhotoPickerPresenter() {
        photoPickerPresenter.presentingViewController = self
        photoPickerPresenter.sourceView = photoSectionView
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

        headerTitleTextField.placeholder = L10n.Notes.Editor.Title.placeholder
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

        textPlaceholderLabel.text = L10n.Notes.Editor.Text.placeholder
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
        headerTitleTextField.addTarget(self, action: #selector(titleDidChange), for: .editingChanged)
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

        if isEditing, searchController.isVisible {
            searchController.close()
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

