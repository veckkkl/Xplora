//
//  NoteEditorContentView.swift
//  Xplora
//

import SnapKit
import UIKit

/// Scrollable container that lays out the note editor's body:
/// the place-title row, header title field, photo & location sections, the
/// trip-date label and the rich-text editor with its placeholder.
///
/// Style configuration and constraints are set up at init time. Delegates,
/// gesture recognizers, target-action wiring and state-driven mutations are
/// the view controller's responsibility — the view exposes its content
/// subviews so the controller can read and update them directly.
final class NoteEditorContentView: UIView {
    // MARK: - Scroll infrastructure

    let scrollView = UIScrollView()
    private let scrollContentView = UIView()
    private let stackView = UIStackView()

    // MARK: - Header

    let placeTitleRow = UIStackView()
    let placeTitleLabel = UILabel()
    let placeTitleBookmarkImageView = UIImageView()
    let headerTitleTextField = UITextField()

    // MARK: - Sections

    let photoSectionView = NotePhotoSectionView()
    let locationSectionView = NoteLocationSectionView()

    // MARK: - Date

    let separatorAboveDate = UIView()
    let dateLabel = UILabel()

    // MARK: - Body text

    let separatorAboveText = UIView()
    let textView = UITextView()
    let textPlaceholderLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        buildHierarchy()
        installConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func configureSubviews() {
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

        placeTitleBookmarkImageView.image = UIImage(systemName: SystemSymbol.bookmarkFill)
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
        textView.isScrollEnabled = false

        textPlaceholderLabel.text = L10n.Notes.Editor.Text.placeholder
        textPlaceholderLabel.textColor = .tertiaryLabel
        textPlaceholderLabel.font = UIFont.preferredFont(forTextStyle: .body)

        separatorAboveDate.backgroundColor = .separator
        separatorAboveText.backgroundColor = .separator
    }

    private func buildHierarchy() {
        addSubview(scrollView)
        scrollView.addSubview(scrollContentView)
        scrollContentView.addSubview(stackView)

        textView.addSubview(textPlaceholderLabel)

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
    }

    private func installConstraints() {
        textPlaceholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
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
            make.edges.equalToSuperview()
        }

        scrollContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-24)
        }
    }
}
