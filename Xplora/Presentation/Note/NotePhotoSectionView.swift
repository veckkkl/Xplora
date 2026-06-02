//
//  NotePhotoSectionView.swift
//  Xplora
//

import SnapKit
import UIKit

final class NotePhotoSectionView: UIView {
    struct State {
        let photoURLs: [URL]
        let isEditing: Bool
        let canAddPhoto: Bool
    }

    var onRemovePhoto: ((Int) -> Void)?
    var onAddPhoto: (() -> Void)?

    private let collageContainer = UIView()
    private let collageView = TripPhotoCollageView()
    private let emptyPlaceholderControl = UIControl()
    private let emptyPlaceholderIcon = UIImageView()

    private var collageHeightConstraint: Constraint?
    private var collageWidthConstraint: Constraint?
    private var placeholderHeightConstraint: Constraint?
    private var placeholderWidthConstraint: Constraint?
    private var sectionHeightConstraint: Constraint?

    private var currentState = State(photoURLs: [], isEditing: false, canAddPhoto: true)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ state: State) {
        currentState = state

        let hasPhotos = !state.photoURLs.isEmpty
        isHidden = !state.isEditing && !hasPhotos

        collageContainer.isHidden = !hasPhotos
        emptyPlaceholderControl.isHidden = !(state.isEditing && !hasPhotos)

        if hasPhotos {
            collageView.configure(
                urls: state.photoURLs,
                showRemoveButton: state.isEditing,
                // When editing and not at the photo cap, append a "+" tile so
                // the grid grows from n to n+1; once the cap is reached we
                // simply drop the placeholder — matching how iOS Photos hides
                // the add affordance at the limit.
                showAddPlaceholder: state.isEditing && state.canAddPhoto,
                mode: .noteFull
            )
        }

        updateLayoutMetrics()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayoutMetrics()
    }

    private func setupLayout() {
        collageContainer.backgroundColor = .clear

        emptyPlaceholderControl.backgroundColor = .secondarySystemBackground
        emptyPlaceholderControl.layer.cornerRadius = 16
        emptyPlaceholderControl.layer.cornerCurve = .continuous
        emptyPlaceholderControl.clipsToBounds = true
        emptyPlaceholderControl.addTarget(self, action: #selector(didTapAddPhoto), for: .touchUpInside)

        emptyPlaceholderIcon.image = UIImage(systemName: "plus")
        emptyPlaceholderIcon.tintColor = .tertiaryLabel
        emptyPlaceholderIcon.contentMode = .scaleAspectFit
        emptyPlaceholderIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 42, weight: .regular)

        addSubview(collageContainer)
        collageContainer.addSubview(collageView)

        addSubview(emptyPlaceholderControl)
        emptyPlaceholderControl.addSubview(emptyPlaceholderIcon)

        collageContainer.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            collageHeightConstraint = make.height.equalTo(0).constraint
            collageWidthConstraint = make.width.equalTo(0).constraint
        }

        collageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        emptyPlaceholderControl.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            placeholderHeightConstraint = make.height.equalTo(0).constraint
            placeholderWidthConstraint = make.width.equalTo(0).constraint
        }

        snp.makeConstraints { make in
            sectionHeightConstraint = make.height.equalTo(0).constraint
        }

        emptyPlaceholderIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 44))
        }

        collageView.onPhotoRemove = { [weak self] index in
            self?.onRemovePhoto?(index)
        }
        collageView.onAddPhoto = { [weak self] in
            self?.onAddPhoto?()
        }
    }

    private func updateLayoutMetrics() {
        let width = availableWidth
        guard width > 0 else { return }

        let hasPhotos = !currentState.photoURLs.isEmpty

        if hasPhotos {
            let collageWidth = TripPhotoPresentationMetrics.noteCollageWidthPolicy.resolvedWidth(for: width)
            collageWidthConstraint?.update(offset: collageWidth)
            let baseHeight = collageView.preferredHeight(forWidth: collageWidth)
            let scaledHeight = baseHeight * TripPhotoPresentationMetrics.noteCollageHeightScale
            let maxHeight = collageWidth * TripPhotoPresentationMetrics.noteCollageMaxHeightRatio
            let collageHeight = max(
                TripPhotoPresentationMetrics.noteCollageMinHeight,
                min(scaledHeight, maxHeight)
            )
            collageHeightConstraint?.update(offset: collageHeight)
            sectionHeightConstraint?.update(offset: collageHeight)
            placeholderWidthConstraint?.update(offset: 0)
            placeholderHeightConstraint?.update(offset: 0)
            return
        }

        if currentState.isEditing {
            let placeholderWidth = TripPhotoPresentationMetrics.notePlaceholderWidthPolicy.resolvedWidth(for: width)
            let placeholderHeight = max(
                TripPhotoPresentationMetrics.notePlaceholderMinHeight,
                placeholderWidth * TripPhotoPresentationMetrics.notePlaceholderHeightRatio
            )
            placeholderWidthConstraint?.update(offset: placeholderWidth)
            placeholderHeightConstraint?.update(offset: placeholderHeight)
            sectionHeightConstraint?.update(offset: placeholderHeight)
            collageWidthConstraint?.update(offset: 0)
            collageHeightConstraint?.update(offset: 0)
            return
        }

        collageWidthConstraint?.update(offset: 0)
        collageHeightConstraint?.update(offset: 0)
        placeholderWidthConstraint?.update(offset: 0)
        placeholderHeightConstraint?.update(offset: 0)
        sectionHeightConstraint?.update(offset: 0)
    }

    private var availableWidth: CGFloat {
        if bounds.width > 0 {
            return bounds.width
        }
        return max(0, UIScreen.main.bounds.width - 40)
    }

    @objc private func didTapAddPhoto() {
        onAddPhoto?()
    }
}
