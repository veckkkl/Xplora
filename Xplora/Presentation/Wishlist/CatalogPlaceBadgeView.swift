// CatalogPlaceBadgeView.swift
// Xplora

import UIKit

/// Small monochrome pill used as a `UITableViewCell.accessoryView` to surface
/// `CatalogPlaceStatus` next to a country row.
final class CatalogPlaceBadgeView: UILabel {

    private let contentInsets = UIEdgeInsets(top: 3, left: 7, bottom: 3, right: 7)

    init(text: String) {
        super.init(frame: .zero)
        configure()
        self.text = text
        invalidateIntrinsicContentSize()
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

    private func configure() {
        font = .systemFont(ofSize: 11, weight: .semibold)
        textColor = .secondaryLabel
        textAlignment = .center
        backgroundColor = .secondarySystemFill
        layer.cornerRadius = 5
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        // Prevent UITableViewCell from squeezing the accessory below intrinsic size.
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }
}

extension CatalogPlaceStatus {
    /// Short label for the cell badge. `nil` means no badge is shown.
    var badgeLabel: String? {
        switch self {
        case .un:        return "UN"
        case .disputed:  return "DISP"
        case .territory: return nil
        }
    }
}
