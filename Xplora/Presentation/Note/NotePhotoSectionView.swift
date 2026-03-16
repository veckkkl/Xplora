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
    }

    var onRemovePhoto: ((Int) -> Void)?

    private let collageView = TripPhotoCollageView()
    private var collageHeightConstraint: Constraint?
    private var currentState = State(photoURLs: [], isEditing: false)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ state: State) {
        currentState = state
        isHidden = state.photoURLs.isEmpty

        guard !state.photoURLs.isEmpty else {
            collageHeightConstraint?.update(offset: 0)
            return
        }

        collageView.configure(urls: state.photoURLs, showRemoveButton: state.isEditing)

        // Use available width to keep collage height self-contained in this section.
        let width = collageView.bounds.width > 0 ? collageView.bounds.width : UIScreen.main.bounds.width - 40
        let height = collageView.preferredHeight(forWidth: width)
        collageHeightConstraint?.update(offset: height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !currentState.photoURLs.isEmpty else { return }
        let width = collageView.bounds.width > 0 ? collageView.bounds.width : bounds.width
        let height = collageView.preferredHeight(forWidth: width)
        collageHeightConstraint?.update(offset: height)
    }

    private func setupLayout() {
        addSubview(collageView)

        collageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            collageHeightConstraint = make.height.equalTo(0).constraint
        }

        collageView.onPhotoRemove = { [weak self] index in
            self?.onRemovePhoto?(index)
        }
    }
}
