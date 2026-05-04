//
//  ProfileRowView.swift
//  Xplora
//

import SnapKit
import UIKit

final class ProfileRowView: UIControl {
    var onTap: (() -> Void)?

    private let horizontalStackView = UIStackView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let spacerView = UIView()
    private let valueLabel = UILabel()
    private let chevronImageView = UIImageView()
    private let dividerView = UIView()
    private let highlightOverlayView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: ProfileActionItem, showsDivider: Bool) {
        titleLabel.text = item.title
        titleLabel.textColor = item.style == .destructive ? .systemRed : .label

        if let value = item.value, !value.isEmpty {
            valueLabel.text = value
            valueLabel.isHidden = false
        } else {
            valueLabel.text = nil
            valueLabel.isHidden = true
        }

        chevronImageView.isHidden = item.accessory != .disclosure
        dividerView.isHidden = !showsDivider

        if let iconName = item.iconSystemName {
            iconImageView.image = UIImage(systemName: iconName)
            iconImageView.isHidden = false
        } else {
            iconImageView.image = nil
            iconImageView.isHidden = true
        }
        iconImageView.tintColor = item.style == .destructive ? .systemRed : .secondaryLabel
    }

    override var isHighlighted: Bool {
        didSet {
            let animations = {
                self.highlightOverlayView.alpha = self.isHighlighted ? 1 : 0
            }
            UIView.animate(withDuration: 0.14, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: animations)
        }
    }

    private func setupUI() {
        backgroundColor = .clear
        accessibilityTraits = [.button]
        clipsToBounds = true

        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center
        horizontalStackView.spacing = 12

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        titleLabel.numberOfLines = 1

        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        valueLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        valueLabel.textColor = .secondaryLabel
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 1
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .tertiaryLabel
        chevronImageView.contentMode = .scaleAspectFit

        dividerView.backgroundColor = UIColor.separator.withAlphaComponent(0.6)

        highlightOverlayView.backgroundColor = UIColor.systemFill.withAlphaComponent(0.4)
        highlightOverlayView.alpha = 0
        highlightOverlayView.isUserInteractionEnabled = false

        addSubview(horizontalStackView)
        addSubview(dividerView)
        addSubview(highlightOverlayView)

        horizontalStackView.addArrangedSubview(iconImageView)
        horizontalStackView.addArrangedSubview(titleLabel)
        horizontalStackView.addArrangedSubview(spacerView)
        horizontalStackView.addArrangedSubview(valueLabel)
        horizontalStackView.addArrangedSubview(chevronImageView)

        horizontalStackView.setCustomSpacing(8, after: valueLabel)
    }

    private func setupConstraints() {
        snp.makeConstraints { make in
            make.height.equalTo(58)
        }

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 23, height: 23))
        }

        chevronImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 8, height: 13))
        }

        horizontalStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.bottom.equalToSuperview()
        }

        dividerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(50)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        highlightOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}
