// WishlistCountryCell.swift
// Xplora

import SnapKit
import UIKit

final class WishlistCountryCell: UICollectionViewListCell {
    var onToggle: (() -> Void)?

    private let checkButton = UIButton(type: .system)
    private let flagLabel = UILabel()
    private let nameLabel = UILabel()
    private let noteLabel = UILabel()
    private let textStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onToggle = nil
        noteLabel.text = nil
        noteLabel.isHidden = true
    }

    func configure(with country: WishlistCountry) {
        flagLabel.text = country.flag
        nameLabel.text = CountryLocalizer.name(for: country.code, fallback: country.name)

        if let city = country.displayCityNote {
            noteLabel.text = city
            noteLabel.isHidden = false
        } else {
            noteLabel.isHidden = true
        }

        applyCompletedStyle(country.isCompleted)
    }

    private func applyCompletedStyle(_ completed: Bool) {
        let symbolName = completed ? "circle.inset.filled" : "circle"
        checkButton.setImage(UIImage(systemName: symbolName), for: .normal)
        checkButton.tintColor = .systemGray

        nameLabel.textColor = completed ? .secondaryLabel : .label
        noteLabel.textColor = .secondaryLabel
        flagLabel.alpha = completed ? 0.5 : 1.0
    }

    private func setupView() {
        automaticallyUpdatesBackgroundConfiguration = false
        if #available(iOS 18.0, *) {
            backgroundConfiguration = UIBackgroundConfiguration.listCell()
        } else {
            backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
        }

        checkButton.tintColor = .systemGray
        checkButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)

        flagLabel.font = .systemFont(ofSize: 26)

        nameLabel.font = .systemFont(ofSize: 24, weight: .regular)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .left
        nameLabel.numberOfLines = 0
        nameLabel.lineBreakMode = .byWordWrapping

        noteLabel.font = .systemFont(ofSize: 15, weight: .regular)
        noteLabel.textColor = .secondaryLabel
        noteLabel.textAlignment = .left
        noteLabel.isHidden = true

        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2
        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(noteLabel)

        contentView.addSubview(checkButton)
        contentView.addSubview(flagLabel)
        contentView.addSubview(textStack)

        textStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.leading.equalTo(flagLabel.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-20)
        }

        checkButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalTo(textStack)
            make.size.equalTo(CGSize(width: 26, height: 26))
        }

        flagLabel.snp.makeConstraints { make in
            make.leading.equalTo(checkButton.snp.trailing).offset(12)
            make.centerY.equalTo(textStack)
        }
    }

    @objc private func toggleTapped() {
        onToggle?()
    }
}
