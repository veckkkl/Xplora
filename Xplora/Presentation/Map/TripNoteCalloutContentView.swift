//
//  TripNoteCalloutContentView.swift
//  Xplora
//

import SnapKit
import UIKit

final class TripNoteCalloutContentView: UIView {
    private let collageView = TripPhotoCollageView()
    private var collageHeightConstraint: Constraint?
    private var collageZeroConstraint: Constraint?
    private var collageTopConstraint: Constraint?
    private var infoTopConstraint: Constraint?
    private var currentPhotoURLs: [URL] = []

    private let titleRow = UIStackView()
    private let titleLabel = UILabel()
    private let bookmarkImageView = UIImageView()
    private let dateLabel = UILabel()
    private let placeCapsule = UIView()
    private let placeIcon = UIImageView()
    private let placeLabel = UILabel()
    private let previewLabel = UILabel()

    private let infoStack: UIStackView

    override init(frame: CGRect) {
        infoStack = UIStackView()
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        infoStack = UIStackView()
        super.init(coder: coder)
        setupView()
    }

    func configure(with viewModel: TripNotePreviewViewModel) {
        titleLabel.text = viewModel.title
        bookmarkImageView.isHidden = !viewModel.isBookmarked
        dateLabel.text = viewModel.dateRange
        previewLabel.text = viewModel.textPreview

        currentPhotoURLs = viewModel.photoURLs
        let hasPhotos = !viewModel.photoURLs.isEmpty
        collageView.isHidden = !hasPhotos
        collageView.configure(urls: viewModel.photoURLs, mode: .preview)

        if hasPhotos {
            collageZeroConstraint?.deactivate()
            collageHeightConstraint?.activate()
            updateCollageHeightIfNeeded()
        } else {
            collageHeightConstraint?.deactivate()
            collageZeroConstraint?.activate()
        }
        collageTopConstraint?.update(offset: hasPhotos ? 0 : 8)
        infoTopConstraint?.update(offset: hasPhotos ? 8 : 0)

        if let placeTitle = viewModel.locationChipText ?? viewModel.placeTitle, !placeTitle.isEmpty {
            placeLabel.text = placeTitle
            placeCapsule.isHidden = false
        } else {
            placeCapsule.isHidden = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCollageHeightIfNeeded()
    }

    private func setupView() {
        backgroundColor = .clear

        collageView.layer.cornerRadius = 12
        collageView.clipsToBounds = true

        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 6

        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        bookmarkImageView.image = UIImage(systemName: "bookmark.fill")
        bookmarkImageView.tintColor = .systemOrange
        bookmarkImageView.contentMode = .scaleAspectFit
        bookmarkImageView.isHidden = true
        bookmarkImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        dateLabel.textColor = .secondaryLabel

        placeCapsule.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.9)
        placeCapsule.layer.cornerRadius = 12
        placeCapsule.clipsToBounds = true
        placeCapsule.setContentCompressionResistancePriority(.required, for: .vertical)
        placeCapsule.setContentHuggingPriority(.required, for: .vertical)

        placeIcon.image = UIImage(systemName: "mappin.and.ellipse")
        placeIcon.tintColor = .secondaryLabel

        placeLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        placeLabel.textColor = .label
        placeLabel.numberOfLines = 1
        placeLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        previewLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 3
        previewLabel.lineBreakMode = .byTruncatingTail
        previewLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        previewLabel.setContentHuggingPriority(.defaultLow, for: .vertical)

        infoStack.axis = .vertical
        infoStack.spacing = 4
        titleRow.addArrangedSubview(titleLabel)
        titleRow.addArrangedSubview(bookmarkImageView)
        infoStack.addArrangedSubview(titleRow)
        infoStack.addArrangedSubview(dateLabel)
        infoStack.addArrangedSubview(placeCapsule)
        infoStack.addArrangedSubview(previewLabel)

        placeCapsule.addSubview(placeIcon)
        placeCapsule.addSubview(placeLabel)

        bookmarkImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        addSubview(collageView)
        addSubview(infoStack)

        collageView.snp.makeConstraints { make in
            collageTopConstraint = make.top.equalToSuperview().constraint
            make.leading.trailing.equalToSuperview()
            collageHeightConstraint = make.height.equalTo(0).constraint
            collageZeroConstraint = make.height.equalTo(0).constraint
        }
        collageZeroConstraint?.deactivate()

        infoStack.snp.makeConstraints { make in
            infoTopConstraint = make.top.equalTo(collageView.snp.bottom).offset(8).constraint
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-8)
        }

        placeIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 14, height: 14))
        }

        placeLabel.snp.makeConstraints { make in
            make.leading.equalTo(placeIcon.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    private func updateCollageHeightIfNeeded() {
        guard !currentPhotoURLs.isEmpty else { return }
        let availableWidth = bounds.width
        guard availableWidth > 0 else { return }
        let height = collageView.preferredHeight(forWidth: availableWidth)
        collageHeightConstraint?.update(offset: height)
    }
}
