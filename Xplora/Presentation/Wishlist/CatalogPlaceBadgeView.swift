// CatalogPlaceBadgeView.swift
// Xplora

import UIKit

/// Small monochrome pill used as a `UITableViewCell.accessoryView` to surface
/// `CatalogPlaceStatus` next to a country row.
final class CatalogPlaceBadgeView: UILabel {

    private let contentInsets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)

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
        font = .systemFont(ofSize: 10, weight: .semibold)
        textColor = .secondaryLabel
        textAlignment = .center
        backgroundColor = .secondarySystemFill
        layer.cornerRadius = 4
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
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
