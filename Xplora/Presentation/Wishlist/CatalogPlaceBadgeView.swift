// CatalogPlaceBadgeView.swift
// Xplora

import UIKit

final class CatalogPlaceBadgeView: UILabel {

    private let contentInsets = UIEdgeInsets(top: 3, left: 7, bottom: 3, right: 7)

    init(status: CatalogPlaceStatus) {
        super.init(frame: .zero)
        configure(status: status)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        return CGSize(
            width: base.width + contentInsets.left + contentInsets.right,
            height: base.height + contentInsets.top + contentInsets.bottom
        )
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    private func configure(status: CatalogPlaceStatus) {
        font = .systemFont(ofSize: 11, weight: .semibold)
        textAlignment = .center
        text = status.badgeLabel
        textColor = status.badgeTextColor
        backgroundColor = status.badgeBackgroundColor
        layer.cornerRadius = 5
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }
}

extension CatalogPlaceStatus {
    var badgeLabel: String {
        switch self {
        case .un:        return "UN"
        case .disputed:  return "DISP"
        case .territory: return "TERR"
        }
    }

    var subtitleLabel: String {
        switch self {
        case .un:        return "UN member"
        case .disputed:  return "Disputed"
        case .territory: return "Territory"
        }
    }

    fileprivate var badgeBackgroundColor: UIColor {
        switch self {
        case .un:        return UIColor.systemBlue.withAlphaComponent(0.14)
        case .disputed:  return UIColor.systemYellow.withAlphaComponent(0.24)
        case .territory: return .secondarySystemFill
        }
    }

    fileprivate var badgeTextColor: UIColor {
        switch self {
        case .un:        return .systemBlue
        case .disputed:  return .label
        case .territory: return .secondaryLabel
        }
    }
}

// MARK: - Accessory factory

extension CatalogPlaceBadgeView {
    static func accessoryView(for status: CatalogPlaceStatus, isSelected: Bool) -> UIView? {
        let badge = CatalogPlaceBadgeView(status: status)
        let checkmark: UIImageView? = isSelected
            ? {
                let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
                let imageView = UIImageView(image: UIImage(systemName: "checkmark", withConfiguration: cfg))
                imageView.tintColor = .systemBlue
                imageView.contentMode = .center
                return imageView
            }()
            : nil

        let parts: [UIView] = [badge, checkmark].compactMap { $0 }

        if parts.count == 1 {
            let view = parts[0]
            view.frame = CGRect(origin: .zero, size: view.intrinsicContentSize)
            return view
        }

        let spacing: CGFloat = 6
        let sizes = parts.map { $0.intrinsicContentSize }
        let totalWidth = sizes.reduce(0) { $0 + $1.width } + CGFloat(parts.count - 1) * spacing
        let maxHeight = sizes.map(\.height).max() ?? 0

        let container = UIView(frame: CGRect(x: 0, y: 0, width: totalWidth, height: maxHeight))
        var x: CGFloat = 0
        for (view, size) in zip(parts, sizes) {
            view.frame = CGRect(
                x: x,
                y: (maxHeight - size.height) / 2,
                width: size.width,
                height: size.height
            )
            container.addSubview(view)
            x += size.width + spacing
        }
        return container
    }
}
