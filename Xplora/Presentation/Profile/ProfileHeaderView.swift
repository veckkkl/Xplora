//
//  ProfileHeaderView.swift
//  Xplora
//

import SnapKit
import UIKit

final class ProfileHeaderView: UIControl {
    private let avatarContainerView = UIView()
    private let avatarLabel = UILabel()
    private let textStackView = UIStackView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevronImageView = UIImageView()
    private let highlightOverlayView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: ProfileCardItem) {
        avatarLabel.text = item.initials
        nameLabel.text = item.name
        subtitleLabel.text = item.subtitle
        accessibilityLabel = "\(item.name), \(item.subtitle)"
    }

    override var isHighlighted: Bool {
        didSet {
            let animations = {
                self.highlightOverlayView.alpha = self.isHighlighted ? 1 : 0
            }
            UIView.animate(withDuration: 0.16, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: animations)
        }
    }

    private func setupUI() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 24
        layer.cornerCurve = .continuous
        clipsToBounds = true

        accessibilityTraits = [.button]

        avatarContainerView.backgroundColor = .tertiarySystemGroupedBackground
        avatarContainerView.layer.cornerRadius = 28
        avatarContainerView.layer.cornerCurve = .continuous

        avatarLabel.font = UIFont.systemFont(ofSize: 21, weight: .semibold)
        avatarLabel.textColor = .label
        avatarLabel.textAlignment = .center

        textStackView.axis = .vertical
        textStackView.alignment = .leading
        textStackView.spacing = 3

        nameLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1

        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1

        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .tertiaryLabel
        chevronImageView.contentMode = .scaleAspectFit

        highlightOverlayView.backgroundColor = UIColor.systemFill.withAlphaComponent(0.42)
        highlightOverlayView.alpha = 0
        highlightOverlayView.isUserInteractionEnabled = false

        addSubview(avatarContainerView)
        avatarContainerView.addSubview(avatarLabel)
        addSubview(textStackView)
        addSubview(chevronImageView)
        addSubview(highlightOverlayView)

        textStackView.addArrangedSubview(nameLabel)
        textStackView.addArrangedSubview(subtitleLabel)
    }

    private func setupConstraints() {
        avatarContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 56, height: 56))
        }

        avatarLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 8, height: 13))
        }

        textStackView.snp.makeConstraints { make in
            make.leading.equalTo(avatarContainerView.snp.trailing).offset(14)
            make.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(16)
            make.bottom.lessThanOrEqualToSuperview().offset(-16)
        }

        highlightOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
