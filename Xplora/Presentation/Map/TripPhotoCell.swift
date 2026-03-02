//
//  TripPhotoCell.swift
//  Xplora


import SnapKit
import UIKit

final class TripPhotoCell: UICollectionViewCell {
    static let reuseIdentifier = "TripPhotoCell"

    private let imageView = UIImageView()
    private let removeButton = UIButton(type: .system)
    private let overflowOverlayView = UIView()
    private let overflowLabel = UILabel()
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
        contentView.layer.cornerRadius = 2
        contentView.clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        overflowOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        overflowOverlayView.isHidden = true
        contentView.addSubview(overflowOverlayView)

        overflowOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        overflowLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        overflowLabel.textColor = .white
        overflowLabel.textAlignment = .center
        overflowOverlayView.addSubview(overflowLabel)

        overflowLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeButton.tintColor = UIColor.black.withAlphaComponent(0.55)
        removeButton.backgroundColor = .clear
        removeButton.addTarget(self, action: #selector(didTapRemove), for: .touchUpInside)
        contentView.addSubview(removeButton)

        removeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.trailing.equalToSuperview().offset(-6)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
    }

    @objc private func didTapRemove() {
        onRemove?()
    }
}
