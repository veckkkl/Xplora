//
//  NoteViewController.swift
//  Xplora
//

import SnapKit
import UIKit

final class NoteViewController: UIViewController {
    private let viewModel: NoteViewModelInput & NoteViewModelOutput

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let photoCollageView = TripPhotoCollageView()
    private var photoCollageHeightConstraint: Constraint?
    private let locationPillView = UIView()
    private let locationIconView = UIImageView()
    private let locationLabel = UILabel()
    private let locationRemoveButton = UIButton(type: .system)
    private let placeTitleRow = UIStackView()
    private let placeTitleLabel = UILabel()
    private let placeTitleBookmarkImageView = UIImageView()
    private let headerTitleTextField = UITextField()
    private let titleTextField = UITextField()
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
    private var photoURLs: [URL] = []
    private var lastState: NoteViewState?
    private var currentSearchQuery: String = ""
    private var isBoldTyping = false
    private var pendingStartDate: Date?
    private var searchMatches: [NSRange] = []
    private var currentMatchIndex: Int = 0
    private var pendingSearchAfterEdit = false
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

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

    private func setupLayout() {
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .fill

        locationPillView.backgroundColor = .secondarySystemBackground
        locationPillView.layer.cornerRadius = 12
        locationPillView.clipsToBounds = true
        locationPillView.addSubview(locationIconView)
        locationPillView.addSubview(locationLabel)
        locationPillView.addSubview(locationRemoveButton)

        locationIconView.image = UIImage(systemName: "mappin.and.ellipse")
        locationIconView.tintColor = .secondaryLabel

        locationLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        locationLabel.textColor = .secondaryLabel

        locationLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.equalTo(locationIconView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(12)
        }

        locationIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        locationRemoveButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        locationRemoveButton.tintColor = UIColor.black.withAlphaComponent(0.55)
        locationRemoveButton.addTarget(self, action: #selector(didTapRemoveLocation), for: .touchUpInside)
        locationRemoveButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 18, height: 18))
        }

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

        headerTitleTextField.placeholder = "Location"
        headerTitleTextField.borderStyle = .none
        headerTitleTextField.backgroundColor = .clear
        headerTitleTextField.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        headerTitleTextField.textColor = .label

        titleTextField.placeholder = "Title"
        titleTextField.borderStyle = .none
        titleTextField.backgroundColor = .clear
        titleTextField.font = UIFont.systemFont(ofSize: 16, weight: .medium)

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
        stackView.addArrangedSubview(photoCollageView)
        stackView.addArrangedSubview(locationPillView)
        stackView.addArrangedSubview(titleTextField)
        stackView.addArrangedSubview(separatorAboveDate)
        stackView.addArrangedSubview(dateLabel)
        stackView.addArrangedSubview(separatorAboveText)
        stackView.addArrangedSubview(textView)

        photoCollageView.snp.makeConstraints { make in
            photoCollageHeightConstraint = make.height.equalTo(0).constraint
        }

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
        titleTextField.addTarget(self, action: #selector(titleDidChange), for: .editingChanged)
        headerTitleTextField.addTarget(self, action: #selector(headerTitleDidChange), for: .editingChanged)
        locationPillView.isUserInteractionEnabled = true
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
                self.pendingSearchAfterEdit = true
                self.confirmExitEditIfNeeded()
                return
            }
            self.openSearchUI()
        }
    }

    private func setupKeyboardHandling() {
        let willShow = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification: notification, showing: true)
            guard let self else { return }
            if self.searchBar.searchTextField.isFirstResponder {
                self.searchBar.searchTextField.inputAccessoryView = self.keyboardToolbar
                self.searchBar.searchTextField.reloadInputViews()
            }
        }
        let willHide = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification: notification, showing: false)
            guard let self else { return }
            self.searchBar.searchTextField.inputAccessoryView = nil
            self.searchBar.searchTextField.reloadInputViews()
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
        lastState = state

        if titleTextField.text != state.title, !titleTextField.isFirstResponder {
            titleTextField.text = state.title
        }

        placeTitleLabel.text = state.placeTitle
        placeTitleBookmarkImageView.isHidden = !state.isBookmarked
        if headerTitleTextField.text != state.placeTitle, !headerTitleTextField.isFirstResponder {
            headerTitleTextField.text = state.placeTitle
        }
        dateLabel.text = state.dateText
        locationLabel.text = state.locationText

        photoURLs = state.photoURLs
        photoCollageView.isHidden = photoURLs.isEmpty
        if !photoCollageView.isHidden {
            photoCollageView.configure(urls: photoURLs, showRemoveButton: state.mode == .edit)
            view.layoutIfNeeded()
            let width = photoCollageView.bounds.width > 0 ? photoCollageView.bounds.width : (view.bounds.width - 40)
            let height = photoCollageView.preferredHeight(forWidth: width)
            photoCollageHeightConstraint?.update(offset: height)
        } else {
            photoCollageHeightConstraint?.update(offset: 0)
        }
        photoCollageView.onPhotoRemove = { [weak self] index in
            guard let self else { return }
            guard state.mode == .edit else { return }
            self.viewModel.didRemovePhoto(at: index)
        }

        locationPillView.isHidden = !state.hasLocation
        locationRemoveButton.isHidden = state.mode != .edit

        let isEditing = state.mode == .edit
        titleTextField.isHidden = true
        titleTextField.isEnabled = false
        placeTitleRow.isHidden = isEditing
        headerTitleTextField.isHidden = !isEditing
        headerTitleTextField.isEnabled = isEditing

        if isEditing, !searchContainerView.isHidden {
            didTapSearchDone()
        }

        if !isEditing, pendingSearchAfterEdit {
            pendingSearchAfterEdit = false
            openSearchUI()
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
        let editTitle = state.mode == .edit ? "Done" : "Edit"
        let editButton = UIBarButtonItem(title: editTitle, style: .plain, target: self, action: #selector(didTapEditToggle))

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
        searchAction.attributes = state.canSearch ? [] : [.disabled]

        let deleteAction = UIAction(title: "Delete Note", image: UIImage(systemName: "trash"), attributes: [.destructive]) { [weak self] _ in
            self?.confirmDelete()
        }
        deleteAction.attributes = state.isDeleteVisible ? [.destructive] : [.disabled, .destructive]

        let menu = UIMenu(title: "", children: [bookmarkAction, searchAction, deleteAction])
        let menuButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease"), menu: menu)

        if state.mode == .edit {
            let doneButton = makeSystemCheckmarkButton()
            navigationItem.rightBarButtonItems = [doneButton, menuButton]
        } else {
            navigationItem.rightBarButtonItems = [menuButton, editButton]
        }
    }

    private func makeSystemCheckmarkButton() -> UIBarButtonItem {
        let image = UIImage(systemName: "checkmark") ?? UIImage()
        let button = UIButton.systemButton(with: image, target: self, action: #selector(didTapEditToggle))
        button.tintColor = .systemBlue
        return UIBarButtonItem(customView: button)
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
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
                self?.pendingSearchAfterEdit = false
            })
            alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
                self?.viewModel.didTapCancelEdit()
            })
            let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
                self?.viewModel.didTapSave()
            }
            saveAction.isEnabled = state.isSaveEnabled
            alert.addAction(saveAction)
            present(alert, animated: true)
        } else {
            viewModel.didTapCancelEdit()
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

    @objc private func titleDidChange() {
        viewModel.didChangeTitle(titleTextField.text)
    }

    @objc private func headerTitleDidChange() {
        viewModel.didChangeHeaderTitle(headerTitleTextField.text)
    }

    @objc private func didTapText() {
        guard let state = lastState, state.mode == .edit else { return }
        textView.becomeFirstResponder()
    }

    @objc private func didTapEditToggle() {
        guard let state = lastState else { return }
        if state.mode == .edit {
            confirmExitEditIfNeeded()
        } else {
            if !searchContainerView.isHidden {
                didTapSearchDone()
            }
            viewModel.didTapEdit()
        }
    }

    @objc private func didTapDate() {
        guard let state = lastState, state.mode == .edit else { return }
        let (initialStart, initialEnd) = parseDateRange(from: state.dateText)
        presentDatePicker(
            title: "From",
            initialDate: initialStart ?? Date()
        ) { [weak self] startDate in
            guard let self else { return }
            self.pendingStartDate = startDate
            self.presentDatePicker(
                title: "To",
                initialDate: initialEnd ?? startDate,
                minimumDate: startDate
            ) { [weak self] endDate in
                guard let self else { return }
                let startText = self.dateFormatter.string(from: self.pendingStartDate ?? startDate)
                let endText = self.dateFormatter.string(from: endDate)
                let rangeText = "\(startText) - \(endText)"
                self.viewModel.didUpdateDateRangeText(rangeText.lowercased())
                self.pendingStartDate = nil
            }
        }
    }

    private func presentDatePicker(title: String, initialDate: Date, minimumDate: Date? = nil, onSave: @escaping (Date) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.date = initialDate
        picker.minimumDate = minimumDate

        alert.view.addSubview(picker)
        picker.snp.makeConstraints { make in
            make.top.equalTo(alert.view.snp.top).offset(56)
            make.leading.trailing.equalTo(alert.view).inset(16)
            make.bottom.equalTo(alert.view.snp.bottom).offset(-72)
        }

        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            onSave(picker.date)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func parseDateRange(from text: String) -> (Date?, Date?) {
        let parts = text.split(separator: "-").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count == 2 else { return (nil, nil) }
        let start = dateFormatter.date(from: parts[0])
        let end = dateFormatter.date(from: parts[1])
        return (start, end)
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

    @objc private func didTapRemoveLocation() {
        guard let state = lastState, state.mode == .edit else { return }
        viewModel.didRemoveLocation()
    }

    @objc private func didTapLocationPill() {}

    @objc private func didTapSearchDone() {
        searchContainerView.isHidden = true
        searchBar.searchTextField.resignFirstResponder()
        searchBar.searchTextField.inputAccessoryView = nil
        searchBar.searchTextField.reloadInputViews()
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
        searchBar.searchTextField.inputAccessoryView = keyboardToolbar
        searchBar.searchTextField.reloadInputViews()
        searchBar.searchTextField.becomeFirstResponder()
        updateSearchNavigationButtons()
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


private extension NoteViewController {
    func loadImages(from urls: [URL]) -> [UIImage] {
        urls.compactMap { url in
            if url.isFileURL {
                return UIImage(contentsOfFile: url.path)
            }
            if let data = try? Data(contentsOf: url) {
                return UIImage(data: data)
            }
            return nil
        }
    }
}
