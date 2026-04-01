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

    private let removeHitButton = UIButton(type: .custom)
    private let removeBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let removeIconView = UIImageView()

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
        removeHitButton.isHidden = true
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
        removeHitButton.isHidden = !showRemoveButton

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

        removeHitButton.addTarget(self, action: #selector(didTapRemove), for: .touchUpInside)
        contentView.addSubview(removeHitButton)

        removeHitButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().offset(-4)
            make.size.equalTo(CGSize(width: 34, height: 34))
        }

        removeBackgroundView.clipsToBounds = true
        removeBackgroundView.layer.cornerRadius = 12
        removeBackgroundView.layer.cornerCurve = .continuous
        removeBackgroundView.layer.borderColor = UIColor.separator.withAlphaComponent(0.26).cgColor
        removeBackgroundView.layer.borderWidth = 0.6
        removeHitButton.addSubview(removeBackgroundView)

        removeBackgroundView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }

        removeIconView.image = UIImage(systemName: "xmark")
        removeIconView.tintColor = .label
        removeIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        removeBackgroundView.contentView.addSubview(removeIconView)

        removeIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    @objc private func didTapRemove() {
        onRemove?()
    }
}
