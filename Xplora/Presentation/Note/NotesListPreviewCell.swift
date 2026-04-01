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
    private let titleRow = UIStackView()
    private let titleLabel = UILabel()
    private let titleSpacer = UIView()
    private let bookmarkImageView = UIImageView()
    private let dateLabel = UILabel()
    private let locationChip = UIView()
    private let locationIcon = UIImageView()
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
        previewLabel.text = nil
        previewLabel.isHidden = false
        bookmarkImageView.isHidden = true
        locationChip.isHidden = true
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

        if let chipText = item.locationChipText, !chipText.isEmpty {
            locationLabel.text = chipText
            locationChip.isHidden = false
        } else {
            locationChip.isHidden = true
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
        previewLabel.numberOfLines = hasPhotos ? 2 : 3

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

        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 14
        cardView.layer.cornerCurve = .continuous
        cardView.clipsToBounds = true

        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 6

        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2

        bookmarkImageView.image = UIImage(systemName: "bookmark.fill")
        bookmarkImageView.tintColor = .systemOrange
        bookmarkImageView.isHidden = true

        dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = .secondaryLabel

        locationChip.backgroundColor = UIColor.tertiarySystemFill
        locationChip.layer.cornerRadius = 9
        locationChip.layer.cornerCurve = .continuous
        locationChip.clipsToBounds = true

        locationIcon.image = UIImage(systemName: "mappin.and.ellipse")
        locationIcon.tintColor = .secondaryLabel

        locationLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        locationLabel.textColor = .secondaryLabel
        locationLabel.numberOfLines = 1

        previewLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        previewLabel.textColor = .secondaryLabel
        previewLabel.lineBreakMode = .byTruncatingTail

        collageView.layer.cornerRadius = 10
        collageView.clipsToBounds = true

        contentView.addSubview(cardView)
        cardView.addSubview(contentStack)

        titleRow.addArrangedSubview(titleLabel)
        titleRow.addArrangedSubview(titleSpacer)
        titleRow.addArrangedSubview(bookmarkImageView)

        locationChip.addSubview(locationIcon)
        locationChip.addSubview(locationLabel)

        contentStack.axis = .vertical
        contentStack.spacing = TripPhotoPresentationMetrics.listVerticalSpacing
        contentStack.addArrangedSubview(titleRow)
        contentStack.addArrangedSubview(collageView)
        contentStack.addArrangedSubview(locationChip)
        contentStack.addArrangedSubview(dateLabel)
        contentStack.addArrangedSubview(previewLabel)

        contentStack.setCustomSpacing(TripPhotoPresentationMetrics.listTitleToPhotoSpacing, after: titleRow)
        contentStack.setCustomSpacing(TripPhotoPresentationMetrics.listPhotoToMetadataSpacing, after: collageView)

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

        locationIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 12, height: 12))
        }

        locationLabel.snp.makeConstraints { make in
            make.leading.equalTo(locationIcon.snp.trailing).offset(5)
            make.trailing.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
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
