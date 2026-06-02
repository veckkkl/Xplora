//
//  TripAddPhotoCell.swift
//  Xplora
//

import SnapKit
import UIKit

/// "Add photo" cell that takes the spot of an extra tile inside the collage
/// grid. Visually it's a single SF Symbol on a `secondarySystemBackground`
/// tile — relies entirely on system materials so it adapts to dark mode and
/// matches the look of the photo cells around it. Disabled state is rendered
/// with a tertiary tint so the limit-reached situation reads cleanly.
final class TripAddPhotoCell: UICollectionViewCell {
    static let reuseIdentifier = "TripAddPhotoCell"

    private let iconView = UIImageView()
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private var isAddEnabled = true

    var onTap: (() -> Void)?

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
        onTap = nil
        isAddEnabled = true
        applyEnabledStyling()
    }

    func configure(isEnabled: Bool, onTap: (() -> Void)?) {
        self.onTap = onTap
        self.isAddEnabled = isEnabled
        applyEnabledStyling()
    }

    private func setupView() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 7
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true

        iconView.image = UIImage(
            systemName: "plus",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        )
        iconView.contentMode = .center
        iconView.isUserInteractionEnabled = false
        contentView.addSubview(iconView)

        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        contentView.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        contentView.addGestureRecognizer(tapRecognizer)
        feedbackGenerator.prepare()

        applyEnabledStyling()
    }

    private func applyEnabledStyling() {
        iconView.tintColor = isAddEnabled ? .label : .tertiaryLabel
        contentView.isUserInteractionEnabled = isAddEnabled
    }

    @objc private func handleTap() {
        guard isAddEnabled else { return }
        animatePress()
        feedbackGenerator.impactOccurred()
        feedbackGenerator.prepare()
        onTap?()
    }

    private func animatePress() {
        UIView.animate(
            withDuration: 0.1,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.iconView.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        } completion: { _ in
            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                usingSpringWithDamping: 0.62,
                initialSpringVelocity: 0.35,
                options: [.allowUserInteraction]
            ) {
                self.iconView.transform = .identity
            }
        }
    }
}
