//
//  NoteTextSearchController.swift
//  Xplora
//

import SnapKit
import UIKit

/// Owns the in-note text-search UI: the search bar that slides up over the
/// scroll content, the keyboard accessory toolbar with previous / next /
/// done items, and the match-traversal state on top of
/// `NoteTextHighlighter`.
///
/// The view controller retains the controller strongly and exposes its
/// containing view + the editable text view at mount time. Keyboard
/// adjustments and edit-mode transitions are coordinated through a small
/// public API (`isVisible`, `searchBarHeight`, `setSearchBarBottomOffset`,
/// `open`, `close`, `refresh`).
final class NoteTextSearchController: NSObject {
    /// Invoked after the controller hides the search UI so the view
    /// controller can restore scroll insets / layout.
    var onClose: (() -> Void)?

    weak var parentView: UIView?
    weak var textView: UITextView?

    private(set) var isVisible = false

    private var currentSearchQuery: String = ""
    private var searchMatches: [NSRange] = []
    private var currentMatchIndex: Int = 0

    private let searchContainerView = UIView()
    private let searchBar = UISearchBar()
    private let keyboardToolbar = UIToolbar()
    private var searchContainerBottomConstraint: Constraint?
    private var toolbarPrevItem: UIBarButtonItem?
    private var toolbarNextItem: UIBarButtonItem?
    private var toolbarDoneItem: UIBarButtonItem?

    /// Height (44 + 8) reserved for the visible search container, used by
    /// the keyboard handler to compute scroll insets. Returns `0` while the
    /// search UI is hidden.
    var searchBarHeight: CGFloat {
        isVisible ? 52 : 0
    }

    /// Sets the bottom offset of the search container; called from the
    /// keyboard handler when the keyboard appears or disappears.
    func setSearchBarBottomOffset(_ offset: CGFloat) {
        searchContainerBottomConstraint?.update(offset: -offset)
    }

    func open() {
        guard let parentView else { return }
        if searchContainerView.superview == nil {
            mountUI(into: parentView)
        }
        searchContainerView.isHidden = false
        isVisible = true
        searchBar.searchTextField.becomeFirstResponder()
        updateSearchNavigationButtons()
    }

    func close() {
        searchContainerView.isHidden = true
        isVisible = false
        searchBar.searchTextField.resignFirstResponder()
        applyHighlight(text: textView?.text ?? "", query: "")
        updateSearchNavigationButtons()
        onClose?()
    }

    /// Re-applies the current search query against new text. Called when
    /// the displayed text is updated externally (e.g. state change in view
    /// mode).
    func refresh(text: String) {
        applyHighlight(text: text, query: currentSearchQuery)
    }

    // MARK: - Highlight orchestration

    private func applyHighlight(text: String, query: String) {
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
        textView?.attributedText = result.attributedText

        if query.isEmpty {
            currentMatchIndex = 0
        } else if !result.matches.isEmpty {
            currentMatchIndex = min(currentMatchIndex, result.matches.count - 1)
            textView?.scrollRangeToVisible(result.matches[currentMatchIndex])
        }
        updateSearchNavigationButtons()
    }

    // MARK: - UI setup (lazy on first open)

    private func mountUI(into parentView: UIView) {
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

        configureToolbar(parentView: parentView)
        textField.inputAccessoryView = keyboardToolbar

        parentView.addSubview(searchContainerView)
        searchContainerView.addSubview(searchBar)

        searchContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(parentView.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(44)
            searchContainerBottomConstraint = make.bottom.equalTo(parentView.safeAreaLayoutGuide).offset(-8).constraint
        }

        searchBar.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }

    private func configureToolbar(parentView: UIView) {
        if toolbarPrevItem == nil {
            toolbarPrevItem = UIBarButtonItem(
                image: UIImage(systemName: "chevron.up"),
                style: .plain,
                target: self,
                action: #selector(didTapPrev)
            )
            toolbarPrevItem?.tintColor = .secondaryLabel
        }

        if toolbarNextItem == nil {
            toolbarNextItem = UIBarButtonItem(
                image: UIImage(systemName: "chevron.down"),
                style: .plain,
                target: self,
                action: #selector(didTapNext)
            )
            toolbarNextItem?.tintColor = .secondaryLabel
        }

        if toolbarDoneItem == nil {
            toolbarDoneItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(didTapDone)
            )
        }

        keyboardToolbar.sizeToFit()
        keyboardToolbar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        keyboardToolbar.frame.size.width = parentView.bounds.width
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        keyboardToolbar.items = [toolbarPrevItem, toolbarNextItem, spacer, toolbarDoneItem].compactMap { $0 }
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

    // MARK: - Toolbar actions

    @objc private func didTapPrev() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = max(0, currentMatchIndex - 1)
        applyHighlight(text: textView?.text ?? "", query: currentSearchQuery)
    }

    @objc private func didTapNext() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = min(searchMatches.count - 1, currentMatchIndex + 1)
        applyHighlight(text: textView?.text ?? "", query: currentSearchQuery)
    }

    @objc private func didTapDone() {
        close()
    }
}

extension NoteTextSearchController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        currentMatchIndex = 0
        applyHighlight(text: textView?.text ?? "", query: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.searchTextField.resignFirstResponder()
    }
}
