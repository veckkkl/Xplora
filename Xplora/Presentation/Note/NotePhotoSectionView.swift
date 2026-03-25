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
    var onAddPhoto: (() -> Void)?

    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .system)
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
        let hasPhotos = !state.photoURLs.isEmpty
        isHidden = !state.isEditing && !hasPhotos
        addButton.isHidden = !state.isEditing
        collageView.isHidden = !hasPhotos

        guard hasPhotos else {
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
        titleLabel.text = "Photos"
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.tintColor = .systemBlue
        addButton.addTarget(self, action: #selector(didTapAddPhoto), for: .touchUpInside)

        addSubview(headerView)
        addSubview(collageView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(addButton)

        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(28)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }

        addButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
            make.width.height.equalTo(28)
        }

        collageView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
            collageHeightConstraint = make.height.equalTo(0).constraint
        }

        collageView.onPhotoRemove = { [weak self] index in
            self?.onRemovePhoto?(index)
        }
    }

    @objc private func didTapAddPhoto() {
        onAddPhoto?()
    }
}
