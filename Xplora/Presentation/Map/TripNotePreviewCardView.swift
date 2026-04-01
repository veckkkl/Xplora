//
//  TripNotePreviewCardView.swift
//  Xplora

import SnapKit
import UIKit

final class TripNotePreviewCardView: UIView {
    enum Style {
        case overlay
        case callout
    }

    enum PresentationState {
        case hidden
        case visible
    }

    private let shadowContainer = UIView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let glassOverlayView = UIView()
    private let collageView = TripPhotoCollageView()
    private var collageHeightConstraint: Constraint?
    private var collageZeroConstraint: Constraint?
    private var collageTopConstraint: Constraint?
    private var collageLeadingConstraint: Constraint?
    private var collageTrailingConstraint: Constraint?
    private var infoTopConstraint: Constraint?
    private var infoLeadingConstraint: Constraint?
    private var infoTrailingConstraint: Constraint?
    private var infoBottomConstraint: Constraint?
    private let titleRow = UIStackView()
    private let titleLabel = UILabel()
    private let bookmarkImageView = UIImageView()
    private let dateLabel = UILabel()
    private let placeCapsule = UIView()
    private let placeIcon = UIImageView()
    private let placeLabel = UILabel()
    private let previewLabel = UILabel()
    private var style: Style = .overlay
    private var currentPhotoURLs: [URL] = []
    private var currentCollageHorizontalInset: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        applyStyle(.overlay)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        applyStyle(.overlay)
    }

    func configure(with viewModel: TripNotePreviewViewModel) {
        titleLabel.text = viewModel.title
        bookmarkImageView.isHidden = !viewModel.isBookmarked
        dateLabel.text = viewModel.dateRange
        previewLabel.text = viewModel.textPreview
        currentPhotoURLs = viewModel.photoURLs
        collageView.configure(urls: viewModel.photoURLs, mode: .preview)
        let hasPhotos = !viewModel.photoURLs.isEmpty
        collageView.isHidden = !hasPhotos
        if hasPhotos {
            collageZeroConstraint?.deactivate()
            collageHeightConstraint?.activate()
            updateCollageHeightIfNeeded()
        } else {
            collageHeightConstraint?.deactivate()
            collageZeroConstraint?.activate()
        }
        if let placeTitle = viewModel.locationChipText ?? viewModel.placeTitle, !placeTitle.isEmpty {
            placeLabel.text = placeTitle
            placeCapsule.isHidden = false
        } else {
            placeCapsule.isHidden = true
        }
    }

    func applyPresentationState(_ state: PresentationState) {
        switch state {
        case .hidden:
            alpha = 0
            transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            isHidden = true
        case .visible:
            isHidden = false
            alpha = 1
            transform = .identity
        }
    }

    func applyStyle(_ style: Style) {
        self.style = style
        switch style {
        case .overlay:
            shadowContainer.layer.shadowOpacity = 0.15
            shadowContainer.layer.shadowRadius = 18
            shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
            blurView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
            glassOverlayView.isHidden = false
            blurView.backgroundColor = .clear
            blurView.layer.cornerRadius = 20
            updateContentInsets(
                collageTop: 0,
                collageSide: 0,
                infoTop: 12,
                infoSide: 14,
                infoBottom: 14
            )
        case .callout:
            shadowContainer.layer.shadowOpacity = 0
            shadowContainer.layer.shadowRadius = 0
            shadowContainer.layer.shadowOffset = .zero
            blurView.effect = nil
            glassOverlayView.isHidden = true
            blurView.backgroundColor = .clear
            blurView.layer.cornerRadius = 20
            updateContentInsets(
                collageTop: 9,
                collageSide: 9,
                infoTop: 9,
                infoSide: 9,
                infoBottom: 9
            )
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCollageHeightIfNeeded()
    }


    private func setupView() {
        backgroundColor = .clear
        collageView.layer.cornerRadius = 12
        setupShadowContainer()
        setupBlurView()
        setupLabels()
        setupPlaceCapsule()

        let infoStack = buildInfoStack()
        blurView.contentView.addSubview(collageView)
        blurView.contentView.addSubview(infoStack)
        placeCapsule.addSubview(placeIcon)
        placeCapsule.addSubview(placeLabel)

        activateConstraints(infoStack: infoStack)


    }

    private func setupShadowContainer() {
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOpacity = 0.15
        shadowContainer.layer.shadowRadius = 18
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        addSubview(shadowContainer)
    }

    private func setupBlurView() {
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        shadowContainer.addSubview(blurView)

        glassOverlayView.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        glassOverlayView.isUserInteractionEnabled = false
        blurView.contentView.addSubview(glassOverlayView)
    }

    private func setupLabels() {
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 8

        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
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

        previewLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 3
        previewLabel.lineBreakMode = .byTruncatingTail
        previewLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        previewLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    private func setupPlaceCapsule() {
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
    }

    private func buildInfoStack() -> UIStackView {
        titleRow.addArrangedSubview(titleLabel)
        titleRow.addArrangedSubview(bookmarkImageView)

        bookmarkImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 18, height: 18))
        }

        let infoStack = UIStackView(arrangedSubviews: [titleRow, dateLabel, placeCapsule, previewLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 8
        return infoStack
    }

    private func activateConstraints(infoStack: UIStackView) {
        shadowContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        glassOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        collageView.snp.makeConstraints { make in
            collageTopConstraint = make.top.equalToSuperview().constraint
            collageLeadingConstraint = make.leading.equalToSuperview().constraint
            collageTrailingConstraint = make.trailing.equalToSuperview().constraint
            collageHeightConstraint = make.height.equalTo(0).constraint
            collageZeroConstraint = make.height.equalTo(0).constraint
        }
        collageZeroConstraint?.deactivate()

        infoStack.snp.makeConstraints { make in
            infoTopConstraint = make.top.equalTo(collageView.snp.bottom).constraint
            infoLeadingConstraint = make.leading.equalToSuperview().constraint
            infoTrailingConstraint = make.trailing.equalToSuperview().constraint
            infoBottomConstraint = make.bottom.equalToSuperview().constraint
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

    private func updateContentInsets(
        collageTop: CGFloat,
        collageSide: CGFloat,
        infoTop: CGFloat,
        infoSide: CGFloat,
        infoBottom: CGFloat
    ) {
        collageTopConstraint?.update(offset: collageTop)
        collageLeadingConstraint?.update(offset: collageSide)
        collageTrailingConstraint?.update(offset: -collageSide)
        currentCollageHorizontalInset = collageSide
        infoTopConstraint?.update(offset: infoTop)
        infoLeadingConstraint?.update(offset: infoSide)
        infoTrailingConstraint?.update(offset: -infoSide)
        infoBottomConstraint?.update(offset: -infoBottom)
        layoutIfNeeded()
    }

    private func updateCollageHeightIfNeeded() {
        guard !currentPhotoURLs.isEmpty else { return }
        let availableWidth = bounds.width - (currentCollageHorizontalInset * 2)
        guard availableWidth > 0 else { return }
        let height = collageView.preferredHeight(forWidth: availableWidth)
        collageHeightConstraint?.update(offset: height)
    }
}
