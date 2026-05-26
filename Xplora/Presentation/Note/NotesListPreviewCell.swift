//
//  NotesListPreviewCell.swift
//  Xplora
//

import SnapKit
import UIKit

final class NotesListPreviewCell: UITableViewCell {
    static let reuseIdentifier = "NotesListPreviewCell"

    private let cardView = UIView()
    private let contentStack = UIStackView()
    private let locationRow = UIStackView()
    private let locationIconView = UIImageView()
    private let titleRow = UIStackView()
    private let titleLabel = UILabel()
    private let titleSpacer = UIView()
    private let bookmarkImageView = UIImageView()
    private let dateLabel = UILabel()
    private let locationLabel = UILabel()
    private let previewLabel = UILabel()
    private let collageView = TripPhotoCollageView()

    private var collageHeightConstraint: Constraint?
    private var hasPhotos = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCollageHeightIfNeeded()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        dateLabel.text = nil
        dateLabel.isHidden = false
        locationLabel.text = nil
        locationLabel.isHidden = false
        locationRow.isHidden = false
        previewLabel.text = nil
        previewLabel.isHidden = false
        bookmarkImageView.isHidden = true
        collageView.isHidden = true
        hasPhotos = false
    }

    func configure(with item: NotesListItemViewState) {
        titleLabel.text = item.title
        bookmarkImageView.isHidden = !item.isBookmarked

        let trimmedDate = item.dateText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDate.isEmpty {
            dateLabel.isHidden = true
            dateLabel.text = nil
        } else {
            dateLabel.isHidden = false
            dateLabel.text = trimmedDate
        }

        if let locationText = item.locationChipText?.trimmingCharacters(in: .whitespacesAndNewlines), !locationText.isEmpty {
            locationLabel.text = locationText
            locationRow.isHidden = false
        } else {
            locationRow.isHidden = true
            locationLabel.text = nil
        }

        if item.textPreview.isEmpty {
            previewLabel.isHidden = true
            previewLabel.text = nil
        } else {
            previewLabel.isHidden = false
            previewLabel.text = item.textPreview
        }

        hasPhotos = !item.photoURLs.isEmpty
        collageView.isHidden = !hasPhotos

        if hasPhotos {
            collageView.configure(urls: item.photoURLs, mode: .preview)
        }

        updateCollageHeightIfNeeded()
    }

    private func setupView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)

        let selectedBackground = UIView()
        selectedBackground.backgroundColor = .clear
        selectedBackgroundView = selectedBackground

        cardView.backgroundColor = .secondarySystemGroupedBackground
        cardView.layer.cornerRadius = 16
        cardView.layer.cornerCurve = .continuous
        cardView.layer.borderWidth = 0.6
        cardView.layer.borderColor = UIColor.separator.withAlphaComponent(0.22).cgColor
        cardView.clipsToBounds = true

        locationRow.axis = .horizontal
        locationRow.alignment = .center
        locationRow.spacing = 8

        locationIconView.image = UIImage(systemName: "mappin.and.ellipse")
        locationIconView.tintColor = .secondaryLabel

        titleRow.axis = .horizontal
        titleRow.alignment = .firstBaseline
        titleRow.spacing = 6

        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail

        bookmarkImageView.image = UIImage(systemName: "bookmark.fill")
        bookmarkImageView.tintColor = .systemOrange
        bookmarkImageView.isHidden = true
        bookmarkImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        locationLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        locationLabel.textColor = .label
        locationLabel.numberOfLines = 1

        previewLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 2
        previewLabel.lineBreakMode = .byTruncatingTail

        dateLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        dateLabel.textColor = .tertiaryLabel

        collageView.layer.cornerRadius = 12
        collageView.clipsToBounds = true

        contentView.addSubview(cardView)
        cardView.addSubview(contentStack)

        locationRow.addArrangedSubview(locationIconView)
        locationRow.addArrangedSubview(locationLabel)

        titleRow.addArrangedSubview(titleLabel)
        titleRow.addArrangedSubview(titleSpacer)
        titleRow.addArrangedSubview(bookmarkImageView)

        contentStack.axis = .vertical
        contentStack.spacing = TripPhotoPresentationMetrics.listVerticalSpacing
        contentStack.addArrangedSubview(collageView)
        contentStack.addArrangedSubview(locationRow)
        contentStack.addArrangedSubview(titleRow)
        contentStack.addArrangedSubview(previewLabel)
        contentStack.addArrangedSubview(dateLabel)

        contentStack.setCustomSpacing(TripPhotoPresentationMetrics.listPhotoToLocationSpacing, after: collageView)
        contentStack.setCustomSpacing(TripPhotoPresentationMetrics.listTitleToPreviewSpacing, after: titleRow)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(TripPhotoPresentationMetrics.listCardVerticalInset)
            make.bottom.equalToSuperview().offset(-TripPhotoPresentationMetrics.listCardVerticalInset)
            make.leading.trailing.equalToSuperview().inset(TripPhotoPresentationMetrics.listCardHorizontalInset)
        }

        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(TripPhotoPresentationMetrics.listContentInset)
        }

        bookmarkImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 15, height: 15))
        }

        locationIconView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        collageView.snp.makeConstraints { make in
            collageHeightConstraint = make.height.equalTo(0).constraint
        }
    }

    private func updateCollageHeightIfNeeded() {
        guard hasPhotos else {
            collageHeightConstraint?.update(offset: 0)
            return
        }

        let width: CGFloat
        if collageView.bounds.width > 0 {
            width = collageView.bounds.width
        } else {
            let horizontalInset = (TripPhotoPresentationMetrics.listCardHorizontalInset + TripPhotoPresentationMetrics.listContentInset) * 2
            width = max(0, contentView.bounds.width - horizontalInset)
        }

        let baseHeight = collageView.preferredHeight(forWidth: width)
        let scaledHeight = baseHeight * TripPhotoPresentationMetrics.listCollageHeightScale
        let finalHeight = max(
            TripPhotoPresentationMetrics.listCollageMinHeight,
            min(TripPhotoPresentationMetrics.listCollageMaxHeight, scaledHeight)
        )
        collageHeightConstraint?.update(offset: finalHeight)
    }
}
