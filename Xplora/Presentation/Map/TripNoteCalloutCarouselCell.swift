//
//  TripNoteCalloutCarouselCell.swift
//  Xplora
//

import SnapKit
import UIKit

/// Wrapper around the existing single-note callout content. Reusing
/// `TripNoteCalloutContentView` means each carousel card has the same
/// visual rules (collage, title, date, place chip, body preview) as the
/// regular single-note callout — only the host changes.
final class TripNoteCalloutCarouselCell: UICollectionViewCell {
    static let reuseIdentifier = "TripNoteCalloutCarouselCell"

    private let contentCard = TripNoteCalloutContentView()
    private var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTap = nil
    }

    func configure(with preview: TripNotePreviewViewModel, onTap: @escaping () -> Void) {
        contentCard.configure(with: preview)
        self.onTap = onTap
    }

    private func setupView() {
        contentView.addSubview(contentCard)
        contentCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        contentView.addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        onTap?()
    }
}
