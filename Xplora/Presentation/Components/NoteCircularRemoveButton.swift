//
//  NoteCircularRemoveButton.swift
//  Xplora
//

import UIKit

/// Native-style attachment remove button used for photos in the trip
/// collage and for the location chip inside a note. The visible glyph is
/// an `xmark.circle.fill` SF Symbol rendered with a two-tone palette
/// (white glyph on a translucent dark circle) so it's always readable on
/// any underlying content. The button's hit area is always 44×44 (Apple
/// HIG), while the visible icon size can be tuned per host via `iconSize`.
final class NoteCircularRemoveButton: UIControl {
    private let iconView = UIImageView()
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    /// Visible side length of the SF Symbol glyph. The hit area itself
    /// is always 44×44; only the rendered icon scales with this value.
    let iconSize: CGFloat

    init(iconSize: CGFloat = 28) {
        self.iconSize = iconSize
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        self.iconSize = 28
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        accessibilityLabel = L10n.Common.removePhoto
        accessibilityTraits = .button
        backgroundColor = .clear

        let config = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .regular)
            .applying(UIImage.SymbolConfiguration(paletteColors: [
                .white,
                UIColor.black.withAlphaComponent(0.55)
            ]))
        iconView.image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        iconView.contentMode = .center
        iconView.isUserInteractionEnabled = false
        addSubview(iconView)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize)
        ])

        // Soft shadow so the icon stays legible on bright photos / colors.
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.22
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.masksToBounds = false

        addTarget(self, action: #selector(handleTouchDown), for: [.touchDown, .touchDragInside])
        addTarget(self, action: #selector(handleTouchUp), for: [
            .touchUpInside, .touchUpOutside, .touchCancel, .touchDragOutside
        ])
        addTarget(self, action: #selector(handleTouchUpInside), for: .touchUpInside)
        feedbackGenerator.prepare()
    }

    /// Move the visible icon to a custom anchor point inside the 44×44 hit
    /// area. Useful when the host wants the cross visually nudged to the
    /// corner (e.g. top-trailing on a photo) instead of centered.
    func placeIcon(insetFromTop top: CGFloat?, insetFromTrailing trailing: CGFloat?) {
        iconView.removeFromSuperview()
        addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        var constraints: [NSLayoutConstraint] = [
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize)
        ]
        if let top {
            constraints.append(iconView.topAnchor.constraint(equalTo: topAnchor, constant: top))
        } else {
            constraints.append(iconView.centerYAnchor.constraint(equalTo: centerYAnchor))
        }
        if let trailing {
            constraints.append(iconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -trailing))
        } else {
            constraints.append(iconView.centerXAnchor.constraint(equalTo: centerXAnchor))
        }
        NSLayoutConstraint.activate(constraints)
    }

    @objc private func handleTouchDown() {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.iconView.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }
    }

    @objc private func handleTouchUp() {
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

    @objc private func handleTouchUpInside() {
        feedbackGenerator.impactOccurred()
        feedbackGenerator.prepare()
    }
}
