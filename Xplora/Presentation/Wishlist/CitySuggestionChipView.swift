// CitySuggestionChipView.swift
// Xplora

import UIKit

final class CitySuggestionChipView: UIButton {
    private(set) var city: CatalogCity?

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 14
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(city: CatalogCity, isSelected: Bool) {
        self.city = city

        var config = UIButton.Configuration.plain()
        config.title = city.displayName
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        config.baseForegroundColor = isSelected ? .systemBlue : .label
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var out = attrs
            out.font = .systemFont(ofSize: 14, weight: .medium)
            return out
        }

        var bg = UIBackgroundConfiguration.clear()
        bg.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.08) : .systemBackground
        bg.cornerRadius = 14
        bg.strokeColor = isSelected ? .systemBlue : .separator
        bg.strokeWidth = 1
        config.background = bg

        configuration = config
    }
}
