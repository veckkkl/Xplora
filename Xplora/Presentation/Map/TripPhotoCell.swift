//
//  TripPhotoCell.swift
//  Xplora


import SnapKit
import UIKit

final class TripPhotoCell: UICollectionViewCell {
    static let reuseIdentifier = "TripPhotoCell"

    private let imageView = UIImageView()
    private let overflowOverlayView = UIView()
    private let overflowLabel = UILabel()
    private let removeButton = NoteCircularRemoveButton(iconSize: 28)

    private var onRemove: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        overflowOverlayView.isHidden = true
        overflowLabel.text = nil
        removeButton.isHidden = true
        onRemove = nil
    }

    func configure(
        image: UIImage?,
        showRemoveButton: Bool = false,
        overflowCount: Int? = nil,
        onRemove: (() -> Void)? = nil
    ) {
        imageView.image = image
        self.onRemove = onRemove
        removeButton.isHidden = !showRemoveButton

        if let overflowCount, overflowCount > 0 {
            overflowLabel.text = "+\(overflowCount)"
            overflowOverlayView.isHidden = false
        } else {
            overflowOverlayView.isHidden = true
            overflowLabel.text = nil
        }
    }

    private func setupView() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 7
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        overflowOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.34)
        overflowOverlayView.isHidden = true
        contentView.addSubview(overflowOverlayView)

        overflowOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        overflowLabel.font = UIFont.systemFont(ofSize: 21, weight: .semibold)
        overflowLabel.textColor = .white
        overflowLabel.textAlignment = .center
        overflowOverlayView.addSubview(overflowLabel)

        overflowLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        removeButton.addTarget(self, action: #selector(didTapRemove), for: .touchUpInside)
        contentView.addSubview(removeButton)

        // 44×44 hit area pinned to the top-trailing corner; the visible icon
        // is nudged 6pt away from the edges so it sits like the native iOS
        // attachment cross.
        removeButton.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.trailing.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        removeButton.placeIcon(insetFromTop: 6, insetFromTrailing: 6)
    }

    @objc private func didTapRemove() {
        onRemove?()
    }
}
