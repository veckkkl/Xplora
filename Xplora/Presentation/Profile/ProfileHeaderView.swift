//
//  ProfileHeaderView.swift
//  Xplora
//

import SnapKit
import UIKit

final class ProfileHeaderView: UIControl {
    private enum Constants {
        static let cornerRadius: CGFloat = 28
        static let cardInsets = NSDirectionalEdgeInsets(top: 18, leading: 24, bottom: 24, trailing: 24)
        static let contentSpacing: CGFloat = 34

        static let avatarSize: CGFloat = 64
        static let avatarFontSize: CGFloat = 24

        static let topRowSpacing: CGFloat = 14
        static let textStackSpacing: CGFloat = 5
        static let chevronSize = CGSize(width: 8, height: 13)

        static let statsSpacing: CGFloat = 14
        static let statsHeight: CGFloat = 60
        static let shadowOpacity: Float = 0.04
        static let shadowRadius: CGFloat = 16
        static let shadowYOffset: CGFloat = 6
    }

    private let cardBackgroundView = UIView()
    private let contentStackView = UIStackView()

    private let topRowStackView = UIStackView()
    private let avatarContainerView = UIView()
    private let avatarImageView = UIImageView()
    private let avatarLabel = UILabel()

    private let textStackView = UIStackView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let chevronImageView = UIImageView()
    private let statsStackView = UIStackView()
    private let highlightOverlayView = UIView()

    private var statViews: [ProfileStatView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(
            roundedRect: cardBackgroundView.frame,
            cornerRadius: Constants.cornerRadius
        ).cgPath
    }

    func configure(with item: ProfileCardItem) {
        applyAvatar(fileName: item.avatarFileName, initials: item.initials)
        avatarLabel.text = item.initials
        nameLabel.text = item.name
        subtitleLabel.text = item.status.title
        subtitleLabel.isHidden = !item.isStatusVisible

        applyStats(item.stats)
        accessibilityLabel = item.isStatusVisible ? "\(item.name), \(item.status.title)" : item.name
    }

    override var isHighlighted: Bool {
        didSet {
            let animations = {
                self.highlightOverlayView.alpha = self.isHighlighted ? 1 : 0
            }
            UIView.animate(
                withDuration: 0.16,
                delay: 0,
                options: [.beginFromCurrentState, .allowUserInteraction],
                animations: animations
            )
        }
    }

    private func setupUI() {
        backgroundColor = .clear

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Constants.shadowOpacity
        layer.shadowRadius = Constants.shadowRadius
        layer.shadowOffset = CGSize(width: 0, height: Constants.shadowYOffset)

        accessibilityTraits = [.button]

        cardBackgroundView.backgroundColor = .secondarySystemGroupedBackground
        cardBackgroundView.layer.cornerRadius = Constants.cornerRadius
        cardBackgroundView.layer.cornerCurve = .continuous
        cardBackgroundView.clipsToBounds = true
        // Keep touch handling on UIControl itself, otherwise nested container may swallow taps.
        cardBackgroundView.isUserInteractionEnabled = false
        cardBackgroundView.directionalLayoutMargins = Constants.cardInsets

        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = Constants.contentSpacing

        topRowStackView.axis = .horizontal
        topRowStackView.alignment = .center
        topRowStackView.spacing = Constants.topRowSpacing

        avatarContainerView.backgroundColor = .secondarySystemFill
        avatarContainerView.layer.cornerRadius = Constants.avatarSize / 2
        avatarContainerView.layer.cornerCurve = .continuous
        avatarContainerView.clipsToBounds = true

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.isHidden = true

        let avatarFont = UIFont.systemFont(ofSize: Constants.avatarFontSize, weight: .semibold)
        avatarLabel.font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: avatarFont)
        avatarLabel.adjustsFontForContentSizeCategory = true
        avatarLabel.textColor = .label
        avatarLabel.textAlignment = .center

        textStackView.axis = .vertical
        textStackView.alignment = .fill
        textStackView.spacing = Constants.textStackSpacing

        let nameFont = UIFont.systemFont(ofSize: 28, weight: .semibold)
        nameLabel.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: nameFont)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        nameLabel.setContentHuggingPriority(.required, for: .vertical)

        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        subtitleLabel.setContentHuggingPriority(.required, for: .vertical)

        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .tertiaryLabel
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.preferredSymbolConfiguration = .init(pointSize: 14, weight: .semibold)

        statsStackView.axis = .horizontal
        statsStackView.alignment = .center
        statsStackView.distribution = .fillEqually
        statsStackView.spacing = Constants.statsSpacing

        highlightOverlayView.backgroundColor = UIColor.systemFill.withAlphaComponent(0.24)
        highlightOverlayView.alpha = 0
        highlightOverlayView.isUserInteractionEnabled = false
    }

    private func setupHierarchy() {
        addSubview(cardBackgroundView)
        cardBackgroundView.addSubview(contentStackView)
        cardBackgroundView.addSubview(highlightOverlayView)

        contentStackView.addArrangedSubview(topRowStackView)
        contentStackView.addArrangedSubview(statsStackView)

        topRowStackView.addArrangedSubview(avatarContainerView)
        topRowStackView.addArrangedSubview(textStackView)
        topRowStackView.addArrangedSubview(chevronImageView)

        avatarContainerView.addSubview(avatarImageView)
        avatarContainerView.addSubview(avatarLabel)

        textStackView.addArrangedSubview(nameLabel)
        textStackView.addArrangedSubview(subtitleLabel)
    }

    private func setupConstraints() {
        cardBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalTo(cardBackgroundView.layoutMarginsGuide)
        }

        avatarContainerView.snp.makeConstraints { make in
            make.size.equalTo(Constants.avatarSize)
        }

        avatarLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        avatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        chevronImageView.snp.makeConstraints { make in
            make.size.equalTo(Constants.chevronSize)
        }

        textStackView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        statsStackView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(Constants.statsHeight)
        }

        highlightOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func applyStats(_ stats: [ProfileCardItem.Stat]) {
        statViews.forEach { view in
            statsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        statViews.removeAll()

        for stat in stats {
            let statView = ProfileStatView()
            statView.configure(with: stat)
            statViews.append(statView)
            statsStackView.addArrangedSubview(statView)
        }
    }

    private func applyAvatar(fileName: String?, initials: String) {
        let image = ProfileUserSettings.loadAvatarImage(fileName: fileName)
        avatarImageView.image = image
        avatarImageView.isHidden = image == nil
        avatarLabel.isHidden = image != nil
        avatarLabel.text = initials
    }
}

private final class ProfileStatView: UIView {
    private enum Constants {
        static let spacing: CGFloat = 4
        static let iconSize: CGFloat = 14
    }

    private let stackView = UIStackView()
    private let iconImageView = UIImageView()
    private let valueLabel = UILabel()
    private let captionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: ProfileCardItem.Stat) {
        iconImageView.image = UIImage(systemName: item.iconSystemName)
        iconImageView.tintColor = color(for: item.tint)
        valueLabel.text = item.value
        captionLabel.text = item.label
    }

    private func setupUI() {
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = Constants.spacing

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.preferredSymbolConfiguration = .init(pointSize: Constants.iconSize, weight: .semibold)

        valueLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 1
        valueLabel.textAlignment = .center
        valueLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        valueLabel.setContentHuggingPriority(.required, for: .vertical)

        captionLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        captionLabel.adjustsFontForContentSizeCategory = true
        captionLabel.textColor = .secondaryLabel
        captionLabel.numberOfLines = 1
        captionLabel.textAlignment = .center
        captionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        captionLabel.setContentHuggingPriority(.required, for: .vertical)
    }

    private func setupHierarchy() {
        addSubview(stackView)
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(valueLabel)
        stackView.addArrangedSubview(captionLabel)
    }

    private func setupConstraints() {
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(Constants.iconSize)
        }
    }

    private func color(for tint: ProfileIconTint) -> UIColor {
        switch tint {
        case .blue:
            return .systemBlue
        case .green:
            return .systemGreen
        case .yellow:
            return .systemYellow
        case .purple:
            return .systemPurple
        case .gray:
            return .secondaryLabel
        case .red:
            return .systemRed
        }
    }
}
